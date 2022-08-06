#!/bin/bash

# No need to run this directly.
# Instead, run: sudo nems-update

 online=$(/usr/local/bin/nems-info online)
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

 # using hard file location rather than symlink as symlink may not exist yet on older versions
 platform=$(/usr/local/bin/nems-info platform)
 ver=$(/usr/local/bin/nems-info nemsver)
 branch=$(/usr/local/bin/nems-info nemsbranch)

 # Update apt here so we don't have to do it below
 apt-get clean
 if (( $platform >= 0 )) && (( $platform <= 9 )); then
   apt-get update --allow-releaseinfo-change
 else
   apt-get update
 fi

 # Fix Default Collector name if incorrect
 collector=$(/usr/bin/mysql -u nconf -h 127.0.0.1 -pnagiosadmin -D nconf -e "SELECT attr_value FROM ConfigValues WHERE fk_id_attr = 1;")
 if [[ ! $collector = *"Default Nagios"* ]]; then
   /usr/bin/mysql -u nconf -h 127.0.0.1 -pnagiosadmin -D nconf -e "UPDATE ConfigValues SET attr_value='Default Nagios' WHERE fk_id_attr = 1;"
 fi

if (( $(awk 'BEGIN {print ("'$ver'" >= "'1.6'")}') )); then

  # Symlink python2 binary to python3 to prevent errors for scripts that call /usr/bin/python
  # This method allows us to keep compatibility with old versions of NEMS Linux a little more easily
  if [[ ! -e /usr/bin/python ]] && [[ -e /usr/bin/python3 ]]; then
    ln -s /usr/bin/python3 /usr/bin/python
  fi

fi


if (( $(awk 'BEGIN {print ("'$ver'" >= "'1.4.1'")}') )); then

  # Benchmarks have not been run yet. Force the first-run (will also run every Sunday on Cron)
  if [[ ! -d /var/log/nems/benchmarks ]] || [[ ! -f /var/log/nems/benchmarks/7z-multithread ]]; then
    /usr/local/bin/nems-benchmark
  fi

  if ! grep -q "NEMS00000" /etc/monit/conf.d/nems.conf; then
    echo '# NEMS00000 Monitorix
check process monitorix with pidfile /run/monitorix.pid
    start program = "/etc/init.d/monitorix start"
    stop program  = "/etc/init.d/monitorix stop"
  ' >> /etc/monit/conf.d/nems.conf
    /bin/systemctl restart monit
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

fi

if (( $(awk 'BEGIN {print ("'$branch'" == "'1.5'")}') )); then
  /usr/local/share/nems/nems-scripts/fixes15.sh
fi

if (( $(awk 'BEGIN {print ("'$ver'" >= "'1.5'")}') )); then

 # check_temper requires access to USB ports as non-root
 # Allow this every time (note this runs at every reboot)
  if [[ -e /dev/ttyUSB0 ]]; then
    chmod a+rw /dev/ttyUSB0
  fi
  if [[ -e /dev/ttyUSB1 ]]; then
    chmod a+rw /dev/ttyUSB1
  fi
  if [[ -e /dev/ttyUSB2 ]]; then
    chmod a+rw /dev/ttyUSB2
  fi
  if [[ -e /dev/ttyUSB3 ]]; then
    chmod a+rw /dev/ttyUSB3
  fi

  # Replace NEMS branding in Cockpit in case an update removes it
    /root/nems/nems-admin/build/171-cockpit
    /root/nems/nems-admin/build/999-cleanup

  # Mark filesystem as resized if greater than 9 GB, just in case the patch didn't get logged or is virtual appliance (etc)
    size=$(df --output=target,size /root | awk ' NR==2 { print $2 } ')
    if (( $size > 9000000 )); then
      # Log that patch (resize) has been applied to this system
      # Activates features such as bootscreen.sh
      if ! grep -q "PATCH-000002" /var/log/nems/patches.log; then
        echo "PATCH-000002" >> /var/log/nems/patches.log
      fi
    fi

fi

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
    /usr/local/bin/hw-detect
  fi

# Load ZRAM Swap at boot
  if [[ -e /etc/rc.local ]]; then
    if ! grep -q "NEMS0000" /etc/rc.local; then
      # fix comment so it doesn't get replaced
      /bin/sed -i -- 's,"exit 0",exit with errorcode 0,g' /etc/rc.local
      # add to boot process
      /bin/sed -i -- 's,exit 0,# Load Swap into ZRAM NEMS0000\n/usr/local/share/nems/nems-scripts/zram.sh > /dev/null 2>\&1\n\nexit 0,g' /etc/rc.local
      # run it now
      /usr/local/share/nems/nems-scripts/zram.sh # Do it now
    fi
  fi

# Final cleanup
/root/nems/nems-admin/build/999-cleanup

rm -f /var/run/nems-fixes.pid

# If a reboot is required, do it now
if [[ $reboot == 1 ]]; then
  /sbin/reboot
fi
