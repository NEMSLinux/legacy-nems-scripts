#!/bin/bash
# Just a simple cleanup script so we don't leave
# a bunch of history behind at build-time

if [[ $EUID -ne 0 ]]; then
  echo "ERROR: This script must be run as root" 2>&1
  exit 1
else
  
  if [[ $1 != "halt" ]]; then echo "Pass the halt option to halt after execution or the reboot option to reboot."; echo ""; fi;
  
  sync
  
  # Stop services which may be using these files
  systemctl stop webmin
  systemctl stop rpimonitor
  systemctl stop monitorix
  systemctl stop apache2
  systemctl stop nagios3
  
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
  find /var/log/ -iname "*.log.*" -type f -delete
  rm /var/log/nagios3/archives/*.log

  # Clear system mail
  find /var/mail/ -type f -exec cp /dev/null {} \;

  # Remove Webmin logs and sessions
  rm /var/webmin/webmin.log
  rm /var/webmin/miniserv.log
  rm /var/webmin/miniserv.error
  rm /var/webmin/sessiondb.pag
  
  # Clear RPi-Monitor history and stats
  rm /usr/share/rpimonitor/web/stat/*.rrd
  
  # Clear Monitorix history and stats
  rm /var/lib/monitorix/*.rrd
  :>/var/log/monitorix-httpd
  
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

  # Remove DNS Resolver config (will be auto-generated on first boot)
  rm  /etc/resolv.conf

  # remove output from nconf
  rm /var/www/nconf/output/*

  sync
  
  if [[ $1 == "halt" ]]; then echo "Halting..."; halt; exit; fi;

  if [[ $1 == "reboot" ]]; then echo "Rebooting..."; reboot; exit; fi;

  # System still running: Restart services
  service networking restart
  systemctl start webmin
  systemctl start rpimonitor
  systemctl start monitorix
  systemctl start apache2
  systemctl start nagios3
  
fi
