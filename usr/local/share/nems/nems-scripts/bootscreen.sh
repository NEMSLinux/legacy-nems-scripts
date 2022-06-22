#!/bin/bash

# Global variables
ver=$(/usr/local/bin/nems-info nemsver)
host=$(/bin/hostname)
# First load IP. May change, so is checked again during rotation.
ip=$(/usr/local/bin/nems-info ip)
alias=$(/usr/local/bin/nems-info alias)

# Should set screen resolution on each board
# See: https://linuxhint.com/set_screen_resolution_linux_kernel_boot/

# Don't allow TTY to go blank
/usr/bin/setterm -blank 0
# See the blank timout (seconds): cat /sys/module/kernel/parameters/consoleblank

display_screen() {
  if [[ $2 == 'warning' ]]; then
    conf=/usr/local/share/nems/nems-scripts/settings/dialog.warning
  else
    conf=/usr/local/share/nems/nems-scripts/settings/dialog.normal
  fi
  if [[ ! $alias == 'nems' ]]; then
    aliastitle=" ($alias)";
  else
    aliastitle="";
  fi
  env DIALOGRC=$conf dialog --backtitle "This NEMS Server: ${ip}${aliastitle}" --title "$1" \
    --no-collapse \
    --infobox "$output" 20 72
}

if [[ ! -e /var/log/nems/patches.log ]]; then
  touch /var/log/nems/patches.log
fi

while  ! grep -q "PATCH-000002" /var/log/nems/patches.log; do
  output="\n\nFilesystem is being resized.\n\nNEMS will reboot. Please standby..."
  display_screen "NEMS Linux $ver"
  sleep 10
done

# Loading screen
output="\n\nNEMS Linux is loading..."
display_screen "NEMS Linux $ver"
sleep 10

while :
do

alias=$(/usr/local/bin/nems-info alias)
veravail=$(/usr/local/bin/nems-info nemsveravail)
users=$(/usr/local/bin/nems-info users)
cpupercent=$(/usr/local/bin/nems-info cpupercent)
diskusage=$(/usr/local/bin/nems-info diskusage)
temperatureC=$(/usr/local/bin/nems-info temperature)
# There's no way a CPU with a reported temp would be 0, so assume unknown
if (( ${temperatureC%.*} == 0 )); then
  temperatureF=0;
  temps=''
else
  temperatureF=$(echo "scale=1;((9/5) * $temperatureC) + 32" |bc)
  temps="\nCPU Temperature:  $temperatureF°F / $temperatureC°C"
fi

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

if (( $(echo "$veravail > $ver" |bc -l) )); then
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
CPU Usage:        $(LC_ALL=C /usr/bin/printf '%.*f\n' 1 $cpupercent)% $temps\n\
Disk Usage:       $(LC_ALL=C /usr/bin/printf '%.*f\n' 1 $diskusage)%\n\
Active Sessions:  $users\n\
Internet Status:  $internet\n\
\n$output_init\n\
\n\
To login, use SSH or press CTRL-ALT-F2\n\
\n\
For help, visit: docs.nemslinux.com"
display_screen "NEMS Server Overview"

sleep 10

hosts=$(/usr/local/bin/nems-info hosts)
services=$(/usr/local/bin/nems-info services)
update=$(/usr/local/bin/nems-info update)
fixes=$(/usr/local/bin/nems-info fixes)

if [[ $update == 1 ]]; then
  timertmp=$(/usr/local/bin/nems-info fileage /var/run/nems-update.pid)
  updating="Running ($timertmp)"
else
  updating="Idle"
fi

if [[ $fixes == 1 ]]; then
  timertmp=$(/usr/local/bin/nems-info fileage /var/run/nems-fixes.pid)
  fixing="Running ($timertmp)"
else
  fixing="Idle"
fi

# General overview
output="\
Hosts:            $hosts\n\
Services:         $services\n\
NEMS Update:      $updating\n\
NEMS Fixes:       $fixing\n\
"
display_screen "NEMS Linux $ver"

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

