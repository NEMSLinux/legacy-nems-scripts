#!/bin/bash
cores=$(nproc --all)
modprobe zram num_devices=$cores > /dev/null 2>&1

result=$(cat /proc/modules | grep zram)

if [[ $result = *"zram"* ]]; then

  swapoff -a

  totalmem=`free | grep -e "^Mem:" | awk '{print $2}'`
  mem=$(( ($totalmem / $cores)* 1024 ))

  core=0
  while [ $core -lt $cores ]; do
    echo $mem > /sys/block/zram$core/disksize
    mkswap /dev/zram$core
    swapon -p 5 /dev/zram$core
    let core=core+1
  done
else
  echo ZRAM Not Found...
fi
