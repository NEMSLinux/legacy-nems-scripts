#!/bin/bash
allowupdate=`/usr/local/bin/nems-info allowupdate`
tmpdir=`mktemp -d -p /usr/local/share/`

PATCH=''
POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -r|--reset)
    PATCH="$2"
    shift # past argument
    shift # past value
    ;;
esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

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
  # remove decimal place
  suptime=${suptime%.*}
  while (( $suptime < 120 )); do
    echo "System is still loading. Please wait..."
    sleep 90
    suptime=$(awk '{print $1}' /proc/uptime)
    suptime=${suptime%.*}
  done

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
  if [[ ! $PATCH == "" ]]; then
    cp /var/log/nems/patches.log $tmpdir/
    /bin/sed -i "/${PATCH}/d" /var/log/nems/patches.log
    printf "Attempting to reset patch ${PATCH}... "
    if ! cmp /var/log/nems/patches.log $tmpdir/patches.log > /dev/null 2>&1
    then
      echo "Success."
    else
      echo "Failed."
    fi
  fi
  echo "It's really just a fancy name: this may take a while."
  echo "Do not stop this script once it is running."
  printf "Please wait patiently."

  # Make sure any lingering package installations get completed before continuing
  dpkg --configure -a > /dev/null 2>&1

  # Reset the log each time quickfix is run
  date > /var/log/nems/nems-quickfix.log

  for run in {1..2}
  do

    printf "."

    # Create a copy of the update script to run
    cp /usr/local/bin/nems-update $tmpdir/qf.sh

    # Run the copy
    $tmpdir/qf.sh >> /var/log/nems/nems-quickfix.log 2>&1

  done
  rm $tmpdir/qf.sh
  echo " Done."
else
  echo "Update Skipped based on settings in NEMS SST."
fi

# Run tasks which need to run daily
/usr/local/share/nems/nems-scripts/daily

rm -f /var/run/nems-quickfix.pid
