#!/bin/bash
# NEMS Linux Migrator Off-Site Backup Restore
# By Robbie Ferguson
# nemslinux.com | baldnerd.com | category5.tv

# Load Config
hwid=`/usr/local/bin/nems-info hwid`
osbpass=$(cat /usr/local/share/nems/nems.conf | grep osbpass | printf '%s' $(cut -n -d '=' -f 2))
osbkey=$(cat /usr/local/share/nems/nems.conf | grep osbkey | printf '%s' $(cut -n -d '=' -f 2))
timestamp=$(/bin/date +%s)

if [[ $osbpass == '' ]] || [[ $osbkey == '' ]]; then
  echo NEMS Migrator Offsite Backup is not currently enabled.
  exit
fi;

if [ $(dpkg-query -W -f='${Status}' jq 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
  echo "JSON parser not yet installed. Installing."
  apt-get update
  apt-get install -y jq
fi

if [[ -f /tmp/osb.backup.nems ]]; then
  rm /tmp/osb.backup.nems
fi

# Cron triggers this at 4:30am
# Sleep for a random time up to 2 hours to stagger user backups to relieve stress on the API server
  if [[ $1 != 'now' ]]; then
    delay=$[ ( $RANDOM % 7200 ) ]
    echo "Waiting $delay seconds" >&2
    sleep ${delay}s
    echo "Running OSB" >&2
  else
    echo "Running OSB now" >&2
  fi

# Load Account Data (output options are json, serial or blank = :: separated, one item per line
  data=$(curl -s -F "hwid=$hwid" -F "osbkey=$osbkey" -F "output=json" https://nemslinux.com/api-backend/offsite-backup-checkin.php)

  if jq -e . >/dev/null 2>&1 <<<"$data"; then # Parse reply to make sure it is JSON before clobbering
    if [[ $data == '' ]]; then
      echo "[]" > /var/log/nems/nems-osb.json
    else
      echo "$data" > /var/log/nems/nems-osb.json
    fi
  else
    echo $data
  fi


