#!/bin/bash
start=`date +%s`

if [[ ! -e /usr/local/bin/nems-info ]]; then
  echo "Requires NEMS Linux."
  exit 1
fi

# Install sysbench if it is not found

  # Set the version of sysbench so all match
  # Needs to match a release found at https://github.com/akopytov/sysbench/releases
    ver='1.0.17'

  # Compile if not exist
  if [[ ! -f /usr/local/bin/sysbench-$ver/bin/sysbench ]]; then

      # Warn and give chance to abort installation
        echo "sysbench-$ver not found. I will install it (along with dependencies) now."
        echo 'CTRL-C to abort'
        sleep 5

      # Update apt repositories
        apt update

      # Install dependencies to compile from source
        yes | apt install make
        yes | apt install automake
        yes | apt install libtool
        yes | apt install libz-dev
        yes | apt install pkg-config
        yes | apt install libaio-dev
        # MySQL Compatibility
        yes | apt install libmariadb-dev-compat
        yes | apt install libmariadb-dev
        yes | apt install libssl-dev

      # Download and compile from source
        tmpdir=`mktemp -d -p /tmp/`
        echo "Working in $tmpdir"
        cd $tmpdir
        wget https://github.com/akopytov/sysbench/archive/$ver.zip
        unzip $ver.zip
        cd sysbench-$ver
        ./autogen.sh
        ./configure --prefix=/usr/local/bin/sysbench-$ver/
        make -j && make install

      # Clean up
        cd /tmp && rm -rf $tmpdir

      if [[ ! -f /usr/local/bin/sysbench-$ver/bin/sysbench ]]; then
        # I tried and failed
        # Now, report the issue to screen and exit
        echo "sysbench could not be installed."
        exit 1
      fi

  fi

# Check if NEMS has been initialized, don't benchmark if not
  nemsinit=`/usr/local/bin/nems-info init`
  if [[ $nemsinit == 0 ]]; then
    echo "NEMS hasn't been initialized."
    exit 1
  fi

# Good to proceed, begin benchmark

sysbench=/usr/local/bin/sysbench-$ver/bin/sysbench

# Set a runtime
if [[ -f /var/log/nems/benchmarks/runtime ]]; then
  lastruntime=`cat /var/log/nems/benchmarks/runtime`
  if [ "$lastruntime" -gt "18000" ]; then
    # Don't run weekly benchmark on boards that take longer than 10 minutes to do so
    echo "Benchmarks take too long on this board. Aborting."
    echo "Stats for this board will be based on first run."
    exit 1
  fi
  thisruntime=$(($lastruntime+120)) # +2 minutes from the last runtime
else
  thisruntime=18000 # 10 minutes
fi
plannedend=$(($start + $thisruntime))

# Schedule downtime on CPU Load notifications for 5 hours during benchmarks
/usr/bin/printf "[%lu] SCHEDULE_SVC_DOWNTIME;NEMS;Current Load;$start;$plannedend;0;0;$thisruntime;NEMS Linux;Weekly Benchmarks Running\n" $start > /usr/local/nagios/var/rw/nagios.cmd

echo "NEMS System Benchmark... Please Wait (may take a while)."

tmpdir=`mktemp -d -p /tmp/`

echo "NEMS System Benchmark" > $tmpdir/nems-benchmark.log
date >> $tmpdir/nems-benchmark.log
printf "NEMS Version: " >> $tmpdir/nems-benchmark.log
ver=$(/usr/local/bin/nems-info nemsver)
echo $ver >> $tmpdir/nems-benchmark.log

printf "\nHardware Revision: " >> $tmpdir/nems-benchmark.log
/usr/local/bin/nems-info hwver >> $tmpdir/nems-benchmark.log
printf "NEMS ID: " >> $tmpdir/nems-benchmark.log
/usr/local/bin/nems-info hwid >> $tmpdir/nems-benchmark.log

printf "System Uptime: " >> $tmpdir/nems-benchmark.log
/usr/bin/uptime >> $tmpdir/nems-benchmark.log

printf "LAN IP: " >> $tmpdir/nems-benchmark.log
/usr/local/bin/nems-info ip >> $tmpdir/nems-benchmark.log

echo "---------------------------------" >> $tmpdir/nems-benchmark.log

if [[ ! -d /var/log/nems/benchmarks ]]; then
  mkdir -p /var/log/nems/benchmarks
fi

# Run the tests
cores=$(nproc --all)

echo "Number of threads: $cores" >> $tmpdir/nems-benchmark.log

cd $tmpdir

