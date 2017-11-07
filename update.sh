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
  if [ -d /usr/local/share/nems/nems-scripts ]; then
    cd /usr/local/share/nems/nems-scripts && git pull
  fi
  # Check if we are still on legacy 1.1 or 1.2.x and update that way, otherwise fixes will not run to patch it
  if [ -d /home/pi/nems-scripts ]; then
    cd /home/pi/nems-scripts && git pull
  fi
  echo "Done."

  # Perform any fixes that have been released since NEMS was built
  printf "Running updates and fixes... "
  if [ -d /usr/local/share/nems/nems-scripts ]; then
    /usr/local/share/nems/nems-scripts/fixes.sh
  fi
  # Legacy support
  if [ -d /home/pi/nems-scripts ]; then
    /home/pi/nems-scripts/fixes.sh
  fi
  echo "Done."

fi
echo ""
