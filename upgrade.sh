#!/bin/bash
if [[ $EUID -ne 0 ]]; then
  echo "ERROR: This script must be run as root" 2>&1
  exit 1
else

  ver=$(cat "/var/www/html/inc/ver.txt") 
  if [[ $ver = "1.2.1" ]]; then
   echo "Running NEMS 1.2.1"
   echo "Upgrading to NEMS 1.2.2"

   # Add nems-www in place of the old page
   echo "Adding nems-www..."
   mv /var/www/html /var/www/html-old
   cd /var/www/
   git clone https://github.com/Cat5TV/nems-www
   mv nems-www html
   chown -R www-data:www-data html
   echo "nems-www is installed."

   # Create symlinks added in this release
   echo "Creating symbolic links..."
   ln -s /home/pi/nems-scripts/update.sh /usr/bin/nems-update
   echo "Done."

   # Copy the fixed MOTD.
   echo "Patching MOTD..."
   cp -f /home/pi/nems-scripts/upgrades/1.2.2/motd.tcl /etc/
   echo "Done."

   # Update packages
   echo "Updating OS..."
   apt-get update && apt-get -y upgrade && apt-get -y dist-upgrade
   echo "Done."

   # Update NEMS to know this is version 1.2.2
   echo "Changing version to 1.2.2..."
   echo "1.2.2" > /root/nems/ver.txt
   echo "Done."

   # Tell the web cache to serve up the file from midnight
   timestamp=$( /bin/date --date="today 00:00:01 UTC -5 hours" +%s )
   /usr/bin/wget -q -O /var/www/html/inc/ver-available.txt http://cdn.zecheriah.com/baldnerd/nems/ver-current.txt#$timestamp

   # Copy the version data to the public inc folder
   printf "Checking for new NEMS version... "
   test -d "/var/www/html/inc" || mkdir -p "/var/www/html/inc" && cp /root/nems/ver.txt "/var/www/html/inc"
   echo "Done."

   echo ""
   exit
  fi

fi
