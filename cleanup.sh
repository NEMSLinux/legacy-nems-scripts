#!/bin/bash
# Just a simple cleanup script so we don't leave
# a bunch of history behind at build-time

if [[ $EUID -ne 0 ]]; then
  echo "ERROR: This script must be run as root" 2>&1
  echo "Recommendation: Add script to crontab with @reboot" 2>&1
  exit 1
else

  sync

  touch /tmp/nems.freeze

  sudo apt-get clean
  sudo apt-get autoclean
  apt-get autoremove

  echo "Don't forget to remove the old kernels:"
  dpkg --get-selections | grep linux-image

  # Remove nconf history
  mysql -u nconf -pnagiosadmin nconf -e "TRUNCATE History"

  # Empty old logs
  find /var/log/ -type f -exec cp /dev/null {} \;
  find /var/log/ -iname "*.gz" -type f -delete
  find /var/log/ -iname "*.1" -type f -delete
  rm /var/log/nagios3/archives/*.log

  # Clear system mail
  find /var/mail/ -type f -exec cp /dev/null {} \;


  cd /root
  rm .nano_history
  rm .bash_history

  cd /home/pi
  rm .nano_history
  rm .bash_history

  rm /var/log/lastlog
  touch /var/log/lastlog

  # remove config backup from NEMS-Migrator
  rm /var/www/html/backup/backup.nems

  # remove output from nconf
  rm /var/www/nconf/output/*

  sync
  halt
fi
