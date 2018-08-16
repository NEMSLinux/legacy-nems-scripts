#!/bin/bash
start=`date +%s`

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
  printf "Running Phoronix 'himeno' test..." >> /tmp/nems-benchmark.log
    /usr/bin/phoronix-test-suite batch-benchmark himeno
  echo " Done." >> /tmp/nems-benchmark.log
  printf "Running Phoronix 'ramspeed' test..." >> /tmp/nems-benchmark.log
    /usr/bin/phoronix-test-suite batch-benchmark ramspeed
  echo " Done." >> /tmp/nems-benchmark.log
  printf "Running Phoronix 'iozone' test..." >> /tmp/nems-benchmark.log
    /usr/bin/phoronix-test-suite batch-benchmark iozone
  echo " Done." >> /tmp/nems-benchmark.log
  printf "Running Phoronix 'smallpt' test..." >> /tmp/nems-benchmark.log
    /usr/bin/phoronix-test-suite batch-benchmark smallpt
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

cat /tmp/nems-benchmark.log
rm  /tmp/nems-benchmark.log
