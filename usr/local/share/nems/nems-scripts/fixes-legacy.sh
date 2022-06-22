#!/bin/bash
echo "Running legacy fixes... you may want to consider upgrading your NEMS version."

 # using hard file location rather than symlink as symlink may not exist yet on older versions
 platform=$(/usr/local/share/nems/nems-scripts/info.sh platform)
 ver=$(/usr/local/share/nems/nems-scripts/info.sh nemsver) 

# NEMS 1.2.1 was released with an incorrect permission on this file
if [[ $ver = "1.2.1" ]]; then
  chown www-data:www-data /etc/nagios3/global/timeperiods.cfg
fi

# Prepare the 1.2.x->1.3.x transition to move away from /home/pi folder
  # Will create this folder now to avoid errors
  if [ ! -d /usr/local/share/nems ]; then
    mkdir -p /usr/local/share/nems
  fi

  if [ -d /home/pi/nems-scripts ]; then
    # Make old NEMS 1.1 + 1.2.x compatible with 1.3 file locations
    # Use a symlink instead of trying to move it when a script within it is running.
    if [ ! -d "/usr/local/share/nems/nems-scripts" ]; then # don't proceed if this is already a directory
      if [ ! -f "/usr/local/share/nems/nems-scripts" ]; then # only proceed if there's no file
        ln -s /home/pi/nems-scripts /usr/local/share/nems/nems-scripts # Create the symlink to /home/pi/nems-scripts - it's the opposite of NEMS 1.3+ but effective and safer
      fi
    fi
  fi

# Check that NEMS has been initialized
if [ -f /var/www/htpasswd ]; then
  # Load the username from nems-init
  username=$(cut -f1 -d":" /var/www/htpasswd)

  # Fix Nagios Core access to admin features for user created with nems-init
  if grep -q nagiosadmin /etc/nagios3/cgi.cfg; then
    cat /root/nems/nems-migrator/data/nagios/conf/cgi.cfg > $(/bin/readlink -f "/etc/nagios3/cgi.cfg") # Doing this way to be compatible with 1.4+ (symlink)
    /bin/sed -i -- 's/nagiosadmin/'"$username"'/g' /etc/nagios3/cgi.cfg
  fi

  # Fix cgi.cfg username (I had pushed out a version where it was set to "robbie")
  if ! grep -q "robbie" /etc/nagios3/cgi.cfg; then
    /bin/sed -i -- 's/robbie/'"$username"'/g' /etc/nagios3/cgi.cfg
  fi

  # Fix Check_MK access to admin features for user created with nems-init
  if grep -q nagiosadmin /etc/check_mk/multisite.d/wato/users.mk; then
    cp -f /root/nems/nems-migrator/data/check_mk/users.mk /etc/check_mk/multisite.d/wato/users.mk
    /bin/sed -i -- 's/nagiosadmin/'"$username"'/g' /etc/check_mk/multisite.d/wato/users.mk
    chown www-data:www-data /etc/check_mk/multisite.d/wato/users.mk
  fi

  # Fix log location for already deployed NEMS misccommands
  if grep -q sendmail /etc/nagios3/global/misccommands.cfg; then
    /bin/sed -i -- 's/sendmail/sendemail/g' /etc/nagios3/global/misccommands.cfg
  fi


fi

# Fix cgi.cfg path to nagios3 icons
if grep -q "/var/www/html/shared/nagios3" /etc/nagios3/cgi.cfg; then
  /bin/sed -i -- 's\/var/www/html/shared/nagios3\/var/www/html/share/nagios3\g' /etc/nagios3/cgi.cfg
fi


# Hide the help buttons in Nagios Core that lead to 404 error pages.
# The context specific help pages, if they exist, are just dumb placeholders anyways
# (guess nobody ever got to them in the Nagios3 development)
# ... so what's the point in showing them?
sed -i -e 's/show_context_help=1/show_context_help=0/g' /etc/nagios3/cgi.cfg

# Move already created symlinks from /usr/bin to /usr/local/bin
if [ -f /usr/bin/nems-init ]; then
  mv /usr/bin/nems-* /usr/local/bin/
  sed -i -e 's/\/usr\/bin\/nems/\/usr\/local\/bin\/nems/g' /etc/motd.tcl
fi

# Move NEMS version data into nems.conf
if [ -f /root/nems/ver.txt ]; then
  ver=$(cat /root/nems/ver.txt)
  echo version=$ver >> /usr/local/share/nems/nems.conf
  rm /root/nems/ver.txt
  if [ -f /var/www/html/inc/ver.txt ]; then
    rm /var/www/html/inc/ver.txt
  fi
fi


# Prepare legacy NEMS for 1.3+ compatibility
if [ ! -d /var/www/html/backup/snapshot ]; then
  mkdir -p /var/www/html/backup/snapshot
fi

