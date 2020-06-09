#!/bin/bash
echo ""
echo "This script will set your router's IP for Multi Router Traffic Grapher (MRTG)."
echo "Doing this will reset all past data, so be sure you want to do this."
echo "See https://docs.nemslinux.com/usage/mrtg"
echo ""
echo "MAKE SURE SNMP IS ALREADY ENABLED ON YOUR ROUTER"
echo ""
read -p "What is your router's IP address? (CTRL-C to abort) " routerip
/usr/local/mrtg2/bin/cfgmaker --global 'WorkDir: /var/www/mrtg' --global 'Options[_]: bits,growright' --output /etc/mrtg/mrtg.cfg public@${routerip}
env LANG=C /usr/local/mrtg2/bin/mrtg /etc/mrtg/mrtg.cfg
echo ""
echo "Here are the generated links, which will automatically be updated every 5 minutes:"
find /var/www/mrtg/*.html  -printf " - https://nems.local/mrtg/%f\n"
echo ""
