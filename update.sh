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
  
  # Update nems-migrator
  printf "Updating nems-migrator... "
  cd /root/nems/nems-migrator && git pull
  echo "Done."

  # Get the latest version data from nems-migrator
  cp -f /root/nems/nems-migrator/data/nems/ver-current.txt /var/www/html/inc/ver-available.txt

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
  
fi
echo ""
