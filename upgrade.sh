#!/bin/bash
if [[ $EUID -ne 0 ]]; then
  echo "ERROR: This script must be run as root" 2>&1
  exit 1
else
  export COMMAND=$1

  upgraded=0
  ver=$(/usr/local/bin/nems-info nemsver) 
  echo "Running NEMS $ver"

  if [[ $COMMAND = "reset" ]]; then
   ver=$(/usr/local/bin/nems-info nemsbranch)
   echo "Forced reset to NEMS $ver"
  fi

  # Just in case apt is already doing stuff in the background, hang tight until it completes
  echo "Please wait for apt tasks to complete..."
  while fuser /var/{lib/{dpkg,apt/lists},cache/apt/archives}/lock >/dev/null 2>&1; do sleep 1; done
  echo "Done."
  # ----------------------------------
  
# Jump irrelevant version 1.2 (did not have rolling updates, but is still the top level of the 1.2.x branch)
  if [[ $ver = "1.2" ]]; then
   ver="1.2.1"
  fi

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
   ln -s /usr/local/share/nems/nems-scripts/update.sh /usr/local/bin/nems-update
   echo "Done."

   # Copy the fixed MOTD.
   echo "Patching MOTD..."
   cp -f /usr/local/share/nems/nems-scripts/upgrades/1.2.2/motd.tcl /etc/
   echo "Done."

   # Update packages
   echo "Updating OS..."
   apt-get update && apt-get -y upgrade && apt-get -y dist-upgrade
   echo "Done."

   # Update NEMS to know this is version 1.2.2
   echo "Changing version to 1.2.2..."
   oldver=$ver
   ver="1.2.2"
   sed -i -e "s/$oldver/$ver/g" /usr/local/share/nems/nems.conf
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
    if [ ! -f /usr/local/bin/nems-benchmark ]; then
      ln -s /usr/local/share/nems/nems-scripts/benchmark.sh /usr/local/bin/nems-benchmark
      echo "Added nems-benchmark command."
    fi

    # Add nems-mailtest command
    if [ ! -f /usr/local/bin/nems-mailtest ]; then
      ln -s /usr/local/share/nems/nems-scripts/mailtest.sh /usr/local/bin/nems-mailtest
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
      cp /usr/local/share/nems/nems-scripts/upgrades/1.2.2/000-default.conf /etc/apache2/sites-available/
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
   sed -i -e "s/$oldver/$ver/g" /usr/local/share/nems/nems.conf
   echo "Done."

   echo ""
   upgraded=1
  fi

# Upgrade from NEMS 1.3 to NEMS 1.3.1
  if [[ $ver = "1.3" ]]; then
   echo "Upgrading from NEMS $ver to NEMS 1.3.1"

   # Copy the fixed MOTD.
   echo "Patching MOTD..."
   cp -f /usr/local/share/nems/nems-scripts/upgrades/1.3.1/motd.tcl /etc/
   echo "Done."
   
   # Upgrade authentic theme
   echo "Upgrading Webmin authentic-theme..."
   systemctl stop webmin
   wget -O /tmp/authentic-theme.gz https://github.com/qooob/authentic-theme/archive/19.09.2.tar.gz
   cd /tmp
   tar -xvzf authentic-theme.gz
   mv authentic-theme-19.09.2 authentic-theme
   mv /usr/share/webmin/authentic-theme /tmp/authentic-theme~
   mv /tmp/authentic-theme /usr/share/webmin/
   systemctl start webmin
   echo "Done."

   # Upgrade packages
   echo "Updating OS..."
   apt-get update && apt-get -y upgrade && apt-get -y dist-upgrade
   echo "Done."

   # Upgrade kernel
   echo "Upgrading kernel..."
   SKIP_WARNING=1 /usr/bin/rpi-update
   echo "Done."

   # Update NEMS to know the new version
   echo "Changing version to 1.3.1..."
   oldver=$ver
   ver="1.3.1"
   sed -i -e "s/$oldver/$ver/g" /usr/local/share/nems/nems.conf
   echo "Done."

   echo ""
   upgraded=1

  fi

# Upgrade from NEMS 1.4.1 to NEMS 1.5
  if [[ $ver = "1.4.1" ]]; then

   echo "Upgrading from NEMS $ver to NEMS 1.5"

   echo "NEMS 1.5 has not yet been released."

   read -p "Do you want to install the beta version? [Y/N] " -n 1 -r beta
   echo ""
   if [[ $beta =~ ^[Yy]$ ]]
   then
     # Backup (to migrate to new database)
     cp /var/www/html/backup/snapshot/backup.nems /tmp/

     # Run the upgrader
     /root/nems/nems-admin/nems-upgrade/1.4.1-1.5

     # Restore the backup
     /usr/local/bin/nems-restore /tmp/backup.nems force

     # Update NEMS to know this is version 1.2.2
     echo "Changing version to 1.5..."
     oldver=$ver
     ver="1.5"
     sed -i -e "s/$oldver/$ver/g" /usr/local/share/nems/nems.conf
     echo "Done."

     echo ""
     upgraded=1
   else
     echo "Aborted."
     exit
   fi
  fi

  
  # ----------------------------------
  if [[ $upgraded -ne 1 ]]; then
    echo "There are no rolling upgrades available for NEMS $ver"
    echo ""
  else
    echo "You must reboot your NEMS Linux server for the changes to take effect."
    echo ""
    read -n 1 -s -p "Press any key to reboot (required)"
    reboot
  fi

fi

