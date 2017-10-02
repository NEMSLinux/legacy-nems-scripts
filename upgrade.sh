#!/bin/bash
if [[ $EUID -ne 0 ]]; then
  echo "ERROR: This script must be run as root" 2>&1
  exit 1
else
  upgraded=0
  ver=$(/usr/bin/nems-info nemsver) 
  echo "Running NEMS $ver"

  # ----------------------------------
  
# Upgrade from NEMS 1.2.1 to NEMS 1.2.2
  if [[ $ver = "1.2.1" ]]; then
   echo "Upgrading from NEMS $ver to NEMS 1.2.2"

   # Add nems-www in place of the old page
   echo "Adding nems-www..."
   mv /var/www/html /var/www/html-old
   cd /var/www/
   git clone https://github.com/Cat5TV/nems-www
   mv nems-www html
   chown -R www-data:www-data html
   echo "nems-www is installed."

   # Setup the version info with nems-www
     printf "Configurating NEMS version information... "
     test -d "/var/www/html/inc" || mkdir -p "/var/www/html/inc" && cp -f /root/nems/nems-migrator/data/nems/ver-current.txt /var/www/html/inc/ver-available.txt
     echo "Done."
   
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
   oldver=$ver
   ver="1.2.2"
   sed -i -e "s/$oldver/$ver/g" /home/pi/nems.conf
   echo "Done."

   echo ""
   upgraded=1
  fi
  
# Upgrade from NEMS 1.2.2 to NEMS 1.2.3
  if [[ $ver = "1.2.2" ]]; then

   echo "Upgrading from NEMS $ver to NEMS 1.2.3"

   # Reduce swap partition usage and instead use the cache / buffer space allocated to tmpfs
   echo "Reducing swappiness..."
  echo "
###################################################################
# Reduce the amount of Swappiness so NEMS will instead free up cache
vm.swappiness = 10
###################################################################
" >> /etc/sysctl.conf
   echo "Done."

   echo "Disabling swap altogether..."
    # Disable Swap
      /sbin/dphys-swapfile swapoff
   echo "Done."
   
   # Create symlinks added in this release
   echo "Creating symbolic links..."
    # Add nems-benchmark command
    if [ ! -f /usr/bin/nems-benchmark ]; then
      ln -s /home/pi/nems-scripts/benchmark.sh /usr/bin/nems-benchmark
      echo "Added nems-benchmark command."
    fi

    # Add nems-mailtest command
    if [ ! -f /usr/bin/nems-mailtest ]; then
      ln -s /home/pi/nems-scripts/mailtest.sh /usr/bin/nems-mailtest
      echo "Added nems-mailtest command."
    fi
   echo "Done."


    # Install hdparm required by nems-benchmark
    if [ ! -f /sbin/hdparm ]; then
      echo "Installing hdparm..."
      apt-get update && apt-get -y install hdparm
      echo "Done."
    fi


    # Enable SSL support and load default certs if none exist
    if [ ! -f /etc/apache2/mods-enabled/ssl.load ]; then
      echo "Enabling SSL Support..."
      a2enmod ssl
      echo "Importing and activating self-signed certs..."
      mv /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/000-default.conf.bak
      if [ ! -f /var/www/certs/ca.pem ]; then
        # Load the default certs since none exist yet (which would be the case in NEMS 1.1 or 1.2)
        cp -R /root/nems/nems-migrator/data/certs /var/www/
      fi
      cp /home/pi/nems-scripts/upgrades/1.2.2/000-default.conf /etc/apache2/sites-available/
      echo "Done."
      echo "Restarting Apache..."
      systemctl restart apache2
      echo "Done."
      echo "Done setting up SSL."
    fi

   # Update packages
   echo "Updating OS..."
   apt-get update && apt-get -y upgrade && apt-get -y dist-upgrade
   echo "Done."

   echo "Installing additional packages..."
   # Add hdparm (used by benchmark tool)
   apt-get update && apt-get -y install hdparm
   echo "Done."

   # Update NEMS to know the new version
   echo "Changing version to 1.2.3..."
   oldver=$ver
   ver="1.2.3"
   sed -i -e "s/$oldver/$ver/g" /home/pi/nems.conf
   echo "Done."

   echo ""
   upgraded=1
  fi
  
  # ----------------------------------
  if [[ $upgraded -ne 1 ]]; then
    echo "There are no rolling upgrades available for NEMS $ver"
    echo ""
  fi

fi

