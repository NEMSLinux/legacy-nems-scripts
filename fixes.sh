#!/bin/bash

# No need to run this directly.
# Instead, run: sudo nems-update

 online=$(/usr/local/share/nems/nems-scripts/info.sh online)
 if [[ $online == 0 ]]; then
   echo "Internet is offline. NEMS needs Internet connectivity."
   echo ""
   exit
 fi

 # Just in case nems-quickfix is running
 fixes=$(/usr/local/bin/nems-info fixes)
 if [[ $fixes == 1 ]]; then
   echo 'NEMS Linux is currently updating itself. Please wait...'
   while [[ $fixes == 1 ]]
   do
     sleep 1
     fixes=$(/usr/local/bin/nems-info fixes)
   done
 fi
 echo $$ > /var/run/nems-fixes.pid


 # By default, do not reboot after update
 reboot=0

 # Setup a patches.log file if one doesn't exist
 # This ensures once a patch is run, it doesn't run again
 # It can also be used to cross-reference the changelogs to
 # see what patches have been added to your NEMS server.
 if [[ ! -e /var/log/nems/patches.log ]]; then
   touch /var/log/nems/patches.log
 fi

 # Just in case apt is already doing stuff in the background, hang tight until it completes
 echo "Please wait for apt tasks to complete..."
 while fuser /var/{lib/{dpkg,apt/lists},cache/apt/archives}/lock >/dev/null 2>&1; do sleep 1; done
 echo "Done."

 # Make sure /bin/systemctl resolves
 if [[ ! -e /bin/systemctl ]]; then
   if [[ -e /usr/bin/systemctl ]]; then
     ln -s /usr/bin/systemctl /bin/systemctl
   fi
 fi

 # Update apt here so we don't have to do it below
 apt clean
 apt update --allow-releaseinfo-change

 # using hard file location rather than symlink as symlink may not exist yet on older versions
 platform=$(/usr/local/share/nems/nems-scripts/info.sh platform)
 ver=$(/usr/local/share/nems/nems-scripts/info.sh nemsver) 

 # Fix Default Collector name if incorrect
 collector=$(/usr/bin/mysql -u nconf -h 127.0.0.1 -pnagiosadmin -D nconf -e "SELECT attr_value FROM ConfigValues WHERE fk_id_attr = 1;")
 if [[ ! $collector = *"Default Nagios"* ]]; then
   /usr/bin/mysql -u nconf -h 127.0.0.1 -pnagiosadmin -D nconf -e "UPDATE ConfigValues SET attr_value='Default Nagios' WHERE fk_id_attr = 1;"
 fi

 # Make a symlink to the PHP interpreter if it doesn't exist in /usr/local/bin
 if [[ ! -e /usr/local/bin/php ]]; then
  if [[ -e /usr/bin/php ]]; then
   ln -s /usr/bin/php /usr/local/bin/php
  fi
 fi

