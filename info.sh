#!/bin/bash
# NEMS Server Info Script

export COMMAND=$1
me=`basename "$0"`
USAGE="Usage: ./$me COMMAND"
if [ $COMMAND = "ip" ]; then
  /sbin/ip -f inet addr show eth0 | grep -Po 'inet \K[\d.]+'
elif [ $COMMAND = "nemsver" ]; then
  /bin/cat /var/www/html/inc/ver.txt
elif [ $COMMAND = "nemsveravail" ]; then
  /bin/cat /var/www/html/inc/ver-available.txt
elif [ $COMMAND = "users" ]; then
  export USERCOUNT=`/usr/bin/users | /usr/bin/wc -w`
  if [ $USERCOUNT -eq 1 -o $USERCOUNT -eq -1 ]
		then
			echo $USERCOUNT user
		else
			echo $USERCOUNT users
	fi
else
  echo $USAGE
fi
