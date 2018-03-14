#!/bin/bash
ver=$(/usr/local/bin/nems-info nemsver)
host=$(/bin/hostname)
ip=$(/usr/local/bin/nems-info ip)
dialog --title "NEMS Linux $ver" --infobox "Hostname:   $host\nIP Address: $ip" 10 40
sleep 30
