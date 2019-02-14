#!/bin/bash

echo ""
echo "NEMS Update"
echo ""

if [[ $EUID -ne 0 ]]; then
  echo "ERROR: This script must be run as root" 2>&1
  exit 1
else
  online=$(/usr/local/bin/nems-info online)
  if [[ $online == 0 ]]; then
    echo "*** NEMS cannot detect your Internet connection. Please make sure you are online. ***"
  fi

  # Just in case nems-quickfix is running
  update=$(/usr/local/bin/nems-info update)
  if [[ $update == 1 ]]; then
    echo 'NEMS Linux is currently updating itself. Please wait...'
    while [[ $update == 1 ]]
    do
      sleep 1
      update=$(/usr/local/bin/nems-info update)
    done
  fi
  echo $$ > /var/run/nems-update.pid

  # Don't do updates if fixes is running, since that is a sub-process of update and could conflict
  fixes=$(/usr/local/bin/nems-info fixes)
  if [[ $fixes == 1 ]]; then
    echo 'NEMS Linux is currently updating itself. Please wait...'
    while [[ $fixes == 1 ]]
    do
      sleep 1
      update=$(/usr/local/bin/nems-info fixes)
    done
  fi

  echo "Updating NEMS Core Components"

  # Update nems-migrator
  echo " - nems-migrator"
  cd /root/nems/nems-migrator
  commit=`git rev-parse HEAD`
  echo "   Commit: $commit"
  printf "   "
  result=`git pull`
  echo $result
  if [[ $result =~ 'error:' ]]; then
    echo 'Error detected. Reinstalling...';
    mv /root/nems/nems-migrator /root/nems/nems-migrator~
    cd /root/nems
    git clone https://github.com/Cat5TV/nems-migrator
    if [[ -d /root/nems/nems-migrator ]]; then
      echo 'Successfully reinstalled.'
      rm -rf /root/nems/nems-migrator~
    else
      echo 'Reinstall failed. Please copy your backup.nems file and re-image your device.'
      mv /root/nems/nems-migrator~ /root/nems/nems-migrator
    fi
  fi
  commitnew=`git rev-parse HEAD`
  if [[ $commit == $commitnew ]]; then
    echo "   No changes."
  else
    echo "   New Commit: $commit"
  fi
  # Get the latest version data from nems-migrator
  cp -f /root/nems/nems-migrator/data/nems/ver-current.txt /var/www/html/inc/ver-available.txt

  # Update nems-www
  echo " - nems-www... "
  cd /var/www/html
  commit=`git rev-parse HEAD`
  echo "   Commit: $commit"
  printf "   "
  result=`git pull`
  echo $result
  if [[ $result =~ 'error:' ]]; then
    echo 'Error detected. Reinstalling...';
    mv /var/www/html /var/www/nems-www~
    cd /var/www
    git clone https://github.com/Cat5TV/nems-www
    if [[ -d /var/www/nems-www ]]; then
      mv nems-www html
      chown -R www-data:www-data html
      echo 'Successfully reinstalled.'
      rm -rf /var/www/nems-www~
    else
      echo 'Reinstall failed. Please copy your backup.nems file and re-image your device.'
      mv /var/www/nems-www~ /var/www/html
    fi
  fi
  commitnew=`git rev-parse HEAD`
  if [[ $commit == $commitnew ]]; then
    echo "   No changes."
  else
    echo "   New Commit: $commit"
  fi

  # Update nems-admin
  echo " - nems-admin... "
  cd /root/nems/nems-admin
  commit=`git rev-parse HEAD`
  echo "   Commit: $commit"
  printf "   "
  result=`git pull`
  echo $result
  if [[ $result =~ 'error:' ]]; then
    echo 'Error detected. Reinstalling...';
    mv /root/nems/nems-admin /root/nems/nems-admin~
    cd /root/nems
    git clone https://github.com/Cat5TV/nems-admin
    if [[ -d /root/nems/nems-admin ]]; then
      echo 'Successfully reinstalled.'
      rm -rf /root/nems/nems-admin~
    else
      echo 'Reinstall failed. Please copy your backup.nems file and re-image your device.'
      mv /root/nems/nems-admin~ /root/nems/nems-admin
    fi
  fi
  commitnew=`git rev-parse HEAD`
  if [[ $commit == $commitnew ]]; then
    echo "   No changes."
  else
    echo "   New Commit: $commit"
  fi

  # Update nems-nconf
  echo " - nconf... "
  cd /var/www/nconf
  commit=`git rev-parse HEAD`
  echo "   Commit: $commit"
  printf "   "
  result=`git pull`
  echo $result
  if [[ $result =~ 'error:' ]]; then
    echo 'Error detected. Reinstalling...';
    mv /var/www/nconf /var/www/nconf~
    cd /var/www
    git clone https://github.com/Cat5TV/nconf
    if [[ -d /var/www/nconf ]]; then
      echo 'Successfully reinstalled.'
      rm -rf /var/www/nconf~
    else
      echo 'Reinstall failed. Please copy your backup.nems file and re-image your device.'
      mv /var/www/nconf~ /var/www/nconf
    fi
  fi
  commitnew=`git rev-parse HEAD`
  if [[ $commit == $commitnew ]]; then
    echo "   No changes."
  else
    echo "   New Commit: $commit"
  fi

  # Update nems-tools
  echo " - nems-tools... "
  if [[ -d /root/nems/nems-tools ]]; then
    cd /root/nems/nems-tools
    commit=`git rev-parse HEAD`
    echo "   Commit: $commit"
    printf "   "
    result=`git pull`
    echo $result
    if [[ $result =~ 'error:' ]]; then
      echo 'Error detected. Reinstalling...';
      mv /root/nems/nems-tools /root/nems/nems-tools~
      cd /root/nems
      git clone https://github.com/Cat5TV/nems-tools
      if [[ -d /root/nems/nems-tools ]]; then
        echo 'Successfully reinstalled.'
        rm -rf /root/nems/nems-tools~
      else
        echo 'Reinstall failed. Please copy your backup.nems file and re-image your device.'
        mv /root/nems/nems-tools~ /root/nems/nems-tools
      fi
    fi
  else
    echo "nems-tools is not installed."
    cd /root/nems
    git clone https://github.com/Cat5TV/nems-tools
    echo 'Installed nems-tools.'
  fi
  commitnew=`git rev-parse HEAD`
  if [[ $commit == $commitnew ]]; then
    echo "   No changes."
  else
    echo "   New Commit: $commit"
  fi

  # Update self
  echo " - nems-scripts... "
  if [ -d /usr/local/share/nems/nems-scripts ]; then
    cd /usr/local/share/nems/nems-scripts
    commit=`git rev-parse HEAD`
    echo "   Commit: $commit"
    printf "   "
    result=`git pull`
    echo $result
    if [[ $result =~ 'error:' ]]; then
      echo 'Error detected. Reinstalling...';
      mv /usr/local/share/nems/nems-scripts /usr/local/share/nems/nems-scripts~
      cd /usr/local/share/nems
      git clone https://github.com/Cat5TV/nems-scripts
      if [[ -d /usr/local/share/nems ]]; then
        echo 'Successfully reinstalled.'
        rm -rf /usr/local/share/nems/nems-scripts~
      else
        echo 'Reinstall failed. Please copy your backup.nems file and re-image your device.'
        mv /usr/local/share/nems/nems-scripts~ /usr/local/share/nems/nems-scripts
      fi
    fi
  fi
  commitnew=`git rev-parse HEAD`
  if [[ $commit == $commitnew ]]; then
    echo "   No changes."
  else
    echo "   New Commit: $commit"
  fi

  # Check if we are still on legacy 1.1 or 1.2.x and update that way, otherwise fixes will not run to patch it
  if [ -d /home/pi/nems-scripts ]; then
    echo "*** You need to upgrade your NEMS server to a current version! ***"
    cd /home/pi/nems-scripts && git pull
  fi
  echo ""

  # Perform any fixes that have been released since NEMS was built
  printf "Running updates and fixes... "
  if [ -d /usr/local/share/nems/nems-scripts ]; then
    /usr/local/share/nems/nems-scripts/fixes.sh
  fi
  # Legacy support
  if [ -d /home/pi/nems-scripts ]; then
    /home/pi/nems-scripts/fixes.sh
  fi
  echo ""

fi
echo "Done."
echo ""

rm -f /var/run/nems-update.pid