if [[ "$ver" == "1.4" ]]; then

  # Fix Nagios lockfile location (was causing systemd to be unable to restart Nagios)
  # Fix the original attempt
   if grep -q "lock_file=/var/lock/subsys/nagios" /usr/local/nagios/etc/nagios.cfg; then
     /bin/systemctl stop monit
     /bin/systemctl stop nagios
     echo Changing location of Nagios lock file in Nagios config...
     /bin/sed -i -- 's,lock_file=/var/lock/subsys/nagios,lock_file=/run/nagios.lock,g' /usr/local/nagios/etc/nagios.cfg
     /usr/bin/killall -9 nagios
     sleep 1
     echo Done.
   fi
   if grep -q "/var/lock/subsys/nagios" /etc/monit/conf.d/nems.conf; then
     /bin/systemctl stop monit
     /bin/systemctl stop nagios
     echo Changing location of Nagios lock file in Monit...
     /bin/sed -i -- 's,/var/lock/subsys/nagios,/run/nagios.lock,g' /etc/monit/conf.d/nems.conf
     /usr/bin/killall -9 nagios
     sleep 1
     echo Done.
   fi
  # Actual fix
   if grep -q "lock_file=/var/run/nagios/nagios.pid" /usr/local/nagios/etc/nagios.cfg; then
     /bin/systemctl stop monit
     /bin/systemctl stop nagios
     echo Changing location of Nagios lock file in Nagios config...
     /bin/sed -i -- 's,lock_file=/var/run/nagios/nagios.pid,lock_file=/run/nagios.lock,g' /usr/local/nagios/etc/nagios.cfg
     /usr/bin/killall -9 nagios
     sleep 1
     echo Done.
   fi
   if grep -q "/run/nagios/nagios.pid" /etc/monit/conf.d/nems.conf; then
     /bin/systemctl stop monit
     /bin/systemctl stop nagios
     echo Changing location of Nagios lock file in Monit...
     /bin/sed -i -- 's,/run/nagios/nagios.pid,/run/nagios.lock,g' /etc/monit/conf.d/nems.conf
     /usr/bin/killall -9 nagios
     sleep 1
     echo Done.
   fi
  /bin/systemctl start nagios
  /bin/systemctl start monit
  # /Fix Nagios lockfile location (was causing systemd to be unable to restart Nagios)


  # Add a symlink to the check_nrpe executable from within the correct Nagios plugin folder
  if [[ ! -e /usr/local/nagios/libexec/check_nrpe ]]; then
    if [[ -f /usr/lib/nagios/plugins/check_nrpe ]]; then
      ln -s /usr/lib/nagios/plugins/check_nrpe /usr/local/nagios/libexec/check_nrpe
    fi
  fi

  # Activate automatic security updates
  if [[ ! -e /etc/apt/apt.conf.d/20auto-upgrades ]]; then
    if [[ -f /root/nems/nems-admin/build/025-auto-upgrades ]]; then
      /root/nems/nems-admin/build/025-auto-upgrades
    fi
  fi

  # Fix RPi-Monitor CPU Frequency Reporting
  if (( $platform >= 0 )) && (( $platform <= 9 )); then
    if [[ ! -e /usr/bin/vcgencmd ]]; then
      apt -y install libraspberrypi-bin
      /bin/systemctl restart rpimonitor
    fi
  fi

  # NEMS 1.4 upgraded to 1.4.1 now that Raspberry Pi Zero W is fully supported
  # Because NEMS 1.4.1 meant a new image (for Pi Zero W) we'll roll up all 1.4 systems
  /bin/sed -i -e "s/1.4/1.4.1/g" /usr/local/share/nems/nems.conf

fi

# Fix strange issue where some systems got bumped to 1.4.1.1
if grep -q "version=1.4.1.1" /usr/local/share/nems/nems.conf; then
  /bin/sed -i -e "s/1.4.1.1/1.4.1/g" /usr/local/share/nems/nems.conf
  ver="1.4.1"
fi

if [[ "$ver" == "1.4.1" ]]; then

  # Fix permissions for Nagios log archiving
  chmod ug+x /usr/local/nagios/var/archives

  # Remove NEMS00000 patch from adagios.conf. It caused problems if user renamed admin user in NConf.
  if grep -q "# NEMS00000 A hacky way of disabling the admin portions of Adagios" /etc/adagios/adagios.conf; then
    /bin/sed -i~ '/# NEMS00000/d' /etc/adagios/adagios.conf
    /bin/sed -i~ '/enable_authorization=True/d' /etc/adagios/adagios.conf
    /bin/sed -i~ '/administrators="nobodyisadmin"/d' /etc/adagios/adagios.conf
  fi

  # Fix ownership of Nagios logs folder
  chown -R nagios:nagios /var/log/nagios

  # Fix ownership of new Adagios web folder (which is now a symlink)
  chown -R www-data:www-data /var/www/adagios/

  if ! grep -q "NEMS00000" /etc/monit/conf.d/nems.conf; then
    echo '# NEMS00000 Monitorix
check process monitorix with pidfile /run/monitorix.pid
    start program = "/etc/init.d/monitorix start"
    stop program  = "/etc/init.d/monitorix stop"
  ' >> /etc/monit/conf.d/nems.conf
    /bin/systemctl restart monit
  fi

  # Install 9590
  # A simple listener on Port 9590 for documentation examples
  if [[ ! -f /etc/init.d/9590 ]]; then
    cp /root/nems/nems-migrator/data/1.4/init.d/9590 /etc/init.d/
    /usr/sbin/update-rc.d 9590 defaults
    /usr/sbin/update-rc.d 9590 enable
    /etc/init.d/9590 start
  fi
  # And add it to monit
  if ! grep -q "NEMS00001" /etc/monit/conf.d/nems.conf; then
    echo '# NEMS00001 9590
