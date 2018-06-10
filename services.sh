#!/bin/bash
# Enable or disable services on boot based on nems.conf

conf='/usr/local/share/nems/nems.conf'

platform=$(/usr/local/bin/nems-info platform) 
ver=$(/usr/local/bin/nems-info nemsver)

 # Raspberry Pi Only
 if [[ $platform == 0 ]] || [[ $platform == 1 ]] || [[ $platform == 2 ]] || [[ $platform == 3 ]]; then

   # RPi-Monitor
   if grep -q "service.rpi-monitor=0" "$conf"; then
     /etc/init.d/rpimonitor stop
   else
     /etc/init.d/rpimonitor start
   fi

 fi

 # All Platforms

   # nagios-api
   if grep -q "service.nagios-api=0" "$conf"; then
     sleep 1
   else
     sleep 15 # Need to wait a bit so Nagios has time to load first
     if (( $(awk 'BEGIN {print ("'$ver'" >= "'1.4'")}') )); then
       /root/nems/nagios-api/nagios-api -p 8090 -c /var/lib/nagios3/rw/live.sock -s /var/cache/nagios/status.dat -l /var/log/nagios/nagios.log >> /var/log/nagios-api.log 2>&1 &
     else
       /root/nems/nagios-api/nagios-api -p 8090 -c /var/lib/nagios3/rw/live.sock -s /var/cache/nagios3/status.dat -l /var/log/nagios3/nagios.log >> /var/log/nagios-api.log 2>&1 &
     fi
   fi

   # webmin
   if grep -q "service.webmin=0" "$conf"; then
     systemctl stop webmin
     systemctl disable webmin
   else
     systemctl enable webmin
     systemctl start webmin
   fi

   # monitorix
   if grep -q "service.monitorix=0" "$conf"; then
     systemctl stop monitorix
     systemctl disable monitorix
   else
     systemctl enable monitorix
     systemctl start monitorix
   fi

   # cockpit
   if grep -q "service.cockpit=0" "$conf"; then
     systemctl stop cockpit.socket
     systemctl disable cockpit.socket
   else
     systemctl enable cockpit.socket
     systemctl start cockpit.socket
   fi
