#!/bin/bash
# First run initialization script
# Run this script with: sudo nems-init
# It's already in the path via a symlink
ver=$(/usr/local/share/nems/nems-scripts/info.sh nemsver)
platform=$(/usr/local/share/nems/nems-scripts/info.sh platform)
init=$(/usr/local/share/nems/nems-scripts/info.sh init)
tmpdir=`mktemp -d -p /usr/local/share/`
olduser=$(/usr/local/bin/nems-info username)

  # Just in case nems-quickfix is running
  quickfix=$(/usr/local/bin/nems-info quickfix)
  if [[ $quickfix == 1 ]]; then
    echo 'NEMS Linux is currently updating itself. Please wait...'
    while [[ $quickfix == 1 ]]
    do
      sleep 1
      quickfix=$(/usr/local/bin/nems-info quickfix)
    done
  fi

if (( $(awk 'BEGIN {print ("'$ver'" >= "'1.4'")}') )); then
  confbase=/etc/nems/conf/
  nagios=nagios
else
  confbase=/etc/nagios3/
  nagios=nagios3
fi

echo ""
echo -e "\e[1mWelcome to the NEMS Linux initialization script.\e[0m"
echo ""
echo This quick questionaire will setup your account.
if [[ $EUID -ne 0 ]]; then
  echo "ERROR: This script must be run as root" 2>&1
  exit 1
else

  # Ensure user changed their MAC address.
  # DO NOT continue if you have not! Using the stock MAC means
  # you'd have the same HWID as other users! That, as you can imagine
  # can cause all kinds of problems, including security issues.
  if [[ $platform == 20 ]]; then
    hwid=$(/usr/local/bin/nems-info hwid)
    # Bad HWID for MAC 080027C75EC1 (Development HWID for VM)
    if [[ $hwid == *'4f6c6d8a4d2670e87004329b99bf517d'* ]] || [[ $hwid == *'d41d8cd98f00b204e9800998ecf8427e'* ]]; then
      echo "You need to initialize a unique MAC address for your"
      echo "virtual Network Interface. Shut down your NEMS appliance"
      echo "and modify the Network Interface in your hypervisor."
      echo ""
      wget -q -O $tmpdir/mac https://nemslinux.com/api/mac
      mac=`cat $tmpdir/mac`
      echo "Here is a MAC address you can use in your VM Config: $mac"
      echo ""
      echo "CANNOT CONTINUE"
      echo ""
      exit 1
    fi
  fi
  # Also bad for HWID d41d8cd98f00b204e9800998ecf8427e (NULL Response)
    hwid=$(/usr/local/bin/nems-info hwid)
    if [[ $hwid == *'4f6c6d8a4d2670e87004329b99bf517d'* ]] || [[ $hwid == *'d41d8cd98f00b204e9800998ecf8427e'* ]]; then
      echo "Invalid hardware ID for this NEMS server."
      printf "Please report this error: "
      four=$(echo $hwid | cut -c1-4)
      echo ${platform}-${four}-init
      echo ""
      echo "CANNOT CONTINUE"
      echo ""
      exit 1
    fi

  online=$(/usr/local/share/nems/nems-scripts/info.sh online)
  if [[ $online == 0 ]]; then
    echo "I am not able to connect with Github."
    echo "MAKE SURE your system clock is set correctly."
    date
    echo ""
    echo "This could also be due to a lack of Internet connectivity, or a firewall issue."
    echo "We'll proceed with initialization, however please note you need to fix this."
    echo "NEMS updates come in via Github, and these patches ensure everything works well."
    echo "Please resolve this issue, and confirm by pinging github.com from your NEMS server."
    echo ""
    sleep 5
  fi

  if [[ -d /home/pi ]]; then
    # Must continue to support NEMS 1.1 and 1.2.x
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
    echo -e "$pipassword\n$pipassword" | passwd pi >$tmpdir/init 2>&1

    echo "Your new password has been set for the Linux pi user."
    echo "Use that password to access NEMS over SSH or when logging in to Webmin."
  fi

  if [[ $init = 1 ]]; then
    echo ""
    echo -e "\e[93m*** \e[91mWARNING \e[93m***\e[0m"
    echo "Your NEMS server is already initialized!"
    echo "If you proceed, all settings will be lost."
    echo "If you wish to keep your settings, please"
    echo "make a copy of your backup.nems file first,"
    echo "initialize, and then run nems-restore."
    echo ""
    read -r -p "Do you want to wipe your config and re-initialize? [y/N] " beta
    echo ""
    if [[ $beta =~ ^([yY][eE][sS]|[yY])$ ]]; then
      echo "Proceeding..."
    else
      echo "Aborted."
      exit 1
    fi
  fi