check process 9590 with pidfile /run/9590.pid
    start program = "/etc/init.d/9590 start"
    stop program  = "/etc/init.d/9590 stop"
  ' >> /etc/monit/conf.d/nems.conf
    /bin/systemctl restart monit
  fi

  # Stop TTY1 from blanking since keyboard is likely not connected
  if ! grep -q "NEMS00000" /etc/rc.local; then
    /root/nems/nems-admin/build/011-tty
  fi

  # Remove Izzy's repository (at least temporarily).
  # cert is broken and it causes all kinds of grief.
  # Perhaps need to evaluate building monitorix ourselves.
  if [[ -f /etc/apt/sources.list.d/monitorix.list ]]; then
    rm /etc/apt/sources.list.d/monitorix.list
  fi

  # Allow the NEMS user to also administer nagios, access livestatus, etc.
  username=$(/usr/local/bin/nems-info username)
  usermod -a -G www-data,nagios $username

  # Install phoronix test suite to supplement our benchmarks
  if [[ ! -f /usr/bin/phoronix-test-suite ]]; then
    if [[ -f /root/nems/nems-admin/build/221-phoronix ]]; then
      /root/nems/nems-admin/build/221-phoronix
    fi
  fi

  # Install less command
    if [[ ! -e /usr/bin/less ]]; then
      apt -y install less
    fi

  # Install nems-tools
    if [[ ! -d /root/nems/nems-tools ]]; then
      cd /root/nems
      git clone https://github.com/Cat5TV/nems-tools
    fi

  # Clean up log errors from early build of nems-tools
  restartwarninglight=0 # Default
  if grep -q "PHP Warning" /var/log/nems/nems-tools/warninglight; then
    /bin/sed -i~ '/PHP Warning/d' /var/log/nems/nems-tools/warninglight
    restartwarninglight=1
  fi
  if grep -q "PHP Notice" /var/log/nems/nems-tools/warninglight; then
    /bin/sed -i~ '/PHP Notice/d' /var/log/nems/nems-tools/warninglight
    restartwarninglight=1
  fi
  if grep -q "sh: 1: /usr/local/bin/gpio: not found" /var/log/nems/nems-tools/warninglight; then
    /bin/sed -i~ '/sh: 1: \/usr\/local\/bin\/gpio: not found/d' /var/log/nems/nems-tools/warninglight
    restartwarninglight=1
  fi
  if grep -q "Parameter must be an array or an object that implements Countable" /var/log/nems/nems-tools/warninglight; then
    /bin/sed -i~ '/Parameter must be an array or an object that implements Countable/d' /var/log/nems/nems-tools/warninglight
    restartwarninglight=1
  fi

  # Restart warninglight if needed
  if (( $restartwarninglight == 1 )); then
    kill `cat /var/run/warninglight.pid` && sleep 1
    /root/nems/nems-tools/warninglight >> /var/log/nems/nems-tools/warninglight 2>&1 &
  fi

  # Install glances command
  if [[ ! -e /usr/bin/glances ]]; then
    apt -y install glances
  fi

  # Check if nagios-plugins was compiled with openssl. If not, recompile.
  checkssl=`/usr/local/nagios/libexec/check_http -S`
  if [[ $checkssl =~ 'SSL is not available' ]];
  then
    # Nagios Plugins was not compiled with SSL, so re-compile (was fixed November 14, 2018)
    /root/nems/nems-admin/build/051-nagios-plugins
  fi

  # Create the patch log dir
  if [ ! -d /var/log/nems/patches ]; then
    mkdir -p /var/log/nems/patches
  fi

  # Fix WiFi
  if [ ! -f /var/log/nems/patches/20181201-wifi ]; then
    online=$(/usr/local/share/nems/nems-scripts/info.sh online)
    if [[ $online == 1 ]]; then
      # Pi Specific
      if (( $platform >= 0 )) && (( $platform <= 9 )); then
        apt -y install raspberrypi-net-mods
      fi
      # This is the firmware for RPi WiFi but include for other boards in case needed
      # May not be available and may say not found, but this only runs once, so no worries
      apt -y install firmware-brcm80211
      apt -y install dhcpcd5
      apt -y install wireless-tools
      apt -y install wpasupplicant
      # Simple prevention of doing this every time fixes.sh runs
      installcheck=`/usr/bin/apt --installed -qq list dhcpcd5`
      if [[ $installcheck != '' ]]; then
        echo "Patched" > /var/log/nems/patches/20181201-wifi
        reboot=1 # Force reboot after this update to activate the firmware
      else
        echo "Patch appears to have failed"
      fi
    fi
  fi

