#!/bin/bash

if [[ $EUID -ne 0 ]]; then
  echo "ERROR: This script must be run as root" 2>&1
  exit 1
else
  # Ping Google to see if Internet is up. Don't begin until we have Internet.
  count=1
  while ! ping -c 1 -W 1 google.com; do
    if [ $count -eq 60 ]
      then
         echo "Google not responding. Resuming, but if Internet is down, updates will fail."
         break;
    fi     
    ((count++))
    sleep 1
  done

  # Tell the web cache to serve up the file from midnight
  timestamp=$( /bin/date --date="today 00:00:01 UTC -5 hours" +%s )
  /usr/bin/wget -q -O /var/www/html/inc/ver-available.txt http://cdn.zecheriah.com/baldnerd/nems/ver-current.txt#$timestamp
  
  # Update nems-migrator
  printf "Updating nems-migrator... "
  cd /root/nems/nems-migrator && git pull
  echo "Done."
  
  # Update nems-www
  printf "Updating nems-www... "
  cd /var/www/html && git pull
  echo "Done."
  
  # Update self
  printf "Updating nems-scripts... "
  cd /home/pi/nems-scripts && git pull
  echo "Done."
  
  # Perform any fixes that have been released since NEMS was built
  printf "Running updates and fixes... "
  /home/pi/nems-scripts/fixes.sh
  echo "Done."
  
  # Copy the version data to the public inc folder (in case it accidentally gets deleted)
  printf "Checking for new NEMS version... "
  test -d "/var/www/html/inc" || mkdir -p "/var/www/html/inc" && cp /root/nems/ver.txt "/var/www/html/inc"
  echo "Done."
  
fi
echo ""
