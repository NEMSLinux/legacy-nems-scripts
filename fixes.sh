#!/bin/bash

# No need to run this directly.
# Instead, run: sudo nems-update

 # Just in case apt is already doing stuff in the background, hang tight until it completes
 echo "Please wait for apt tasks to complete..."
 while fuser /var/{lib/{dpkg,apt/lists},cache/apt/archives}/lock >/dev/null 2>&1; do sleep 1; done
 echo "Done."

 # using hard file location rather than symlink as symlink may not exist yet on older versions
 platform=$(/usr/local/share/nems/nems-scripts/info.sh platform)
 ver=$(/usr/local/share/nems/nems-scripts/info.sh nemsver) 

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
  sed -i~ '/apikey/d' /usr/local/share/nems/nems.conf
fi

# Force hw_model - I never took into account some people might not reboot to trigger this.
if [ ! -f /var/log/nems/hw_model.log ]; then
  /usr/local/share/nems/nems-scripts/hw_model.sh
fi

# Randomize nemsadmin password if NEMS is initialized
# After nems-init you must first become root, then su nemsadmin to access nemsadmin
  if [ -d /home/nemsadmin ]; then # nemsadmin is missing, so do not proceed
    usercount=$(find /home/* -maxdepth 0 -type d | wc -l)
    if (( $usercount > 1)); then # Only do this if there are other users on the system
      rndpass=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w ${1:-32} | head -n 1)
      echo -e "$rndpass\n$rndpass" | passwd nemsadmin >/tmp/init 2>&1
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