fi
# end 1.4.1

if (( $(awk 'BEGIN {print ("'$ver'" >= "'1.4.1'")}') )); then

  # Benchmarks have not been run yet. Force the first-run (will also run every Sunday on Cron)
  if [[ ! -d /var/log/nems/benchmarks ]] || [[ ! -f /var/log/nems/benchmarks/7z-multithread ]]; then
    /usr/local/share/nems/nems-scripts/benchmark.sh
  fi

fi

if (( $(awk 'BEGIN {print ("'$ver'" >= "'1.5'")}') )); then

 # Move NEMS TV Dashboard out of nems-www
 if [[ ! -d /var/www/nems-tv ]]; then
   cd /var/www
   # Obtain nems-tv
   git clone https://github.com/Cat5TV/nems-tv
   # If the clone was successful, enable nems-tv
   if [[ -d /var/www/nems-tv ]]; then
     # Add the apache2 conf
     cp -f /var/www/nems-tv/nems-tv.conf /etc/apache2/conf-available/
     # Set permissions
     chown -R www-data:www-data /var/www/nems-tv
     chown root:root /etc/apache2/conf-available/nems-tv.conf
     # Update nems-www to remove the /tv folder
     cd /var/www/html
     git pull
     # Enable nems-tv
     /usr/sbin/a2enconf nems-tv
     # Reload apache2
     /bin/systemctl reload apache2
   fi
 fi

 # Upgrade check_speedtest
 if ! grep -q "NEMS00001" /usr/local/nagios/libexec/check_speedtest-cli.sh; then
   cp /root/nems/nems-migrator/data/1.5/nagios/plugins/check_speedtest-cli.sh /usr/local/nagios/libexec/
 fi

 # Add nems-install command
 if [[ ! -e /usr/local/bin/nems-install ]]; then
   ln -s /usr/local/share/nems/nems-scripts/installers/install-vim3.sh /usr/local/bin/nems-install
 fi


