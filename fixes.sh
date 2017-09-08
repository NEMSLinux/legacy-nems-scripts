#!/bin/bash

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

# Disable Swap
  /sbin/dphys-swapfile swapoff

# Install hdparm required by nems-benchmark
if [ ! -f /sbin/hdparm ]; then
  apt-get update && apt-get -y install hdparm
fi

# Add nems-benchmark command
if [ ! -f /usr/bin/nems-benchmark ]; then
  ln -s /home/pi/nems-scripts/benchmark.sh /usr/bin/nems-benchmark
fi

# Add nems-mailtest command
if [ ! -f /usr/bin/nems-mailtest ]; then
  ln -s /home/pi/nems-scripts/mailtest.sh /usr/bin/nems-mailtest
fi

# Enable SSL support and load default certs if none exist
if [ ! -f /etc/apache2/mods-enabled/ssl.load ]; then
  a2enmod ssl
  mv /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/000-default.conf.bak
  if [ ! -f /var/www/certs/ca.pem ]; then
    # Load the default certs since none exist yet (which would be the case in NEMS 1.1 or 1.2)
    cp -R /root/nems/nems-migrator/data/certs /var/www/
  fi
  cp /home/pi/nems-scripts/upgrades/1.2.2/000-default.conf /etc/apache2/sites-available/
  systemctl restart apache2
fi
