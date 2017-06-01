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
  /bin/cat /var/www/html/inc/ver.txt
  
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

# Output usage info as no valid command line argument was provided
else
  echo "Usage: ./$me command"
  echo "Available commands: ip nemsver nemsveravail users"
fi
