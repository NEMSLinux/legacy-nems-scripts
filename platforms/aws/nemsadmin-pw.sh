#!/bin/bash

# AWS removes the nemsadmin password when the AMI is deployed. Reverse this action.

if [ -d /home/nemsadmin ]; then # the nemsadmin user folder exists
  usercount=$(find /home/* -maxdepth 0 -type d | wc -l)
  if (( $usercount == 1)); then # Only do this if there are no other users on the system
    echo -e "nemsadmin\nnemsadmin" | passwd nemsadmin >/tmp/init 2>&1
  fi
fi
