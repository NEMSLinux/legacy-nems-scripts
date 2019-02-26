#!/bin/bash
# Enable or disable services on boot based on nems.conf

conf='/usr/local/share/nems/nems.conf'

platform=$(/usr/local/bin/nems-info platform) 
ver=$(/usr/local/bin/nems-info nemsver)


 # Set defaults if nothing is set

   # Pi Zero / 1
   if (( $platform < '2' )); then

     if ! grep -q "service.rpi-monitor" "$conf"; then
       echo "service.rpi-monitor=0" >> "$conf"
     fi

     if ! grep -q "service.nagios-api" "$conf"; then
       echo "service.nagios-api=0" >> "$conf"
     fi

     if ! grep -q "service.monitorix" "$conf"; then
       echo "service.monitorix=0" >> "$conf"
     fi

   fi


 # All Platforms

   socket=$(/usr/local/bin/nems-info socket)

   # nagios-api
   if grep -q "service.nagios-api=0" "$conf"; then
     sleep 1
   else
     sleep 15 # Need to wait a bit so Nagios has time to load first
     if (( $(awk 'BEGIN {print ("'$ver'" >= "'1.4'")}') )); then
       /root/nems/nagios-api/nagios-api -p 8090 -c $socket -s /var/cache/nagios/status.dat -l /var/log/nagios/nagios.log >> /var/log/nagios-api.log 2>&1 &
     else
       /root/nems/nagios-api/nagios-api -p 8090 -c /var/lib/nagios3/rw/live.sock -s /var/cache/nagios3/status.dat -l /var/log/nagios3/nagios.log >> /var/log/nagios-api.log 2>&1 &
     fi
   fi

   # monitorix
   if grep -q "service.monitorix=0" "$conf"; then
     /bin/systemctl stop monitorix
     /bin/systemctl disable monitorix
   else
     /bin/systemctl enable monitorix
     /bin/systemctl start monitorix
   fi


 # Raspberry Pi Only
 if (( $platform < '10' )); then

   # RPi-Monitor
   if grep -q "service.rpi-monitor=0" "$conf"; then
     sleep 30
     /etc/init.d/rpimonitor stop
     /bin/systemctl stop rpimonitor
   else
     /etc/init.d/rpimonitor start
   fi

 fi