# Increase upload size for background images
  if [[ -e /etc/php/7.3/phpdbg/php.ini ]]; then
   reloadapache=0
   if ! grep -q "NEMS00001" /etc/php/7.3/phpdbg/php.ini; then
    /bin/sed -i '/post_max_size =/c\; NEMS00001\npost_max_size = 20M' /etc/php/7.3/phpdbg/php.ini
    /bin/sed -i '/upload_max_filesize =/c\upload_max_filesize = 16M' /etc/php/7.3/phpdbg/php.ini
    reloadapache=1
   fi
  fi
  if [[ -e /etc/php/7.2/phpdbg/php.ini ]]; then
   if ! grep -q "NEMS00001" /etc/php/7.2/phpdbg/php.ini; then
    /bin/sed -i '/post_max_size =/c\; NEMS00001\npost_max_size = 20M' /etc/php/7.2/phpdbg/php.ini
    /bin/sed -i '/upload_max_filesize =/c\upload_max_filesize = 16M' /etc/php/7.2/phpdbg/php.ini
    reloadapache=1
   fi
   if [[ $reloadapache == 1 ]]; then
    /bin/systemctl reload apache2
   fi
  fi

  # Give Adagios access to socket
  /bin/sed -i -- 's,livestatus_path = None,livestatus_path = "/usr/local/nagios/var/rw/live.sock",g' /var/www/adagios/settings.py

  # Ensure ownership of nems-www is set to the apache2 user
  chown -R www-data:www-data /var/www/html

  # Fix logs for Nagios (in particular, this fixes Adagios history)
  if [[ ! -d /var/log/nagios/archives ]]; then
    mkdir /var/log/nagios/archives
    chown nagios:nagios /var/log/nagios/archives
    chmod ug+x /var/log/nagios/archives
    chmod g+ws /var/log/nagios/archives
  fi

  # Allow Nagios to check for external commands from Nagios Core web UI or Adagios
  if grep -q "check_external_commands=0" /usr/local/nagios/etc/nagios.cfg; then
    /bin/sed -i -- 's/check_external_commands=0/check_external_commands=1/g' /usr/local/nagios/etc/nagios.cfg
    /bin/systemctl restart nagios
  fi

 # Make Adagios work on NEMS 1.4.1+
   if [[ -d /var/www/adagios ]]; then
     rm -rf /var/www/adagios
     ln -s /usr/local/lib/python2.7/dist-packages/adagios /var/www/adagios
   fi

   if ! grep -q "NEMS00000" /var/www/adagios/settings.py; then
     cp -f /root/nems/nems-migrator/data/1.4/adagios/settings.py /var/www/adagios/
     chown www-data:www-data /var/www/adagios/settings.py
     adagioscache=1;
   fi

   if ! grep -q "NEMS00000" /var/www/adagios/templates/403.html; then
     cp -f /root/nems/nems-migrator/data/1.4/adagios/templates/403.html /var/www/adagios/templates/
     adagioscache=1;
   fi
   if ! grep -q "NEMS00000" /var/www/adagios/templates/base.html; then
     cp -f /root/nems/nems-migrator/data/1.4/adagios/templates/base.html /var/www/adagios/templates/
     adagioscache=1;
   fi
   if [[ $adagioscache = "1" ]]; then
     cd /var/www/adagios
     /usr/bin/find /var/www/adagios/ -name "*.pyc" -exec rm -rf {} \;
     /usr/local/bin/pip install --trusted-host pypi.python.org --trusted-host pypi.org --trusted-host files.pythonhosted.org --trusted-host piwheels.org --upgrade pip
     /usr/local/bin/pip install --trusted-host pypi.python.org --trusted-host pypi.org --trusted-host files.pythonhosted.org --trusted-host piwheels.org django-clear-cache
     /usr/bin/python manage.py clear_cache
     /bin/systemctl restart apache2
   fi

  # Move bootscreen to TTY7 and disable TTY1
    if ! grep -q "NEMS00001" /etc/rc.local; then
      /root/nems/nems-admin/build/010-tty
    fi

  # Don't output kernel messages -- such as firewall blocks -- to TTY
    if ! grep -q "NEMS00002" /etc/rc.local; then
      /root/nems/nems-admin/build/012-tty
    fi

  # Allow unauthenticated SMTP
    if ! grep -q "NEMS00002" /usr/local/nagios/libexec/nems_sendmail_host; then
      cp -f /root/nems/nems-migrator/data/1.5/nagios/plugins/nems_sendmail_* /usr/local/nagios/libexec/
    fi

  # Replace NEMS branding in Cockpit in case an update removes it
    /root/nems/nems-admin/build/171-cockpit
    /root/nems/nems-admin/build/999-cleanup

  # Install glances command
  if [[ ! -e /usr/bin/glances ]]; then
    apt -y install glances
  fi

  # Mark filesystem as resized if greater than 9 GB, just in case the patch didn't get logged or is virtual appliance (etc)
    size=$(df --output=target,size /root | awk ' NR==2 { print $2 } ')
    if (( $size > 9000000 )); then
      # Log that patch (resize) has been applied to this system
      # Activates features such as bootscreen.sh
      if ! grep -q "PATCH-000002" /var/log/nems/patches.log; then
        echo "PATCH-000002" >> /var/log/nems/patches.log
      fi
    fi

  # enable rc.local service if not enabled (ie., Rock64)
    if [[ ! -e /etc/systemd/system/rc-local.service ]]; then
      /root/nems/nems-admin/build/009-rc_local
      /root/nems/nems-admin/build/999-cleanup
    fi

  # Patch check_rpi_temperature to include error handling for when the thermal sensor doesn't exist (ie., VM)
    if ! grep -q "PATCH-000006" /var/log/nems/patches.log; then
      cp -f /root/nems/nems-migrator/data/1.5/nagios/plugins/check_rpi_temperature /usr/lib/nagios/plugins/
      echo "PATCH-000006" >> /var/log/nems/patches.log
    fi

  # Add some error handling if nems-mailtest was run as a non-root user
    if ! grep -q "if (!@file_put_contents('/var/log/nagios/nagios.log'" /usr/local/nagios/libexec/nems_sendmail_service; then
      cp -f /root/nems/nems-migrator/data/1.5/nagios/plugins/nems_sendmail_service /usr/local/nagios/libexec/
    fi
    if ! grep -q "if (!@file_put_contents('/var/log/nagios/nagios.log'" /usr/local/nagios/libexec/nems_sendmail_host; then
      cp -f /root/nems/nems-migrator/data/1.5/nagios/plugins/nems_sendmail_host /usr/local/nagios/libexec/
    fi

  # Forcibly disable TLS if disabled in NEMS SST
    if ! grep -q "SMTPAutoTLS" /usr/local/nagios/libexec/nems_sendmail_service; then
      cp -f /root/nems/nems-migrator/data/1.5/nagios/plugins/nems_sendmail_service /usr/local/nagios/libexec/
    fi
    if ! grep -q "SMTPAutoTLS" /usr/local/nagios/libexec/nems_sendmail_host; then
      cp -f /root/nems/nems-migrator/data/1.5/nagios/plugins/nems_sendmail_host /usr/local/nagios/libexec/
    fi


  # Fix issues from early Armbian-based Build Bases
    if [[ -d /usr/lib/armbian ]]; then

      # Stop /tmp and /var/log from being loaded in zram
      sed -i '/\/tmp/d' /etc/fstab
      umount /tmp 2>&1

      systemctl stop armbian-zram-config
      systemctl disable armbian-zram-config

      systemctl stop armbian-ramlog
      systemctl disable armbian-ramlog

      # Delete the services
      rm -f /etc/systemd/system/sysinit.target.wants/armbian-*

      # Remove Armbian-specific stuff
      rm -rf /usr/lib/armbian
      rm -rf /usr/share/armbian
      rm -f /boot/armbian_first_run*
      apt -y remove --purge armbian-config

      # Change name of armbianEnv file to bootEnv
      mv /boot/armbianEnv.txt /boot/bootEnv.txt
      sed -i 's/armbianEnv/bootEnv/g' /boot/boot.cmd

      reboot=1

    fi

  #asdf
