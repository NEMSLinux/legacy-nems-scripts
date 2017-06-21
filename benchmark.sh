#!/bin/bash

echo "NEMS System Benchmark... Please Wait (may take a while)."

echo "NEMS System Benchmark" > /tmp/nems-benchmark.log
date >> /tmp/nems-benchmark.log
printf "NEMS Version: " >> /tmp/nems-benchmark.log
/home/pi/nems-scripts/info.sh nemsver >> /tmp/nems-benchmark.log
printf "LAN IP: " >> /tmp/nems-benchmark.log
/home/pi/nems-scripts/info.sh ip >> /tmp/nems-benchmark.log

echo "---------------------------------" >> /tmp/nems-benchmark.log

echo "SD Card READ:" >> /tmp/nems-benchmark.log
/sbin/hdparm -t /dev/mmcblk0p2 >> /tmp/nems-benchmark.log
echo "SD Card WRITE:" >> /tmp/nems-benchmark.log
/bin/dd count=100 bs=1M if=/dev/zero of=/root/nems-benchmark.img 2>> /tmp/nems-benchmark.log
rm /root/nems-benchmark.img

echo "---------------------------------" >> /tmp/nems-benchmark.log

#echo "Memory READ:" >> /tmp/nems-benchmark.log
echo "Memory WRITE:" >> /tmp/nems-benchmark.log
/bin/dd count=100 bs=1M if=/dev/zero of=/tmp/nems-benchmark.img 2>> /tmp/nems-benchmark.log
rm /tmp/nems-benchmark.img

echo "---------------------------------" >> /tmp/nems-benchmark.log

echo "Filesystem:" >> /tmp/nems-benchmark.log
/bin/df -h >> /tmp/nems-benchmark.log

echo "---------------------------------" >> /tmp/nems-benchmark.log

echo "Memory:" >> /tmp/nems-benchmark.log
/usr/bin/free -h >> /tmp/nems-benchmark.log

echo "---------------------------------" >> /tmp/nems-benchmark.log

echo "Internet Speed:" >> /tmp/nems-benchmark.log
/home/pi/nems-scripts/speedtest --simple >> /tmp/nems-benchmark.log

cat /tmp/nems-benchmark.log
#rm  /tmp/nems-benchmark.log
