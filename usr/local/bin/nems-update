#!/bin/bash

echo ""
echo "NEMS Update"
echo "By Robbie Ferguson"
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

  apt-get update

  git config --global --unset http.postBuffer

  echo "Updating NEMS Core Components"
  echo

  echo "nems-migrator ..."
  apt-get install -y nems-migrator
  # Get the latest version data from the NEMS API
  /usr/local/share/nems/nems-scripts/tasks.sh update platform
  echo

  echo "nems-scripts ... "
  apt-get install -y nems-scripts
  echo

  echo "nems-plugins ... "
  apt-get install -y nems-plugins
  echo

  echo "9590 ... "
  apt-get install -y 9590
  echo

  echo "hw-detect ... "
  apt-get install -y hw-detect
  echo

  echo "nems-www ... "
  apt-get install -y nems-www
  echo

# Don't do this yet; not ready
#  echo "speedtest ... "
#  apt-get install -y speedtest
#  echo

  echo "wmic ... "
  apt-get install -y wmic
  echo


  # Update nems-tv
  echo " - nems-tv... "
  cd /var/www/nems-tv
  git config --unset http.postBuffer
  commit=`git rev-parse HEAD`
  echo "   Commit: $commit"
  printf "   "
  result=`git pull`
  echo $result
  if [[ $result =~ 'error:' ]]; then
    echo 'Error detected. Reinstalling...';
    mv /var/www/nems-tv /var/www/nems-tv~
    cd /var/www
    git clone https://github.com/Cat5TV/nems-tv
    if [[ -d /var/www/nems-tv ]]; then
      chown -R www-data:www-data nems-tv
      echo 'Successfully reinstalled.'
      rm -rf /var/www/nems-tv~
    else
      echo 'Reinstall failed. Please copy your backup.nems file and re-image your device.'
      mv /var/www/nems-tv~ /var/www/nems-tv
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
  git config --unset http.postBuffer
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
  git config --unset http.postBuffer
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
    git config --unset http.postBuffer
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

  # Perform any fixes that have been released since NEMS was built
  printf "Running updates and fixes... "
  if [ -d /usr/local/share/nems/nems-scripts ]; then
    /usr/local/share/nems/nems-scripts/fixes.sh
  fi
  echo ""

fi
echo "Done."
echo ""

rm -f /var/run/nems-update.pid
