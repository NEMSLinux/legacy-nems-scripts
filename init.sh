#!/bin/bash
# First run initialization script
# Run this script with: sudo nems-init
# It's already in the path via a symlink

echo ""
echo Welcome to NEMS initialization script.
echo ""
if [[ $EUID -ne 0 ]]; then
  echo "ERROR: This script must be run as root" 2>&1
  exit 1
else

  echo "First, let's change the password of the pi Linux user..."
  passwd pi

  echo ""
  read -p "What username would you like to use when logging in to the NEMS web interfaces? " username

  while true; do
    read -s -p "Password: " password
    echo
    read -s -p "Password (again): " password2
    echo
    [ "$password" = "$password2" ] && break
    echo "Please try again (didn't match)"
  done

  echo $password | /usr/bin/htpasswd -c -i /var/www/htpasswd $username

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

# Import to NConf database
/var/www/nconf/bin/add_items_from_nagios.pl -c contact -f /etc/nagios3/global/contacts.cfg -x 1

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
