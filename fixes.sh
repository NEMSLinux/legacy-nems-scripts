#!/bin/bash

# No need to run this directly. Instead, run: sudo nems-update

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
apikey=$(cat /usr/local/share/nems/nems.conf | grep test | printf '%s' $(cut -n -d '=' -f 2))
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
if grep -q "/home/pi/nems-scripts/info.sh" /etc/rpimonitor/template/version.conf; then
  systemctl stop rpimonitor
  /bin/sed -i -- 's,/home/pi/nems-scripts/info.sh,/usr/local/bin/nems-info,g' /etc/rpimonitor/template/version.conf
  systemctl stop rpimonitor
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