# Install PHP-RRD (used by nems-info to read Monitorix data)...
if [ $(dpkg-query -W -f='${Status}' php-rrd 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
  apt-get -y install php-rrd
fi

# Install dialog (make nems command line prompts pretty)
if [ $(dpkg-query -W -f='${Status}' dialog 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
  apt-get -y install dialog
fi

# Install netcat (used by nems-info checkport)
if [ $(dpkg-query -W -f='${Status}' netcat 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
  apt -y install netcat
fi


# Patch Against KRACK WPA2 Exploit
if [ ! -f /var/log/nems/wpasupplicant ]; then
  apt install wpasupplicant
  # Simple prevention of doing this every time fixes.sh runs
  echo "Patched" > /var/log/nems/wpasupplicant
fi

# Move nems.conf out of /home/pi (NEMS 1.2.x)
if [ -f /home/pi/nems.conf ]; then
  mv /home/pi/nems.conf /usr/local/share/nems/
fi

# Remove the platform designation from conf file (this was moved to hw_model.sh)
sed -i '/platform/d' /usr/local/share/nems/nems.conf

# Fix paths on rpimonitor
if (( $platform >= 0 )) && (( $platform <= 9 )); then
  if grep -q "/home/pi/nems-scripts/info.sh" /etc/rpimonitor/template/version.conf; then
    systemctl stop rpimonitor
    /bin/sed -i -- 's,/home/pi/nems-scripts/info.sh,/usr/local/bin/nems-info,g' /etc/rpimonitor/template/version.conf
    systemctl start rpimonitor
  fi
fi

# Fix ownership of NEMS SST
  chown -R www-data:www-data /var/www/html/config

# Password protect /phpmyadmin - found users putting their NEMS servers online with this conf enabled... Yikes!
# This adds security to this software since only the NEMS user can now use it.
if [[ -f /etc/apache2/conf-available/phpmyadmin.conf ]]; then
  if ! grep -q "NEMS Protected Access" /etc/apache2/conf-available/phpmyadmin.conf; then
    /bin/sed -i -- 's,DirectoryIndex index.php,DirectoryIndex index.php\n    AuthName "NEMS Protected Access"\n    AuthType Basic\n    AuthUserFile /var/www/htpasswd\n    <RequireAll>\n      Require all granted\n      Require valid-user\n    </RequireAll>,g' /etc/apache2/conf-available/phpmyadmin.conf
    systemctl restart apache2
  fi
fi

# Fix SSL certificate issue on Windows clients
# Use Debian Snakeoil instead of nems-cert
  # Backup old config
  if [[ ! -f /etc/apache2/sites-available/000-default.conf~ ]]; then
    cp /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/000-default.conf~
  fi
  if [[ ! -f /etc/webmin/miniserv.conf~ ]]; then
    cp /etc/webmin/miniserv.conf /etc/webmin/miniserv.conf~
  fi

  regen=0
  # Patch Apache2
  # Comment out the CA
  if grep -q "  SSLCertificateChainFile /var/www/certs/ca.pem" /etc/apache2/sites-available/000-default.conf; then
    /bin/sed -i -- 's,SSLCertificateChainFile,# SSLCertificateChainFile,g' /etc/apache2/sites-available/000-default.conf
    regen=1
  fi
  # Change the cert files
  if grep -q "/var/www/certs/server-cert.pem" /etc/apache2/sites-available/000-default.conf; then
    /bin/sed -i -- 's,/var/www/certs/server-cert.pem,/etc/ssl/certs/ssl-cert-snakeoil.pem,g' /etc/apache2/sites-available/000-default.conf
    regen=1
  fi
  if grep -q "/var/www/certs/server-key.pem" /etc/apache2/sites-available/000-default.conf; then
    /bin/sed -i -- 's,/var/www/certs/server-key.pem,/etc/ssl/private/ssl-cert-snakeoil.key,g' /etc/apache2/sites-available/000-default.conf
    regen=1
  fi

  # Patch Webmin
  if grep -q "/var/www/certs/combined.pem" /etc/webmin/miniserv.conf; then
    /bin/sed -i -- 's,/var/www/certs/combined.pem,/etc/ssl/certs/ssl-cert-snakeoil-combined.pem,g' /etc/webmin/miniserv.conf
    regen=1
  fi

  if [[ $regen == 1 ]]; then
    # Generating new Snakeoil cert
    /usr/local/share/nems/nems-scripts/gen-cert.sh

    #Restart Apache2
    /bin/systemctl restart apache2

    # Restart Webmin
    /bin/systemctl restart webmin
  fi

  # When we moved to snakeoil certs, we did not also point Monit to these new certs, so it broke. Fix it (NEMS 1.1-1.3.x)
  # Fix permissions for monit to use the cert (max 700)
  chmod 600 /etc/ssl/certs/ssl-cert-snakeoil-combined.pem
  if grep -q "/var/www/certs/combined.pem" /etc/monit/conf.d/nems.conf; then
    /bin/sed -i -- 's,/var/www/certs/combined.pem,/etc/ssl/certs/ssl-cert-snakeoil-combined.pem,g' /etc/monit/conf.d/nems.conf
    # not regenerating script this time since this is a future fix
    systemctl restart monit
  fi

# / end of move to snakeoil certs

# Make NEMS 1.1-1.3 compatible with NEMS 1.4+ configuration locations
  if [[ ! -d /etc/nems ]]; then
    mkdir -p /etc/nems/conf
    ln -s /etc/nagios3/import /etc/nems/conf/import
    ln -s /etc/nagios3/global /etc/nems/conf/global
    ln -s /etc/nagios3/Default_collector /etc/nems/conf/Default_collector
  fi

# Replace ntpd with htpdate - fixes crashing when server cannot be reached
#  if [[ $ver = "1.3.1" ]]; then
#    apt -y remove --purge --auto-remove ntp
#    apt -y install htpdate
#  fi

