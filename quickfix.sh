#!/bin/bash
allowupdate=`/usr/local/bin/nems-info allowupdate`

  # Just in case nems-quickfix is running
  quickfix=$(/usr/local/bin/nems-info quickfix)
  if [[ $quickfix == 1 ]]; then
    echo 'NEMS Linux is currently updating itself. Please wait...'
    while [[ $quickfix == 1 ]]
    do
      sleep 1
      quickfix=$(/usr/local/bin/nems-info quickfix)
    done
  fi
  echo $$ > /var/run/nems-quickfix.pid

  # Wait for 90 seconds if system just booted
  suptime=$(awk '{print $1}' /proc/uptime)
  suptime=${suptime%.*}
  while (( $suptime < 120 )); do
    echo "System is still loading. Please wait..."
    sleep 90
  done

  if [[ -f /var/www/nconf/temp/generate.lock ]]; then
    printf "Resetting NEMS NConf generate.lock..."
    rm -f /var/www/nconf/temp/generate.lock
    sleep 1
    echo " done."
  fi

  printf "Setting Internet speedtest server..."
  # Detect current first since this will create the conf if missing
  speedtestcurrent=`/usr/local/bin/nems-info speedtest`
  # Detect the best server
  speedtestbest=`/usr/local/bin/nems-info speedtest best`
  # Overwrite the conf
  if (( $speedtestcurrent != $speedtestbest )); then
    if (( $speedtestbest > 0 )); then
      /bin/sed -i~ '/speedtestserver/d' /usr/local/share/nems/nems.conf
      echo "speedtestserver=$speedtestbest" >> /usr/local/share/nems/nems.conf
      echo " done."
    else
      echo " couldn't detect server."
    fi
  else
    echo " no change."
  fi


# 1 = Not allowed
# 2 = Allowed monthly
# 3 = Allowed semi-weekly
# 4 = Allowed weekly
# 5 = Allowed daily (always)

if [[ -f /var/log/nems/nems-update.last ]]; then
  lastdate=`cat /var/log/nems/nems-update.last`
else
  lastdate=1
fi
thisdate=$(date '+%s')
dayssincelast=$(( ( $thisdate - $lastdate )/(60*60*24) ))

proceed=0
if [[ $allowupdate == 5 ]]; then
  proceed=1
elif [[ $allowupdate == 4 ]]; then
  if [[ $dayssincelast > 6 ]]; then
    proceed=1
  fi
elif [[ $allowupdate == 3 ]]; then
  if [[ $dayssincelast > 13 ]]; then
    proceed=1
  fi
elif [[ $allowupdate == 2 ]]; then
  if [[ $dayssincelast > 29 ]]; then
    proceed=1
  fi
fi

if [[ $proceed == 1 ]]; then
  echo $thisdate > /var/log/nems/nems-update.last
  echo "Performing NEMS QuickFix..."
  echo "It's really just a fancy name: this may take a while."
  echo "Do not stop this script once it is running."
  printf "Please wait patiently."

  for run in {1..2}
  do

    printf "."

    # Create a copy of the update script to run
    cp /usr/local/share/nems/nems-scripts/update.sh /tmp/qf.sh

    # Run the copy
    /tmp/qf.sh > /dev/null 2>&1

  done
  rm /tmp/qf.sh
  echo " Done."
else
  echo "Update Skipped based on settings in NEMS SST."
fi

rm -f /var/run/nems-quickfix.pid
