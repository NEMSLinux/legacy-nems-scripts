#!/bin/bash
# NEMS Server Info Script (primarily used for MOTD)

export COMMAND=$1
me=`basename "$0"`

# Output local IP address
if [[ $COMMAND == "ip" ]]; then
  if /sbin/ip -f inet addr show eth0 | grep -Po 'inet \K[\d.]+'; then
    do=nothingreally
  else
    /sbin/ip -f inet addr show wlan0 | grep -Po 'inet \K[\d.]+'
  fi

# Output current running NEMS version
elif [[ $COMMAND == "nemsver" ]]; then
  cat /home/pi/nems.conf | grep version |  printf '%s' $(cut -n -d '=' -f 2)

# Output the current available NEMS version (update.sh generates this every day at midnight and at reboot)
elif [[ $COMMAND == "nemsveravail" ]]; then
  /bin/cat /var/www/html/inc/ver-available.txt

# Output the number of users connected to server
elif [[ $COMMAND == "users" ]]; then
  export USERCOUNT=`/usr/bin/users | /usr/bin/wc -w`
  if [ $USERCOUNT -eq 1 -o $USERCOUNT -eq -1 ]
		then
			echo $USERCOUNT user
		else
			echo $USERCOUNT users
	fi

# Output disk usage in percent
elif [[ $COMMAND == "diskusage" ]]; then
  df -hl | awk '/^\/dev\/root/ { sum+=$5 } END { print sum }'

# Output memory usage breakdown
elif [[ $COMMAND == "memusage" ]]; then
  for file in /proc/*/status ; do awk '/VmSwap|Name/{printf $2 " " $3}END{ print ""}' $file; done | sort -k 2 -n -r | less

# Output country code
elif [[ $COMMAND == "country" ]]; then
  /home/pi/nems-scripts/country.sh

# Output revision of Raspberry Pi board
elif [[ $COMMAND == "hwver" ]]; then
# if is pi
 cat /proc/cpuinfo | grep 'Revision' | awk '{print $3}' | sed 's/^1000//'

# Output an MD5 of the Pi board serial number - we'll call this the NEMS Pi ID
elif [[ $COMMAND == "hwid" ]]; then
# if is pi
 cat /proc/cpuinfo | grep Serial |  printf '%s' $(cut -n -d ' ' -f 2) | md5sum | cut -d"-" -f1 -

elif [[ $COMMAND == "platform" ]]; then
# show if is pi or if is xu4, etc.
  cat /home/pi/nems.conf | grep platform |  printf '%s' $(cut -n -d '=' -f 2)

elif [[ $COMMAND == "drives" ]]; then
# Generate a list of drives
# Used by NEMS to configure external storage
  lsblk -J --output NAME,MOUNTPOINT,FSTYPE,UUID,SIZE,TYPE

elif [[ $COMMAND == "loadaverage" ]]; then
# See 1 week load average
if [ -f /var/log/nems/load-average.log ]; then
  cat /var/log/nems/load-average.log
  echo ""
else
  echo 0
fi

elif [[ $COMMAND == "loadaverageround" ]]; then
# See 1 week load average
if [ -f /var/log/nems/load-average.log ]; then
  la=$(cat /var/log/nems/load-average.log)
  printf '%.*f\n' 2 $la
else
  echo 0
fi

# Output usage info as no valid command line argument was provided
else
  echo "Usage: ./$me command"
  echo "For help, visit wiki.nemslinux.com/commands/nems-info"
fi