fi




if (( $(awk 'BEGIN {print ("'$ver'" <= "'1.3.1'")}') )); then
  /usr/local/share/nems/nems-scripts/fixes-legacy.sh
fi


# Install nems-upgrade command if not already
if [ ! -f /usr/local/bin/nems-upgrade ]; then
  ln -s /usr/local/share/nems/nems-scripts/upgrade.sh /usr/local/bin/nems-upgrade
fi

# Install nems-update command if not already
if [ ! -f /usr/local/bin/nems-update ]; then
  ln -s /usr/local/share/nems/nems-scripts/update.sh /usr/local/bin/nems-update
fi

# Install nems-info command if not already
if [ ! -f /usr/local/bin/nems-info ]; then
  ln -s /usr/local/share/nems/nems-scripts/info.sh /usr/local/bin/nems-info
fi

# Install nems-cert command
if [ ! -f /usr/local/bin/nems-cert ]; then
  ln -s /usr/local/share/nems/nems-scripts/gen-cert.sh /usr/local/bin/nems-cert
fi

# Install nems-quickfix command
if [ ! -f /usr/local/bin/nems-quickfix ]; then
  ln -s /usr/local/share/nems/nems-scripts/quickfix.sh /usr/local/bin/nems-quickfix
fi

# Install nems-support command
if [ ! -f /usr/local/bin/nems-support ]; then
  ln -s /root/nems/nems-migrator/support.sh /usr/local/bin/nems-support
fi

