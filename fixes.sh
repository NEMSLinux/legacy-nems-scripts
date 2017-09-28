#!/bin/bash

# No need to run this directly. Instead, run: sudo nems-update

# NEMS 1.2.1 was released with an incorrect permission on this file
chown www-data:www-data /etc/nagios3/global/timeperiods.cfg

# Check that NEMS has been initialized
if [ -f /var/www/htpasswd ]; then
  # Load the username from nems-init
  username=$(cut -f1 -d":" /var/www/htpasswd)

  # Fix Nagios Core access to admin features for user created with nems-init
  if grep -q nagiosadmin /etc/nagios3/cgi.cfg; then
    cp -f /root/nems/nems-migrator/data/nagios/cgi.cfg /etc/nagios3/
    /bin/sed -i -- 's/nagiosadmin/'"$username"'/g' /etc/nagios3/cgi.cfg
  fi

  # Fix Check_MK access to admin features for user created with nems-init
  if grep -q nagiosadmin /etc/check_mk/multisite.d/wato/users.mk; then
    cp -f /root/nems/nems-migrator/data/check_mk/users.mk /etc/check_mk/multisite.d/wato/users.mk
    /bin/sed -i -- 's/nagiosadmin/'"$username"'/g' /etc/check_mk/multisite.d/wato/users.mk
    chown www-data:www-data /etc/check_mk/multisite.d/wato/users.mk
  fi
fi

# Hide the help buttons in Nagios Core that lead to 404 error pages.
# The context specific help pages, if they exist, are just dumb placeholders anyways
# (guess nobody ever got to them in the Nagios3 development)
# ... so what's the point in showing them?
sed -i -e 's/show_context_help=1/show_context_help=0/g' /etc/nagios3/cgi.cfg

# Install nems-upgrade command if not already
if [ ! -f /usr/bin/nems-upgrade ]; then
  ln -s /home/pi/nems-scripts/upgrade.sh /usr/bin/nems-upgrade
fi

# Install nems-update command if not already
if [ ! -f /usr/bin/nems-update ]; then
  ln -s /home/pi/nems-scripts/update.sh /usr/bin/nems-update
fi

# Move NEMS version data into nems.conf
if [ -f /root/nems/ver.txt ]; then
  ver=$(cat /root/nems/ver.txt)
  echo platform=pi > /home/pi/nems.conf
  echo version=$ver >> /home/pi/nems.conf
  rm /root/nems/ver.txt
  if [ -f /var/www/html/inc/ver.txt ]; then
    rm /var/www/html/inc/ver.txt
  fi
fi

# Add new cron entries

  # Dump current crontab to tmp file
    crontab -l > /tmp/cron.tmp

  # Benchmark log
  if ! grep -q "NEMS0001" /tmp/cron.tmp; then
    printf "\n# Run a weekly system benchmark of the NEMS server to assist with troubleshooting NEMS0001\n0 3 * * 0 /home/pi/nems-scripts/benchmark.sh > /var/log/nems/benchmark.log\n" >> /tmp/cron.tmp
    cronupdate=1
  fi

  # NEMS Anonymous Stats
  if ! grep -q "NEMS0002" /tmp/cron.tmp; then
    printf "\n# NEMS Anonymous Stats NEMS0002\n0 0 * * * /home/pi/nems-scripts/stats.sh\n" >> /tmp/cron.tmp
    cronupdate=1
  fi

  if ! grep -q "NEMS0003" /tmp/cron.tmp; then
    printf "\n# Load Average Over One Week Logger NEMS0003\n*/15 * * * * /home/pi/nems-scripts/loadlogger.sh\n" >> /tmp/cron.tmp
    cronupdate=1
  fi

  if ! grep -q "NEMS0004" /tmp/cron.tmp; then
    printf "\n# Detect Hardware Model NEMS0004\n@reboot /home/pi/nems-scripts/hw_model.sh\n" >> /tmp/cron.tmp
    cronupdate=1
  fi

  if ! grep -q "NEMS0005" /tmp/cron.tmp; then
    printf "\n# Log Package Version Info NEMS0005\n0 5 * * 0 /home/pi/nems-scripts/versions.sh > /var/log/nems/package-versions.log\n" >> /tmp/cron.tmp
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
