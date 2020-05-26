#!/bin/bash
if [[ $EUID -ne 0 ]]; then
  echo "ERROR: This script must be run as root" 2>&1
  exit 1
else
  export COMMAND=$1

  upgraded=0
  ver=$(/usr/local/bin/nems-info nemsver) 
  echo "Running NEMS $ver"

  platform=$(/usr/local/share/nems/nems-scripts/info.sh platform)

  # Setup a patches.log file if one doesn't exist
  # This ensures once a patch is run, it doesn't run again
  # It can also be used to cross-reference the changelogs to
  # see what patches have been added to your NEMS server.
  if [[ ! -e /var/log/nems/patches.log ]]; then
    touch /var/log/nems/patches.log
  fi

  if [[ $COMMAND = "reset" ]]; then
   ver=$(/usr/local/bin/nems-info nemsbranch)
   echo "Forced reset to NEMS $ver"
  fi

  # Just in case apt is already doing stuff in the background, hang tight until it completes
  echo "Please wait for apt tasks to complete..."
  while fuser /var/{lib/{dpkg,apt/lists},cache/apt/archives}/lock >/dev/null 2>&1; do sleep 1; done
  echo "Done."
  # ----------------------------------

  # Just in case nems-quickfix is running
  quickfix=$(/usr/local/bin/nems-info quickfix)
  if [[ $quickfix == 1 ]]; then
    echo 'NEMS Linux is currently updating itself. Please wait...'
    while [[ $quickfix == 1 ]]
    do
      sleep 1
      quickfix=$(/usr/local/bin/nems-info quickfix)
    done
  fi


  # ensure /boot won't run out of space
  diskfree=$(($(stat -f --format="%a*%S" /boot)))
  if (( "$diskfree" < "12582912" )); then
    echo ""
    echo "/boot is too full for the upgrade."
    echo "Please manually remove old kernels before attempting this upgrade."
    exit
  fi



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
   echo "NEMS 1.5 is available now."
   echo "Please download it from nemslinux.com"
   exit
   echo "Upgrading from NEMS $ver to NEMS 1.5"
   echo "NEMS 1.5 has not yet been released."
   read -r -p "Do you want to install the beta version? [y/N] " beta
   echo ""
   if [[ $beta =~ ^([yY][eE][sS]|[yY])$ ]]; then

     # Make sure NEMS is at the current version with all fixes applied
     /usr/local/bin/nems-update

     # Backup (to migrate to new database), only if initialized
     initialized=`/usr/local/bin/nems-info init`
     if [[ $initialized == 1 ]]; then
       cp /var/www/html/backup/snapshot/backup.nems /tmp/
     fi

     # Run the upgrader
     /root/nems/nems-admin/nems-upgrade/1.4.1-1.5

     # Restore the backup, only if initialized
     if [[ $initialized == 1 ]]; then
       /usr/local/bin/nems-restore /tmp/backup.nems force
     fi

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

  if [[ $ver = "1.5" ]]; then
    echo ""

    if ! grep -q "PATCH-000001" /var/log/nems/patches.log; then
      echo "PATCH-000001 is available."
      echo "This patch reinstalls all check commands, fixing many issues."
      echo "It has to recompile each component, which takes a LONG time."
      echo "It will also cause a LOT of false notifications as the plugins"
      echo "are rebuilt. Alternatively you can just download a newer NEMS"
      echo "Linux build for your platform, released after March 15, 2019."
      read -r -p "Do you want to install this patch? [y/N] " PATCH000001
      echo ""
    fi

    if (( $platform == 11 )); then
      skip=1 # Means nothing, just skipping untested patch on XU4
    else
      if ! grep -q "PATCH-000003" /var/log/nems/patches.log; then
        echo "PATCH-000003 is available."
        echo "This patch changes your networking system to NetworkManager."
        echo "This allows you to control your network interfaces as per the"
        echo "instructions found at https://docs.nemslinux.com/networking"
        echo "*** BACKUP FIRST *** You may lose access to your NEMS server."
        echo "Alternatively you can just download a newer NEMS Linux build"
        echo "for your platform, released after March 15, 2019."
        read -r -p "Do you want to install this patch? [y/N] " PATCH000003
        echo ""
      fi
    fi

    if ! grep -q "PATCH-000004" /var/log/nems/patches.log; then
      echo "PATCH-000004 is available."
      echo "This patch upgrades the Internet speedtest check command so you"
      echo "can have it automatically use the best available server rather"
      echo "than the one specified in the checkcommand's arg."
      echo "Alternatively you can just download a newer NEMS Linux build for"
      echo "your platform, released after March 28, 2019."
      read -r -p "Do you want to install this patch? [y/N] " PATCH000004
      echo ""
    fi

    if ! grep -q "PATCH-000005" /var/log/nems/patches.log; then
      echo "PATCH-000005 is available."
      echo "This patch upgrades the thermal testing capabilities of"
      echo "check_sbc_temperature to use the improved thermal data from"
      echo "nems-info, which fixes some issues with boards that post thermal"
      echo "data in Celsius rather than millidegree Celsius."
      echo "Alternatively you can just download a newer NEMS Linux build for"
      echo "your platform, released after March 29, 2019."
      read -r -p "Do you want to install this patch? [y/N] " PATCH000005
      echo ""
    fi

    if ! grep -q "PATCH-000007" /var/log/nems/patches.log; then
      echo "PATCH-000007 is available."
      echo "This patch removes the package maintainer's version of the"
      echo "nrpe plugin, which has been orphaned. This version has crippled"
      echo "functionality, and will be replaced with a custom compiled"
      echo "version on your NEMS Server."
      read -r -p "Do you want to install this patch? [y/N] " PATCH000007
      echo ""
    fi

    if ! grep -q "PATCH-000008" /var/log/nems/patches.log; then
      echo "PATCH-000008 is available."
      echo "This patch adds a sophisticated realtime TV dashboard called"
      echo "NagiosTV to your NEMS Server. It was scheduled for NEMS Linux"
      echo "1.6, but I decided to make it available to you as a patch."
      read -r -p "Do you want to install this patch? [y/N] " PATCH000008
      echo ""
    fi


    # Run the selected patches
    if [[ $PATCH000001 =~ ^([yY][eE][sS]|[yY])$ ]]; then
      /root/nems/nems-admin/nems-upgrade/patches/000001 && upgraded=1
    fi
    if [[ $PATCH000003 =~ ^([yY][eE][sS]|[yY])$ ]]; then
      /root/nems/nems-admin/nems-upgrade/patches/000003 && upgraded=1
    fi
    if [[ $PATCH000004 =~ ^([yY][eE][sS]|[yY])$ ]]; then
      /root/nems/nems-admin/nems-upgrade/patches/000004 && upgraded=1
    fi
    if [[ $PATCH000005 =~ ^([yY][eE][sS]|[yY])$ ]]; then
      /root/nems/nems-admin/nems-upgrade/patches/000005 && upgraded=1
    fi
    if [[ $PATCH000007 =~ ^([yY][eE][sS]|[yY])$ ]]; then
      /root/nems/nems-admin/nems-upgrade/patches/000007 && upgraded=1
    fi
    if [[ $PATCH000008 =~ ^([yY][eE][sS]|[yY])$ ]]; then
      /root/nems/nems-admin/nems-upgrade/patches/000008 && upgraded=1
    fi

  fi

  # ----------------------------------
  if [[ $upgraded -ne 1 ]]; then
    echo "There are no rolling upgrades to install."
    echo ""
  else
    echo "You must reboot your NEMS Linux server for the changes to take effect."
    echo ""
    read -n 1 -s -p "Press any key to reboot (required)"
    reboot
  fi

fi