# Add new cron entries

  # Dump current crontab to tmp file
    crontab -l > /tmp/cron.tmp

  # Benchmark log
  if ! grep -q "NEMS0001" /tmp/cron.tmp; then
    printf "\n# Run a weekly system benchmark of the NEMS server to assist with troubleshooting NEMS0001\n0 3 * * 0 /usr/local/share/nems/nems-scripts/benchmark.sh > /var/log/nems/benchmark.log\n" >> /tmp/cron.tmp
    cronupdate=1
  fi

  # NEMS Anonymous Stats
  if ! grep -q "NEMS0002" /tmp/cron.tmp; then
    printf "\n# NEMS Anonymous Stats NEMS0002\n0 0 * * * /usr/local/share/nems/nems-scripts/stats.sh\n" >> /tmp/cron.tmp
    cronupdate=1
  fi

  if ! grep -q "NEMS0003" /tmp/cron.tmp; then
    printf "\n# Load Average Over One Week Logger NEMS0003\n*/15 * * * * /usr/local/share/nems/nems-scripts/loadlogger.sh cron\n" >> /tmp/cron.tmp
    cronupdate=1
  fi

  # Fix first-gen NEMS0003
  if ! grep -q "loadlogger.sh cron" /tmp/cron.tmp; then
    /bin/sed -i -- 's/loadlogger.sh/loadlogger.sh cron/g' /tmp/cron.tmp
    cronupdate=1
  fi

  if ! grep -q "NEMS0004" /tmp/cron.tmp; then
    printf "\n# Detect Hardware Model NEMS0004\n@reboot /usr/local/share/nems/nems-scripts/hw_model.sh\n" >> /tmp/cron.tmp
    cronupdate=1
  fi

  if ! grep -q "NEMS0005" /tmp/cron.tmp; then
    printf "\n# Log Package Version Info NEMS0005\n0 5 * * 0 /usr/local/share/nems/nems-scripts/versions.sh > /var/log/nems/package-versions.log\n" >> /tmp/cron.tmp
    cronupdate=1
  fi

  # Change nems-update cronjob to nems-quickfix, cutting patch delivery time in half!
  if grep -q "/update.sh" /tmp/cron.tmp; then
    /bin/sed -i -- 's,/update.sh,/quickfix.sh > /dev/null 2\>\&1,g' /tmp/cron.tmp
    cronupdate=1
  fi

  if ! grep -q "NEMS0006" /tmp/cron.tmp; then
    printf "\n# Log CPU Temperature NEMS0006\n*/15 * * * * /usr/local/share/nems/nems-scripts/thermallogger.sh cron\n" >> /tmp/cron.tmp
    cronupdate=1
  fi

  if ! grep -q "NEMS0007" /tmp/cron.tmp; then
    printf "\n# Run NEMS Migrator Off-Site Backup NEMS0007\n30 23 * * * /root/nems/nems-migrator/offsite-backup.sh > /dev/null 2>&1\n" >> /tmp/cron.tmp
    cronupdate=1
  else # Move to 11:30pm so the daily OSB is more accurate to the date (originally it ran at 4am - this patches previously patched systems)
    if grep -q "0 4 \* \* \* /root/nems/nems-migrator/offsite-backup.sh" /tmp/cron.tmp; then
      /bin/sed -i -- 's,0 4 \* \* \* /root/nems/nems-migrator/offsite-backup.sh,30 23 * * * /root/nems/nems-migrator/offsite-backup.sh,g' /tmp/cron.tmp
      cronupdate=1
    fi
  fi

  if ! grep -q "NEMS0008" /tmp/cron.tmp; then
    printf "\n# Log NEMS Migrator Off-Site Backup Stats NEMS0008\n30 4 * * * /usr/local/share/nems/nems-scripts/osb-stats.sh > /dev/null 2>&1\n" >> /tmp/cron.tmp
    cronupdate=1
  fi
  
  if ! grep -q "NEMS0009" /tmp/cron.tmp; then
    printf "\n# Test Memory for Errors Weekly NEMS0009\n0 3 * * 0 /usr/sbin/memtester 500 10 > /var/log/nems/memtest.log\n" >> /tmp/cron.tmp
    cronupdate=1
  fi

  if ! grep -q "NEMS0010" /tmp/cron.tmp; then
    printf "\n# Detect and Set Local DNS Settings NEMS0010\n@reboot /sbin/resolvconf -u > /dev/null 2>&1\n" >> /tmp/cron.tmp
    cronupdate=1
  fi

  if ! grep -q "NEMS0011" /tmp/cron.tmp; then
    printf "\n# support.nems Self-Destruct NEMS0011\n* * * * * /root/nems/nems-migrator/support-sd.sh > /dev/null 2>&1\n" >> /tmp/cron.tmp
    cronupdate=1
  fi

  if ! grep -q "NEMS0012" /tmp/cron.tmp; then
    if [[ ! -d /var/log/nems/nems-tools/ ]]; then
      mkdir /var/log/nems/nems-tools/
    fi
    printf "\n# nems-tools warninglight NEMS0012\n@reboot /root/nems/nems-tools/warninglight >> /var/log/nems/nems-tools/warninglight 2>&1\n" >> /tmp/cron.tmp
    cronupdate=1
    # Run it now
    /root/nems/nems-tools/warninglight >> /var/log/nems/nems-tools/warninglight 2>&1 &
  fi

  if ! grep -q "NEMS0013" /tmp/cron.tmp; then
    printf "\n# NEMS Cloud State Update NEMS0013\n* * * * * /usr/local/share/nems/nems-scripts/cloud.sh > /dev/null 2>&1\n" >> /tmp/cron.tmp
    cronupdate=1
  fi

  if ! grep -q "NEMS0014" /tmp/cron.tmp; then
    printf "\n# NEMS Checkin NEMS0014\n*/5 * * * * /usr/local/share/nems/nems-scripts/checkin.sh > /dev/null 2>&1\n" >> /tmp/cron.tmp
    cronupdate=1
  fi

  # Install piWatcher daemon, will run every 10 seconds if hat present. Otherwise, will do nothing.
  if ! grep -q "NEMS0015" /tmp/cron.tmp; then
    if [[ $platform < 10 ]]; then
      printf "\n# piWatcher NEMS0015\n@reboot /root/nems/nems-tools/piwatcher > /dev/null 2>&1\n" >> /tmp/cron.tmp
      cronupdate=1
    fi
  fi

  # Install the NEMS Tools GPIO Extender daemon.
  if ! grep -q "NEMS0016" /tmp/cron.tmp; then
    printf "\n# NEMS Tools GPIO Extender Server NEMS0016\n@reboot /root/nems/nems-tools/gpio-extender/gpioe-server > /dev/null 2>&1\n" >> /tmp/cron.tmp
    cronupdate=1
    # Run it
    restartwarninglight=1
    /root/nems/nems-tools/gpio-extender/gpioe-server > /dev/null 2>&1 &
  fi


  # Import revised crontab
  if [[ "$cronupdate" == "1" ]]
  then
    crontab /tmp/cron.tmp
  fi

  # Remove temp file
  rm /tmp/cron.tmp

