#!/bin/bash
ver=$(/usr/local/bin/nems-info nemsver)
veravail=$(/usr/local/bin/nems-info nemsveravail)

host=$(/bin/hostname)
users=$(/usr/local/bin/nems-info users)
cpupercent=$(/usr/local/bin/nems-info cpupercent)
diskusage=$(/usr/local/bin/nems-info diskusage)

online=$(/usr/local/bin/nems-info online)
  if [[ $online == 1 ]]; then
    internet="Online"
  elif [[ $online == 0 ]]; then
    internet="Offline"
  else
    internet="Unknown"
  fi

ip=$(/usr/local/bin/nems-info ip)

init=$(/usr/local/bin/nems-info init)

platform_name=$(/usr/local/bin/nems-info platform-name)

if [[ $init == "0" ]]; then
  output_init="Your NEMS server is not yet initialized. Please run: sudo nems-init"
fi

dialog --title "NEMS Linux $ver" --infobox "\
Platform:         $platform_name\n\
Hostname:         $host.local\n\
IP Address:       $ip\n\
CPU Usage:        $cpupercent%\n\
Disk Usage:       $diskusage%\n\
Active Sessions:  $users\n\
Internet Status:  $internet\n\
\n$output_init\n\
\n\
To login, use SSH or press CTRL-ALT-F2\n\
\n\
For help, visit: docs.nemslinux.com" 20 72
sleep 30