# Determine if we're on an old version of SysBench requiring --test=
help=`$sysbench --help`
if [[ $help == *"--test="* ]]; then
  # Old version
  command="$sysbench --test="
else
  # Modern version
  command="$sysbench "
fi
if [[ $help == *"--num-threads="* ]]; then
  # Old version
  threadsswitch="--num-threads"
else
  # Modern version
  threadsswitch="--threads"
fi

printf "Performing CPU Benchmark: " >> $tmpdir/nems-benchmark.log
cpu=`${command}cpu --cpu-max-prime=20000 $threadsswitch=$cores run | /usr/local/share/nems/nems-scripts/benchmark-parse.sh cpu`
echo $cpu > /var/log/nems/benchmarks/cpu
echo "CPU Score $cpu" >> $tmpdir/nems-benchmark.log

printf "Performing RAM Benchmark: " >> $tmpdir/nems-benchmark.log
ram=`${command}memory $threadsswitch=$cores --memory-total-size=10G run | /usr/local/share/nems/nems-scripts/benchmark-parse.sh ram`
echo $ram > /var/log/nems/benchmarks/ram
echo "RAM Score $ram" >> $tmpdir/nems-benchmark.log

printf "Performing Mutex Benchmark: " >> $tmpdir/nems-benchmark.log
mutex=`${command}mutex $threadsswitch=64 run | /usr/local/share/nems/nems-scripts/benchmark-parse.sh mutex`
echo $mutex > /var/log/nems/benchmarks/mutex
echo "Mutex Score $mutex" >> $tmpdir/nems-benchmark.log

printf "Performing I/O Benchmark: " >> $tmpdir/nems-benchmark.log
io=`${command}fileio --file-test-mode=seqwr run | /usr/local/share/nems/nems-scripts/benchmark-parse.sh io`
echo $io > /var/log/nems/benchmarks/io
echo "I/O Score $io" >> $tmpdir/nems-benchmark.log

# Clear the test files
rm -f $tmpdir/test_file.*

echo "---------------------------------" >> $tmpdir/nems-benchmark.log

printf "Performing 7z Benchmark: " >> $tmpdir/nems-benchmark.log
prog=$(which 7za || which 7zr)
if [[ -z $prog ]]; then
  apt update && apt -y install p7zip
  prog=$(which 7za || which 7zr)
fi

if [[ ! -z $prog ]]; then
  # Get the total result from first CPU core
  taskset -c 0 "$prog" b > $tmpdir/7z.log
  result1=$(awk -F" " '/^Tot:/ {print $4}' <$tmpdir/7z.log | tr '\n' ', ' | sed 's/,$//')
  # Get the total result from last CPU core (might be big.LITTLE, or could be same core)
  taskset -c $(( $cores - 1 )) "$prog" b > $tmpdir/7z.log
  result2=$(awk -F" " '/^Tot:/ {print $4}' <$tmpdir/7z.log | tr '\n' ', ' | sed 's/,$//')
  average7z=$(( ($result1 + $result2) / 2 ))
  echo "Done." >> $tmpdir/nems-benchmark.log
  echo "7z Benchmark Result:     $average7z" >> $tmpdir/nems-benchmark.log
  echo $average7z > /var/log/nems/benchmarks/7z
else
  echo "Can't find or install p7zip. 7z benchmark skipped." >> $tmpdir/nems-benchmark.log
fi
echo "---------------------------------" >> $tmpdir/nems-benchmark.log

echo "Filesystem:" >> $tmpdir/nems-benchmark.log
/bin/df -h >> $tmpdir/nems-benchmark.log

echo "---------------------------------" >> $tmpdir/nems-benchmark.log

echo "Memory:" >> $tmpdir/nems-benchmark.log
/usr/bin/free -h >> $tmpdir/nems-benchmark.log

echo "---------------------------------" >> $tmpdir/nems-benchmark.log

echo "Internet Speed:" >> $tmpdir/nems-benchmark.log
/usr/local/share/nems/nems-scripts/speedtest --simple >> $tmpdir/nems-benchmark.log

echo "---------------------------------" >> $tmpdir/nems-benchmark.log

end=`date +%s`
runtime=$((end-start))
echo "Benchmark of this benchmark: "$runtime" seconds" >> $tmpdir/nems-benchmark.log

echo $runtime > /var/log/nems/benchmarks/runtime

cat $tmpdir/nems-benchmark.log
cd /tmp
rm -rf $tmpdir

# sometime in future, get the downtime ID from livestatus and output it in place of the '1'
#/usr/bin/printf "[%lu] DEL_SVC_DOWNTIME;1\n" $end > /usr/local/nagios/var/rw/nagios.cmd

