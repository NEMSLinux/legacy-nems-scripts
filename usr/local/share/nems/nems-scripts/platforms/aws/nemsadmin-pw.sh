#!/bin/bash

if [ -d /home/nemsadmin ]; then # the nemsadmin user folder exists
  usercount=$(find /home/* -maxdepth 0 -type d | wc -l)

# AWS removes the nemsadmin password when the AMI is deployed. Reverse this action.
  if (( $usercount == 1)); then # Only do this if there are no other users on the system
    echo -e "nemsadmin\nnemsadmin" | passwd nemsadmin >/tmp/init 2>&1
  fi

# Add the key pair's public key to the nemsadmin user
  if (( $usercount == 1)); then
    key=$(curl -s http://169.254.169.254/latest/meta-data/public-keys/0/openssh-key)
    if [[ ! -e /home/nemsadmin/.ssh/authorized_keys ]]; then
      # Create a new file and place the public key there
      echo $key > /home/nemsadmin/.ssh/authorized_keys
    else
      # Append the public key to an existing file, if it doesn't already exist within it
      if ! grep -q "$key" /home/nemsadmin/.ssh/authorized_keys; then
        echo $key >> /home/nemsadmin/.ssh/authorized_keys
      fi
    fi
  fi

fi

