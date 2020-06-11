#!/bin/bash
echo ""
echo "This script will set your router's IP for Multi Router Traffic Grapher (MRTG)."
echo "Doing this will reset all past data, so be sure you want to do this."
echo "See https://docs.nemslinux.com/usage/mrtg"
echo ""
echo "MAKE SURE SNMP IS ALREADY ENABLED ON YOUR ROUTER"
echo ""
gateway=$(ip r | grep default | awk '{print $3}' | head -n 1)
routerip=""
if [[ ! $gateway == "" ]]; then
 read -r -p "I detected $gateway. Do you want to use that? [y/N] " detected
    echo ""
    if [[ $detected =~ ^([yY][eE][sS]|[yY])$ ]]; then
      echo "Using $gateway."
      routerip=$gateway
    fi
fi
if [[ $routerip == "" ]]; then
  read -p "What is your router's IP address? (CTRL-C to abort) " routerip
fi
if [[ $routerip == "" ]]; then
  echo
  echo "No IP provided for the router. Aborting."
  echo
  exit 1
fi
/usr/local/mrtg2/bin/cfgmaker --global 'WorkDir: /var/www/mrtg' --global 'Options[_]: bits,growright' --output /etc/mrtg/mrtg.cfg public@${routerip}
env LANG=C /usr/local/mrtg2/bin/mrtg /etc/mrtg/mrtg.cfg
echo ""
count=$(ls -1 /var/www/mrtg/*.html 2>/dev/null | wc -l)
if [ $count != 0 ]; then
  if [[ ! -L /etc/apache2/conf-enabled/mrtg.conf ]]; then
    echo "Enabling MRTG..."
    a2enconf mrtg > /dev/null 2>&1
    systemctl reload apache2
    echo
  fi
  echo "Here are the generated links, which will automatically be updated every 5 minutes:"
  find /var/www/mrtg/*.html  -printf " - https://nems.local/mrtg/%f\n"
else
  echo "*******************************************************************"
  echo -e "\e[1mNo data found.\e[0m"
  echo "Are you certain your router supports SNMP and you enabled it first?"
  echo "Are you sure you entered the correct IP address for the router?"
  echo "Nothing to detect."
  echo "*******************************************************************"
fi
echo ""
