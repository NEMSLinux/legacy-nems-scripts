#!/bin/bash
start=`date +%s`
plannedend=$(($start + 18000))

nemsinit=`/usr/local/bin/nems-info init`
if [[ $nemsinit == 0 ]]; then
  echo "NEMS hasn't been initialized. Benchmark rejected."
  exit
fi

# Schedule downtime on CPU Load notifications for 5 hours during benchmarks
/usr/bin/printf "[%lu] SCHEDULE_SVC_DOWNTIME;NEMS;Current Load;$start;$plannedend;0;0;18000;NEMS Linux;Weekly Benchmarks Running\n" $start > /usr/local/nagios/var/rw/nagios.cmd

echo "NEMS System Benchmark... Please Wait (may take a while)."

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

if (( $(awk 'BEGIN {print ("'$ver'" >= "'1.4.1'")}') )); then
  # Phoronix Test Suite in NEMS 1.4.1+
#  printf "Running Phoronix 'iozone' test..." >> /tmp/nems-benchmark.log
#    /usr/bin/phoronix-test-suite batch-benchmark iozone
#  echo " Done." >> /tmp/nems-benchmark.log
#  printf "Running Phoronix 'smallpt' test..." >> /tmp/nems-benchmark.log
#    /usr/bin/phoronix-test-suite batch-benchmark smallpt
#  echo " Done." >> /tmp/nems-benchmark.log
#  printf "Running Phoronix 'himeno' test..." >> /tmp/nems-benchmark.log
#    /usr/bin/phoronix-test-suite batch-benchmark himeno
#  echo " Done." >> /tmp/nems-benchmark.log
#  printf "Running Phoronix 'ramspeed' test..." >> /tmp/nems-benchmark.log
#    /usr/bin/phoronix-test-suite batch-benchmark ramspeed
#  echo " Done." >> /tmp/nems-benchmark.log
#  printf "Running Phoronix 'netperf' test..." >> /tmp/nems-benchmark.log
#    /usr/bin/phoronix-test-suite batch-benchmark netperf
#  echo " Done." >> /tmp/nems-benchmark.log

#  printf "Running Phoronix 'apache' test..." >> /tmp/nems-benchmark.log
#    /usr/bin/phoronix-test-suite batch-benchmark apache
#  echo " Done." >> /tmp/nems-benchmark.log
#  printf "Running Phoronix 'cachebench' test..." >> /tmp/nems-benchmark.log
#    /usr/bin/phoronix-test-suite batch-benchmark cachebench
#  echo " Done." >> /tmp/nems-benchmark.log
#  printf "Running Phoronix 'scimark2' test..." >> /tmp/nems-benchmark.log
#    /usr/bin/phoronix-test-suite batch-benchmark scimark2
#  echo " Done." >> /tmp/nems-benchmark.log
#  printf "Running Phoronix 'graphics-magick' test..." >> /tmp/nems-benchmark.log
#    /usr/bin/phoronix-test-suite batch-benchmark graphics-magick
#  echo " Done." >> /tmp/nems-benchmark.log
#  printf "Running Phoronix 'ebizzy' test..." >> /tmp/nems-benchmark.log
#    /usr/bin/phoronix-test-suite batch-benchmark ebizzy
#  echo " Done." >> /tmp/nems-benchmark.log
#  printf "Running Phoronix 'c-ray' test..." >> /tmp/nems-benchmark.log
#    /usr/bin/phoronix-test-suite batch-benchmark c-ray
#  echo " Done." >> /tmp/nems-benchmark.log
#  printf "Running Phoronix 'stockfish' test..." >> /tmp/nems-benchmark.log
#    /usr/bin/phoronix-test-suite batch-benchmark stockfish
#  echo " Done." >> /tmp/nems-benchmark.log
#  printf "Running Phoronix 'aobench' test..." >> /tmp/nems-benchmark.log
#    /usr/bin/phoronix-test-suite batch-benchmark aobench
#  echo " Done." >> /tmp/nems-benchmark.log
#  printf "Running Phoronix 'timed-audio-encode' test..." >> /tmp/nems-benchmark.log
#    /usr/bin/phoronix-test-suite batch-benchmark timed-audio-encode
#  echo " Done." >> /tmp/nems-benchmark.log
#  printf "Running Phoronix 'encode-mp3' test..." >> /tmp/nems-benchmark.log
#    /usr/bin/phoronix-test-suite batch-benchmark encode-mp3
#  echo " Done." >> /tmp/nems-benchmark.log
#  printf "Running Phoronix 'perl-benchmark' test..." >> /tmp/nems-benchmark.log
#    /usr/bin/phoronix-test-suite batch-benchmark perl-benchmark
#  echo " Done." >> /tmp/nems-benchmark.log
#  printf "Running Phoronix 'openssl' test..." >> /tmp/nems-benchmark.log
#    /usr/bin/phoronix-test-suite batch-benchmark openssl
#  echo " Done." >> /tmp/nems-benchmark.log
#  printf "Running Phoronix 'redis' test..." >> /tmp/nems-benchmark.log
#    /usr/bin/phoronix-test-suite batch-benchmark redis
#  echo " Done." >> /tmp/nems-benchmark.log
#  printf "Running Phoronix 'pybench' test..." >> /tmp/nems-benchmark.log
#    /usr/bin/phoronix-test-suite batch-benchmark pybench
#  echo " Done." >> /tmp/nems-benchmark.log
#  printf "Running Phoronix 'phpbench' test..." >> /tmp/nems-benchmark.log
#    /usr/bin/phoronix-test-suite batch-benchmark phpbench
#  echo " Done." >> /tmp/nems-benchmark.log
#  printf "Running Phoronix 'git' test..." >> /tmp/nems-benchmark.log
#    /usr/bin/phoronix-test-suite batch-benchmark git
#  echo " Done." >> /tmp/nems-benchmark.log

  printf "Running Phoronix benchmarks..." >> /tmp/nems-benchmark.log
    /usr/bin/phoronix-test-suite batch-benchmark smallpt himeno apache cachebench scimark2 graphics-magick ebizzy c-ray stockfish aobench timed-audio-encode encode-mp3perl-benchmark openssl redis pybench phpbench git
  echo " Done." >> /tmp/nems-benchmark.log

else
  printf "SD Card READ:" >> /tmp/nems-benchmark.log
  /sbin/hdparm -t /dev/mmcblk0p2 >> /tmp/nems-benchmark.log
  echo "SD Card WRITE:" >> /tmp/nems-benchmark.log
  /bin/dd count=100 bs=1M if=/dev/zero of=/root/nems-benchmark.img 2>> /tmp/nems-benchmark.log
  rm /root/nems-benchmark.img

  echo "---------------------------------" >> /tmp/nems-benchmark.log

  echo "Memory WRITE:" >> /tmp/nems-benchmark.log
  /bin/dd count=100 bs=1M if=/dev/zero of=/tmp/nems-benchmark.img 2>> /tmp/nems-benchmark.log
  rm /tmp/nems-benchmark.img
fi

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

# sometime in future, get the downtime ID from livestatus and output it in place of the '1'
#/usr/bin/printf "[%lu] DEL_SVC_DOWNTIME;1\n" $end > /usr/local/nagios/var/rw/nagios.cmd

cat /tmp/nems-benchmark.log
rm  /tmp/nems-benchmark.log
