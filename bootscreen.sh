#!/bin/bash

# Global variables
ver=$(/usr/local/bin/nems-info nemsver)
host=$(/bin/hostname)

display_screen() {
  if [[ $2 == 'warning' ]]; then
    conf=/usr/local/share/nems/nems-scripts/settings/dialog.warning
  else
    conf=/usr/local/share/nems/nems-scripts/settings/dialog.normal
  fi
  env DIALOGRC=$conf dialog --title "$1" \
    --no-collapse \
    --infobox "$output" 20 72
}

# Loading screen
output="Loading..."
display_screen "NEMS Linux $ver"


while :
do

alias=$(/usr/local/bin/nems-info alias)
veravail=$(/usr/local/bin/nems-info nemsveravail)
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

if (( $ver < $veravail )); then
  current="- $veravail is Available."
else
  current=""
fi
output="\
NEMS Version:     $ver $current\n\
Server Alias:     $alias\n\
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
For help, visit: docs.nemslinux.com"
display_screen "NEMS Server Overview"

sleep 10

# NEMS Warning Light Current State Screen
  if [[ -e /var/log/nems/nems-tools/currentstate ]]; then
    output=$(cat /var/log/nems/nems-tools/currentstate)
    if [[ $output == *"CRITICAL"* ]]; then
      conf="warning"
      timer=45
    else
      conf="normal"
      timer=10
    fi
    display_screen "NEMS Current State" $conf
    sleep $timer
  fi

done