# /Add new cron entries


# Update apt Lists
apt update


# Remove apikey if it is not set (eg., did not get a response from the server)
apikey=$(cat /usr/local/share/nems/nems.conf | grep apikey | printf '%s' $(cut -n -d '=' -f 2))
if [[ $apikey == '' ]]; then
  /bin/sed -i~ '/apikey/d' /usr/local/share/nems/nems.conf
fi

# Randomize nemsadmin password if NEMS is initialized
# After nems-init you must first become root, then su nemsadmin to access nemsadmin
  if [ -d /home/nemsadmin ]; then # the nemsadmin user folder exists
    usercount=$(find /home/* -maxdepth 0 -type d | wc -l)
    if (( $usercount > 1)); then # Only do this if there are other users on the system
    # This assumes (and rightly so) that an extra user means NEMS has been initialized
    # It would be best and most accurate to also/instead check the init status
      rndpass=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w ${1:-32} | head -n 1)
      echo -e "$rndpass\n$rndpass" | passwd nemsadmin >/tmp/init 2>&1
      # Attempt to delete the nemsadmin user: will not proceed if in use
      # Doing this now instead of during init to avoid crashing during init
      # where user continues as nemsadmin
      userdel -r nemsadmin
    fi
  fi

# Detect Platform if failed previously
  if [ ! -f /var/log/nems/hw_model ]; then
    /usr/local/share/nems/nems-scripts/hw_model.sh
  fi

# Load ZRAM Swap at boot
  if ! grep -q "NEMS0000" /etc/rc.local; then
    # fix comment so it doesn't get replaced
    /bin/sed -i -- 's,"exit 0",exit with errorcode 0,g' /etc/rc.local
    # add to boot process
    /bin/sed -i -- 's,exit 0,# Load Swap into ZRAM NEMS0000\n/usr/local/share/nems/nems-scripts/zram.sh > /dev/null 2>\&1\n\nexit 0,g' /etc/rc.local
    # run it now
    /usr/local/share/nems/nems-scripts/zram.sh # Do it now
  fi

if [ $(dpkg-query -W -f='${Status}' memtester 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
  apt-get -y install memtester
fi

# Final cleanup
/root/nems/nems-admin/build/999-cleanup

rm -f /var/run/nems-fixes.pid

# If a reboot is required, do it now
if [[ $reboot == 1 ]]; then
  /sbin/reboot
fi