# Localization
  echo -e "\e[2m"

  # Configure timezone
  dpkg-reconfigure tzdata

  # Configure locale
  dpkg-reconfigure locales

  # Configure the keyboard locale (will be skipped if keyboard is not connected)
  dpkg-reconfigure keyboard-configuration && service keyboard-setup restart

# /Localization

  echo -e "\e[0m"
  isValidUsername() {
    local re='^[[:lower:]_][[:lower:][:digit:]_-]{2,15}$'
    (( ${#1} > 16 )) && return 1
    [[ $1 =~ $re ]]
  }
  containsElement () {
    local e match="$1"
    shift
    for e; do [[ "$e" == "$match" ]] && return 0; done
    return 1
  }
  badnames=("nemsadmin" "nagios" "nems" "root" "user" "config" "pi" "admin" "robbie" "nagiosadmin" "www-data" "${olduser}")
  while true; do
  read -p "What would you like your NEMS Username to be? " username
    if [[ ${username,,} == $username ]]; then
      if isValidUsername "$username"; then
        if containsElement "$username" "${badnames[@]}"; then
          if [[ $username == ${olduser} ]]; then
            echo Username is not allowed: already exists. Please try again.
          else
            echo Username is not allowed. Please try again.
          fi
          username=""
        else
          echo Username accepted.
          echo ""
          break
        fi
      else
        echo Username is invalid. Please try again.
      fi
    else 
      echo Username must be all lowercase. Please try again.
    fi
  done

  while true; do
    read -s -p "Password: " password
    echo
    read -s -p "Password (again): " password2
    echo
    [ "$password" = "nemsadmin" ] && password="-" && echo "You are not allowed to use that password."
    [ "$password" = "raspberry" ] && password="-" && echo "You are not allowed to use that password."
    [ "$password" = "" ] && password="-" && echo "You can't leave the password blank."
    [ "$password" = "$password2" ] && break
    echo "Please try again"
  done

  echo ""
  read -p "What email address should I send notifications to? " email

  echo ""

  # In case this is a re-initialization, clear the init file (remove old login), then add this user
  echo "">/var/www/htpasswd && echo $password | /usr/bin/htpasswd -B -c -i /var/www/htpasswd $username

  # Create the Linux user
  adduser --disabled-password --gecos "" $username
  # Giving you files
  # Transfer user files from old user to new user, especially since AWS SSH keys would break if we didn't do this and someone re-initialized a NEMS Server
  printf "Moving all files in /home/${olduser} to /home/$username... "
  rsync -rtv /home/${olduser}/ /home/${username}/ > /dev/null 2>&1
  chown -R ${username}:${username} /home/${username}/
  echo Done.



  # User groups #
    # Allow user to become super-user
    usermod -aG sudo $username
    # Allow them to also administer nagios, access livestatus, etc.
    usermod -aG www-data,nagios $username
    # Allow user to access GPIO without root access (where applicable)
    usermod -aG gpio $username
    # Allow user to control network connections
    usermod -aG netdev $username
    # Allow user to login to monit web interface
    [ $(getent group monit) ] || groupadd monit
    usermod -aG monit $username
  ###############

  # Set the user password
  echo -e "$password\n$password" | passwd $username >$tmpdir/init 2>&1

  # Reset the RPi-Monitor user
  cp /root/nems/nems-migrator/data/rpimonitor/daemon.conf /etc/rpimonitor

  # Configure RPi-Monitor to run as the new user
  if [[ -f /etc/rpimonitor/daemon.conf ]]; then
    /bin/sed -i -- 's/nemsadmin/'"$username"'/g' /etc/rpimonitor/daemon.conf
  fi

  # Samba config
    # Create Samba User
    echo -e "$password\n$password" | smbpasswd -s -a $username
    # Reset Samba users
    cp /root/nems/nems-migrator/data/samba/smb.conf /etc/samba
    # Configure new samba user
    /bin/sed -i -- 's/nemsadmin/'"$username"'/g' /etc/samba/smb.conf
    systemctl restart smbd

echo Initializing new Nagios user
systemctl stop $nagios

# Import default Nagios configs for NEMS 1.4+
if (( $(awk 'BEGIN {print ("'$ver'" >= "'1.4'")}') )); then
  rm -rf $confbase
  mkdir -p $confbase
  if (( $(awk 'BEGIN {print ("'$ver'" >= "'1.6'")}') )); then
    cp -R /root/nems/nems-migrator/data/1.6/nagios/conf/* $confbase
  elif (( $(awk 'BEGIN {print ("'$ver'" >= "'1.5'")}') )); then
    cp -R /root/nems/nems-migrator/data/1.5/nagios/conf/* $confbase
  elif (( $(awk 'BEGIN {print ("'$ver'" >= "'1.4'")}') )); then
    cp -R /root/nems/nems-migrator/data/1.4/nagios/conf/* $confbase
  fi
  okconfig="okconfig"
  if [[ ! -d $confbase$okconfig ]]; then
    mkdir $confbase$okconfig
  fi
  chown -R www-data:www-data $confbase
fi

# Reininitialize Nagios user account
  echo "define contactgroup {
                contactgroup_name                     admins
                alias                                 Nagios Administrators
                members                               $username
}
" > $confbase/global/contactgroups.cfg
  echo "define contact {
                contact_name                          $username
                alias                                 Nagios Admin
                host_notification_options             d,u,r,f,s
                service_notification_options          w,u,c,r,f,s
                email                                 $email
                host_notification_period              24x7
                service_notification_period           24x7
                host_notification_commands            notify-host-by-email
                service_notification_commands         notify-service-by-email
}
" > $confbase/global/contacts.cfg

# Replace the database with Sample database
systemctl stop mysql
# Force kill MySQL (in case safe mode prevents shutdown, as is the case on Docker)
  sleep 3
  mysqldpid=$(pidof mysqld)
  if [[ $mysqldpid != "" ]]; then
    kill -9 $mysqldpid
    sleep 1
  fi
  systemctl stop mysql

mv /var/lib/mysql /var/lib/mysql~
rm -rf /var/lib/mysql~

if (( $(awk 'BEGIN {print ("'$ver'" >= "'1.6'")}') )); then
  cp -R /root/nems/nems-migrator/data/1.6/mysql/NEMS-Sample /var/lib
elif (( $(awk 'BEGIN {print ("'$ver'" >= "'1.5'")}') )); then
  cp -R /root/nems/nems-migrator/data/1.5/mysql/NEMS-Sample /var/lib
elif (( $(awk 'BEGIN {print ("'$ver'" >= "'1.4'")}') )); then
  cp -R /root/nems/nems-migrator/data/1.4/mysql/NEMS-Sample /var/lib
else
  cp -R /root/nems/nems-migrator/data/mysql/NEMS-Sample /var/lib
fi
mv /var/lib/NEMS-Sample /var/lib/mysql
chown -R mysql:mysql /var/lib/mysql
# Force kill MySQL (in case safe mode prevents shutdown, as is the case on Docker)
  sleep 3
  mysqldpid=$(pidof mysqld)
  if [[ $mysqldpid != "" ]]; then
    kill -9 $mysqldpid
    sleep 1
  fi
  systemctl stop mysql

systemctl start mysql

# Replace the Nagios cgi.cfg file with the sample and add username
if (( $(awk 'BEGIN {print ("'$ver'" >= "'1.5'")}') )); then
  cp -fr /root/nems/nems-migrator/data/1.5/nagios/etc/* /usr/local/nagios/etc/
  /bin/sed -i -- 's/nemsadmin/'"$username"'/g' /usr/local/nagios/etc/cgi.cfg
elif (( $(awk 'BEGIN {print ("'$ver'" >= "'1.4'")}') )); then
  cp -fr /root/nems/nems-migrator/data/1.4/nagios/etc/* /usr/local/nagios/etc/
  /bin/sed -i -- 's/nemsadmin/'"$username"'/g' /usr/local/nagios/etc/cgi.cfg
else
  cp -f /root/nems/nems-migrator/data/nagios/conf/cgi.cfg /etc/nagios/
  /bin/sed -i -- 's/nemsadmin/'"$username"'/g' /etc/nagios/cgi.cfg
fi

# Replace the Check_MK users.mk file with the sample and add username
if [[ -d /etc/check_mk ]]; then # Removed in NEMS 1.4+
  cp -f /root/nems/nems-migrator/data/check_mk/users.mk /etc/check_mk/multisite.d/wato/users.mk
  /bin/sed -i -- 's/nagiosadmin/'"$username"'/g' /etc/check_mk/multisite.d/wato/users.mk
  chown www-data:www-data /etc/check_mk/multisite.d/wato/users.mk
fi

# Remove nconf history, should it exist
mysql -u nconf -pnagiosadmin nconf -e "TRUNCATE History"

# Import new configuration into NConf
if (( $(awk 'BEGIN {print ("'$ver'" >= "'1.5'")}') )); then
  # Update user info (no need to import in 1.5
  echo "  Updating contact: $username"
  mysql -t -u nconf -pnagiosadmin nconf -e "UPDATE ConfigValues SET attr_value='$username' WHERE fk_id_attr=47;"
  mysql -t -u nconf -pnagiosadmin nconf -e "UPDATE ConfigValues SET attr_value='$email' WHERE fk_id_attr=55;"
else
  echo "  Importing: contact" && /var/www/nconf/bin/add_items_from_nagios.pl -c contact -f $confbase/global/contacts.cfg 2>&1 | grep -E "ERROR|WARN"
  echo "  Importing: contactgroup" && /var/www/nconf/bin/add_items_from_nagios.pl -c contactgroup -f $confbase/global/contactgroups.cfg 2>&1 | grep -E "ERROR|WARN"
fi

systemctl start $nagios

  # Forcibly restart cron to prevent tasks running at wrong times after timezone update
  service cron stop && service cron start

if (( $(awk 'BEGIN {print ("'$ver'" >= "'1.3'")}') )); then

  # Configure NagVis user
  if (( $(awk 'BEGIN {print ("'$ver'" >= "'1.4'")}') )); then
    cp -f /root/nems/nems-migrator/data/1.4/nagvis/auth.db /etc/nagvis/etc/
  else
    cp -f /root/nems/nems-migrator/data/nagvis/auth.db /etc/nagvis/etc/
  fi
  chown www-data:www-data /etc/nagvis/etc/auth.db
  # Note, this is being added as specifically userId 1 as this user is users2role 1, administrator
  # NagVis hashes its SHA1 passwords with the long string, which is duplicated in the nagvis ini file - /etc/nagvis/etc/nagvis.ini.php
  sqlite3 /etc/nagvis/etc/auth.db "INSERT INTO users (userId,name,password) VALUES (1,'$username','$(echo -n '29d58ead6a65f5c00342ae03cdc6d26565e20954'$password | sha1sum | awk '{print $1}')');"


  # Create new SSL and SSH Certificates
  /usr/local/bin/nems-cert

fi

  echo ""

# Generate nems.conf file
  echo "version=$ver" > /usr/local/share/nems/nems.conf
  echo "nemsuser=$username" >> /usr/local/share/nems/nems.conf
  # If it's low-end hardware, disable all extraneous daemons by default
  if \
   (( $platform == 0 )) || \
   (( $platform == 1 )) || \
   (( $platform == 2 )); then
     echo "\
service.nagios-api=0
service.webmin=0
service.monitorix=0
service.cockpit=0
service.rpi-monitor=0
" >> /usr/local/share/nems/nems.conf
  fi

    reboot=0

  # Only do this for anything LESS THAN 1.5 (that is to say, 1.4.1, etc).
  if (( $(awk 'BEGIN {print ("'$ver'" < "'1.5'")}') )); then
    # Raspberry Pi
    if (( $platform >= 0 )) && (( $platform <= 9 )); then
      /usr/bin/raspi-config --expand-rootfs > /dev/null 2>&1
      reboot=1
    fi
  echo "Done."
  fi

  if [[ $platform == 22 ]]; then
    echo Configuring Amazon Web Services default user
      /bin/sed -i -- 's/nemsadmin/'"$username"'/g' /etc/cloud/cloud.cfg
      # Amazon Web Services uses a key pair instead of password
      if [[ -e /home/nemsadmin/.ssh/authorized_keys ]]; then
        if [[ ! -e /home/$username/.ssh ]]; then
          mkdir -p /home/$username/.ssh
        fi
        mv /home/nemsadmin/.ssh/authorized_keys /home/$username/.ssh/
        chown $username:$username /home/$username/.ssh/authorized_keys
      fi
    echo Done.
  fi

  # Disable old admin account
  if [[ -d /home/$username ]] && [[ -d /home/${olduser} ]]; then
    # old user will be deleted automatically via cron now that you're initialized, but this stuff is just to protect users in case for some reason the nemsuser user remains.
    echo "Disabling ${olduser} access. Remember you must now login as ${username}"
    # Cockpit will die here. So warn users they need to reboot
    echo "You may lose connection now."
    printf "Please reconnect as $username"
    if [[ $reboot == 1 ]]; then
      echo " and reboot your NEMS server."
    fi
    echo ""
    deluser ${olduser} sudo # Remove super user access from nemsadmin account
    deluser ${olduser} netdev # Remove network device access from nemsadmin account
    rndpass=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w ${1:-32} | head -n 1)
    echo -e "$rndpass\n$rndpass" | passwd ${olduser} >$tmpdir/init 2>&1 # set a random password on the account so no longer can login
  fi

  echo ""
  if [[ $reboot == 1 ]]; then
    echo "Now we will resize your root partition to give you access to all the space"
    echo ""
    echo "*** YOUR NEMS SERVER WILL REBOOT NOW ***"
    echo ""
    echo "****************************************************"
    echo "NOTICE: When you reboot, you must login as $username"
    echo "****************************************************"
    echo ""
    echo "After rebooting, visit https://$(/usr/local/bin/nems-info ip)/ to get started."
    echo ""
    reboot
  else
    echo "You can now visit https://$(/usr/local/bin/nems-info ip)/ to get started."
    echo ""
    echo "Enjoy NEMS Linux!"
    echo ""
  fi

fi
