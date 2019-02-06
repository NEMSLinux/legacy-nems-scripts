#!/bin/bash
allowupdate=`/usr/local/bin/nems-info allowupdate`

quickfix=$(/usr/local/bin/nems-info quickfix)
if [[ $quickfix == 1 ]]; then
  echo 'Already running.'
  exit
fi
echo $$ > /var/run/nems-quickfix.pid

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
