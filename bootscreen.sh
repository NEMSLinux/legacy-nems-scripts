#!/bin/bash
ver=$(/usr/local/bin/nems-info nemsver)
host=$(/bin/hostname)
users=$(/usr/local/bin/nems-info users)
cpupercent=$(/usr/local/bin/nems-info cpupercent)
diskusage=$(/usr/local/bin/nems-info diskusage)

ip=$(/usr/local/bin/nems-info ip)
dialog --title "NEMS Linux $ver" --infobox "\
Hostname:         $host.local\n\
IP Address:       $ip\n\
CPU Usage:        $cpupercent%\n\
Disk Usage:       $diskusage%\n\
Active Sessions:  $users\n\
" 10 40
sleep 30
