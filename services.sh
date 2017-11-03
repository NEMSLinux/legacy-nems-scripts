#!/bin/bash
# Enable or disable services on boot based on nems.conf

# systemctl disable service

conf='/usr/local/share/nems/nems.conf'

 # RPi-Monitor
 if grep -q "service.rpi-monitor=0" "$conf"; then
   /etc/init.d/rpimonitor stop
 else
   /etc/init.d/rpimonitor start
 fi

 # nagios-api
 if grep -q "service.nagios-api=0" "$conf"; then
   sleep 1
 else
   sleep 15 # Need to wait a bit so Nagios has time to load first
   /root/nems/nagios-api/nagios-api -p 8090 -c /var/lib/nagios3/rw/live.sock -s /var/cache/nagios3/status.dat -l /var/log/nagios3/nagios.log >> /var/log/nagios-api.log 2>&1 &
 fi
