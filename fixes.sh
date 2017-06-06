#!/bin/bash

# NEMS 1.2.1 was released with an incorrect permission on this file
chown www-data:www-data /etc/nagios3/global/timeperiods.cfg

# Fix Nagios Core access to admin features for user created with nems-init
if [ -f /var/www/htpasswd ]; then
  if grep -q nagiosadmin /etc/nagios3/cgi.cfg; then
    username=$(cut -f1 -d":" /var/www/htpasswd)
    cp -f /root/nems/nems-migrator/data/nagios/cgi.cfg /etc/nagios3/
    /bin/sed -i -- 's/nagiosadmin/'"$username"'/g' /etc/nagios3/cgi.cfg
  fi
fi
