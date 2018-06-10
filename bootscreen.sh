#!/bin/bash
ver=$(/usr/local/bin/nems-info nemsver)
veravail=$(/usr/local/bin/nems-info nemsveravail)

host=$(/bin/hostname)
users=$(/usr/local/bin/nems-info users)
cpupercent=$(/usr/local/bin/nems-info cpupercent)
diskusage=$(/usr/local/bin/nems-info diskusage)

ip=$(/usr/local/bin/nems-info ip)

init=$(/usr/local/bin/nems-info init)

if [[ $init == "0" ]]; then
  output_init="Your NEMS server is not yet initialized. Please run: sudo nems-init"
fi

dialog --title "NEMS Linux $ver" --infobox "\
Hostname:         $host.local\n\
IP Address:       $ip\n\
CPU Usage:        $cpupercent%\n\
Disk Usage:       $diskusage%\n\
Active Sessions:  $users\n\
\n$output_init\n\
\n\
To login, use SSH or press CTRL-ALT-F2\n\
\n\
For help, visit: docs.nemslinux.com" 15 72
sleep 30
