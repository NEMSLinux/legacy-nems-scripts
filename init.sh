#!/bin/bash
# First run initialization script
# Run this script with: sudo nems-init
# It's already in the path via a symlink

ver=$(cat "/var/www/html/inc/ver.txt") 

echo ""
echo Welcome to NEMS initialization script.
echo ""
if [[ $EUID -ne 0 ]]; then
  echo "ERROR: This script must be run as root" 2>&1
  exit 1
else

  # Perform any fixes that have been released since NEMS was built
  /home/pi/nems-scripts/fixes.sh

  echo "First, let's change the password of the pi Linux user..."
  echo "REMEMBER: This will be the password you'll use for SSH/Local Login and Webmin."
  echo "If you do not want to change it, simply enter the existing password."
  while true; do
    read -s -p "New Password for pi user: " pipassword
    echo
    read -s -p "New Password for pi user (again): " pipassword2
    echo
    [ "$pipassword" = "raspberry" ] && pipassword="-" && echo "You are not allowed to use that password."
    [ "$pipassword" = "" ] && pipassword="-" && echo "You can't leave the password blank."
    [ "$pipassword" = "$pipassword2" ] && break
    echo "Please try again"
  done
  echo -e "$pipassword\n$pipassword" | passwd pi >/tmp/init 2>&1

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
  echo "">/var/www/htpasswd && echo $password | /usr/bin/htpasswd -B -c -i /var/www/htpasswd $username

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

# Localization

  # Configure timezone
  dpkg-reconfigure tzdata

  # Forcibly restart cron to prevent tasks running at wrong times after timezone update
  service cron stop && service cron start

  # Configure the keyboard locale
  dpkg-reconfigure keyboard-configuration && service keyboard-setup restart

# /Localization

# Setup SSL Certificates
if [[ $ver = "1.3" ]]; then
  mkdir /tmp/certs
  cd /tmp/certs

  echo ""
  echo "Now, let's generate your SSL Certificates..."
  echo "DO NOT LEAVE ANYTHING BLANK - If you do, the certs will fail."
  echo ""
  echo "Fill in the following:"
  country=$(/home/pi/nems-scripts/country.sh)

  read -p "Country Code: " -i "$country" -e country
  read -p "Province/State: " province
  read -p "Your City: " city
  read -p "Company Name or Your Name: " company
  read -p "Unique Name For NEMS Server: " cn
  read -p "Your email address: " email

  echo "[req]
  prompt = no
  distinguished_name = req_distinguished_name
  req_extensions = v3_req

  [req_distinguished_name]
  C = $country
  ST = $province
  L = $city
  O = $company
  CN = $cn
  emailAddress = $email

  [v3_req]
  basicConstraints = CA:FALSE
  keyUsage = nonRepudiation, digitalSignature, keyEncipherment
  subjectAltName = @alt_names

  [alt_names]
  DNS.1 = nems.local
  DNS.2 = nems" > /tmp/certs/config.txt

  # Create CA private key
  /usr/bin/openssl genrsa 2048 > ca-key.pem

  # Create CA cert based on private key
  /usr/bin/openssl req -sha256 -new -x509 -config /tmp/certs/config.txt -nodes -days 3650 \
          -key ca-key.pem -out ca.pem

  # Create server certificate, remove passphrase, and sign it
  # server-cert.pem = public key, server-key.pem = private key
  /usr/bin/openssl req -sha256 -newkey rsa:2048 -config /tmp/certs/config.txt -days 3650 \
          -nodes -keyout server-key.pem -out server-req.pem

  /usr/bin/openssl rsa -in server-key.pem -out server-key.pem

  /usr/bin/openssl x509 -req -in server-req.pem -days 3600 \
          -CA ca.pem -CAkey ca-key.pem -set_serial 01 -out server-cert.pem

  # Create client certificate, remove passphrase, and sign it
  # client-cert.pem = public key, client-key.pem = private key
  /usr/bin/openssl req -sha256 -newkey rsa:2048 -config /tmp/certs/config.txt -days 3600 \
          -nodes -keyout client-key.pem -out client-req.pem

  /usr/bin/openssl rsa -in client-key.pem -out client-key.pem

  /usr/bin/openssl x509 -req -in client-req.pem -days 3600 \
          -CA ca.pem -CAkey ca-key.pem -set_serial 01 -out client-cert.pem

  rm /tmp/certs/config.txt
  
  echo "Done:"
  
  /usr/bin/openssl verify /tmp/certs/ca.pem
  echo ""
  rm -rf /var/www/certs/
  mv /tmp/certs /var/www/
  chown -R root:root /var/www/certs

fi

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
