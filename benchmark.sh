#!/bin/bash
start=`date +%s`

nemsinit=`/usr/local/bin/nems-info init`
if [[ $nemsinit == 0 ]]; then
  echo "NEMS hasn't been initialized. Benchmark rejected."
  exit
fi

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

if [[ ! -f /usr/bin/sysbench ]]; then
  apt install sysbench
fi

echo "NEMS System Benchmark" > /tmp/nems-benchmark.log
date >> /tmp/nems-benchmark.log
printf "NEMS Version: " >> /tmp/nems-benchmark.log
ver=$(/usr/local/bin/nems-info nemsver)
echo $ver >> /tmp/nems-benchmark.log

printf "\nHardware Revision: " >> /tmp/nems-benchmark.log
/usr/local/bin/nems-info hwver >> /tmp/nems-benchmark.log
printf "NEMS ID: " >> /tmp/nems-benchmark.log
/usr/local/bin/nems-info hwid >> /tmp/nems-benchmark.log

printf "System Uptime: " >> /tmp/nems-benchmark.log
/usr/bin/uptime >> /tmp/nems-benchmark.log

printf "LAN IP: " >> /tmp/nems-benchmark.log
/usr/local/bin/nems-info ip >> /tmp/nems-benchmark.log

echo "---------------------------------" >> /tmp/nems-benchmark.log

if [[ ! -d /var/log/nems/benchmarks ]]; then
  mkdir -p /var/log/nems/benchmarks
fi

# Run the tests
cores=$(nproc --all)

echo "Number of threads: $cores" >> /tmp/nems-benchmark.log

cd /tmp

printf "Performing CPU Benchmark: " >> /tmp/nems-benchmark.log
cpu=`/usr/bin/sysbench --test=cpu --cpu-max-prime=20000 --num-threads=$cores run | /usr/local/share/nems/nems-scripts/benchmark-parse.sh cpu`
echo $cpu > /var/log/nems/benchmarks/cpu
echo "CPU Score $cpu" >> /tmp/nems-benchmark.log

printf "Performing RAM Benchmark: " >> /tmp/nems-benchmark.log
ram=`/usr/bin/sysbench --test=memory --num-threads=$cores --memory-total-size=10G run | /usr/local/share/nems/nems-scripts/benchmark-parse.sh ram`
echo $ram > /var/log/nems/benchmarks/ram
echo "RAM Score $ram" >> /tmp/nems-benchmark.log

printf "Performing Mutex Benchmark: " >> /tmp/nems-benchmark.log
mutex=`/usr/bin/sysbench --test=mutex --num-threads=64 run | /usr/local/share/nems/nems-scripts/benchmark-parse.sh mutex`
echo $mutex > /var/log/nems/benchmarks/mutex
echo "Mutex Score $mutex" >> /tmp/nems-benchmark.log

printf "Performing I/O Benchmark: " >> /tmp/nems-benchmark.log
io=`/usr/bin/sysbench --test=fileio --file-test-mode=seqwr run | /usr/local/share/nems/nems-scripts/benchmark-parse.sh io`
echo $io > /var/log/nems/benchmarks/io
echo "I/O Score $io" >> /tmp/nems-benchmark.log

# Clear the test files
rm -f /tmp/test_file.*

echo "---------------------------------" >> /tmp/nems-benchmark.log

echo "Filesystem:" >> /tmp/nems-benchmark.log
/bin/df -h >> /tmp/nems-benchmark.log

echo "---------------------------------" >> /tmp/nems-benchmark.log

echo "Memory:" >> /tmp/nems-benchmark.log
/usr/bin/free -h >> /tmp/nems-benchmark.log

echo "---------------------------------" >> /tmp/nems-benchmark.log

echo "Internet Speed:" >> /tmp/nems-benchmark.log
/usr/local/share/nems/nems-scripts/speedtest --simple >> /tmp/nems-benchmark.log

echo "---------------------------------" >> /tmp/nems-benchmark.log

end=`date +%s`
runtime=$((end-start))
echo "Benchmark of this benchmark: "$runtime" seconds" >> /tmp/nems-benchmark.log

echo $runtime > /var/log/nems/benchmarks/runtime

cat /tmp/nems-benchmark.log
rm  /tmp/nems-benchmark.log

# sometime in future, get the downtime ID from livestatus and output it in place of the '1'
#/usr/bin/printf "[%lu] DEL_SVC_DOWNTIME;1\n" $end > /usr/local/nagios/var/rw/nagios.cmd

