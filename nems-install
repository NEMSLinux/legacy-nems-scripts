#!/bin/bash

if [[ $EUID -ne 0 ]]; then
  echo "ERROR: This script must be run as root" 2>&1
  exit 1
fi

platform=$(/usr/local/bin/nems-info platform)

# Khadas VIM3 - install to eMMC
if (( $platform == 120 )) || (( $platform == 121 )); then
  /usr/local/share/nems/nems-scripts/installers/install-vim3.sh
  exit
fi

echo "There are no installers available for this platform."
echo ""
