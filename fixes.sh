#!/bin/bash

# No need to run this directly. Instead, run: sudo nems-update

platform=$(/usr/local/share/nems/nems-scripts/info.sh platform)

# NEMS 1.2.1 was released with an incorrect permission on this file
chown www-data:www-data /etc/nagios3/global/timeperiods.cfg

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
    cp -f /root/nems/nems-migrator/data/nagios/conf/cgi.cfg /etc/nagios3/
    /bin/sed -i -- 's/nagiosadmin/'"$username"'/g' /etc/nagios3/cgi.cfg
  fi

  # Fix cgi.cfg username (I had pushed out a version where it was set to "robbie")
  if ! grep -q "robbie" /etc/cgi.cfg; then
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

# Move NEMS version data into nems.conf
if [ -f /root/nems/ver.txt ]; then
  ver=$(cat /root/nems/ver.txt)
  echo version=$ver >> /usr/local/share/nems/nems.conf
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

  # Import revised crontab
  if [[ "$cronupdate" == "1" ]]
  then
    crontab /tmp/cron.tmp
  fi

  # Remove temp file
  rm /tmp/cron.tmp

# /Add new cron entries

# Prepare legacy NEMS for 1.3+ compatibility
if [ ! -d /var/www/html/backup/snapshot ]; then
  mkdir -p /var/www/html/backup/snapshot
fi

# Update apt Lists
apt update

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

# Remove apikey if it is not set (eg., did not get a response from the server)
apikey=$(cat /usr/local/share/nems/nems.conf | grep apikey | printf '%s' $(cut -n -d '=' -f 2))
if [[ $apikey == '' ]]; then
  sed -i~ '/apikey/d' /usr/local/share/nems/nems.conf
fi

# Remove the platform designation from conf file (this was moved to hw_model.sh)
sed -i '/platform/d' /usr/local/share/nems/nems.conf

# Force hw_model - I never took into account some people might not reboot to trigger this.
if [ ! -f /var/log/nems/hw_model.log ]; then
  /usr/local/share/nems/nems-scripts/hw_model.sh
fi

# Fix paths on rpimonitor
if (( $platform >= 0 )) && (( $platform <= 9 )); then
  if grep -q "/home/pi/nems-scripts/info.sh" /etc/rpimonitor/template/version.conf; then
    systemctl stop rpimonitor
    /bin/sed -i -- 's,/home/pi/nems-scripts/info.sh,/usr/local/bin/nems-info,g' /etc/rpimonitor/template/version.conf
    systemctl start rpimonitor
  fi
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

# / end of move to snakeoil certs

# Load ZRAM Swap at boot
  if ! grep -q "NEMS0000" /etc/rc.local; then
    # fix comment so it doesn't get replaced
    /bin/sed -i -- 's,"exit 0",exit with errorcode 0,g' /etc/rc.local
    # add to boot process
    /bin/sed -i -- 's,exit 0,# Load Swap into ZRAM NEMS0000\n/usr/local/share/nems/nems-scripts/zram.sh > /dev/null 2>\&1\n\nexit 0,g' /etc/rc.local
    # run it now
    /usr/local/share/nems/nems-scripts/zram.sh # Do it now
  fi

# Make NEMS 1.1-1.3 compatible with NEMS 1.4+ configuration locations
  if [[ ! -d /etc/nems ]]; then
    mkdir -p /etc/nems/conf
    ln -s /etc/nagios3/import /etc/nems/conf/import
    ln -s /etc/nagios3/global /etc/nems/conf/global
    ln -s /etc/nagios3/Default_collector /etc/nems/conf/Default_collector
  fi

