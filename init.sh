#!/bin/bash
# First run initialization script
# Run this script with: sudo nems-init
# It's already in the path via a symlink

# Perform any fixes that have been released since NEMS was built
/home/pi/nems-scripts/fixes.sh

echo ""
echo Welcome to NEMS initialization script.
echo ""
if [[ $EUID -ne 0 ]]; then
  echo "ERROR: This script must be run as root" 2>&1
  exit 1
else

  echo "First, let's change the password of the pi Linux user..."
  echo "REMEMBER: This will be the password you'll use for SSH/Local Login and Webmin."
  echo "If you do not want to change it, simply enter the existing password."
  while true; do
    read -s -p "New pi User Password: " pipassword
    echo
    read -s -p "New pi User Password (again): " pipassword2
    echo
    [ "$pipassword" = "raspberry" ] && pipassword="-" && echo "You are not allowed to use that password."
    [ "$pipassword" = "" ] && pipassword="-" && echo "You can't leave the password blank."
    [ "$pipassword" = "$pipassword2" ] && break
    echo "Please try again"
  done
  echo -e "$pipassword\n$pipassword" | passwd pi | grep passwd >/tmp/init 2>&1

  echo "Your new password has been set for the Linux pi user."
  echo "Use that password to access NEMS over SSH or when logging in to Webmin."
  echo ""
  echo "What username would you like to use when"
  read -p "logging in to the NEMS web interfaces? " username

  while true; do
    read -s -p "Password: " password
    echo
    read -s -p "Password (again): " password2
    echo
    [ "$password" = "raspberry" ] && password="-" && echo "You are not allowed to use that password."
    [ "$password" = "" ] && password="-" && echo "You can't leave the password blank."
    [ "$password" = "$password2" ] && break
    echo "Please try again"
  done

  # In case this is a re-initialization, clear the init file (remove old login), then add this user
  echo "">/var/www/htpasswd && echo $password | /usr/bin/htpasswd -c -i /var/www/htpasswd $username

echo Initializing new Nagios user
systemctl stop nagios3

# Reininitialize Nagios3 user account
  echo "define contactgroup {
                contactgroup_name                     admins
                alias                                 Nagios Administrators
                members                               $username
}
" > /etc/nagios3/global/contactgroups.cfg
  echo "define contact {
                contact_name                          $username
                alias                                 Nagios Admin
                host_notification_options             d,u,r,f,s
                service_notification_options          w,u,c,r,f,s
                email                                 nagios@localhost
                host_notification_period              24x7
                service_notification_period           24x7
                host_notification_commands            notify-host-by-email
                service_notification_commands         notify-service-by-email
}
" > /etc/nagios3/global/contacts.cfg

# Replace the database with Sample database
service mysql stop
rm -rf /var/lib/mysql/
cp -R /root/nems/nems-migrator/data/mysql/NEMS-Sample /var/lib
chown -R mysql:mysql /var/lib/NEMS-Sample
mv /var/lib/NEMS-Sample /var/lib/mysql
service mysql start

# Replace the Nagios3 cgi.cfg file with the sample and add username
cp -f /root/nems/nems-migrator/data/nagios/cgi.cfg /etc/nagios3/
/bin/sed -i -- 's/nagiosadmin/'"$username"'/g' /etc/nagios3/cgi.cfg

# Replace the Check_MK users.mk file with the sample and add username
cp -f /root/nems/nems-migrator/data/check_mk/users.mk /etc/check_mk/multisite.d/wato/users.mk
/bin/sed -i -- 's/nagiosadmin/'"$username"'/g' /etc/check_mk/multisite.d/wato/users.mk
chown www-data:www-data /etc/check_mk/multisite.d/wato/users.mk

# Remove nconf history, should it exist
mysql -u nconf -pnagiosadmin nconf -e "TRUNCATE History"

# Import new configuration into NConf
echo "  Importing: contact" && /var/www/nconf/bin/add_items_from_nagios.pl -c contact -f /etc/nagios3/global/contacts.cfg 2>&1 | grep -E "ERROR"
echo "  Importing: contactgroup" && /var/www/nconf/bin/add_items_from_nagios.pl -c contactgroup -f /etc/nagios3/global/contactgroups.cfg 2>&1 | grep -E "ERROR"
  
systemctl start nagios3

dpkg-reconfigure tzdata

  echo ""

  echo "Now we will resize your root partition to give you access to all the space"
  read -n 1 -s -p "Press any key to continue, or CTRL-C to abort"

  echo ""

  /usr/bin/raspi-config --expand-rootfs > /dev/null 2>&1
  echo "Done."

  echo ""
  read -n 1 -s -p "Press any key to reboot (required)"

  reboot

fi
