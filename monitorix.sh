#!/bin/bash
# This script generates all the images for Monitorix via cronjob rather than on-demand, giving the perception of much faster processing and reducing load on page refresh
# It also ensures certain graphs (ie. Yearly) are not updated every time since the data won't be affected

/bin/sleep 15

if [[ $1 = "all" ]] || [[ $1 = "day" ]]; then /usr/bin/nice -n19 /usr/bin/w3m -dump "http://localhost:8080/monitorix-cgi/monitorix.cgi?mode=localhost&graph=all&when=1day&color=black" > /dev/null 2>&1; fi;
if [[ $1 = "all" ]] || [[ $1 = "week" ]]; then /usr/bin/nice -n19 /usr/bin/w3m -dump "http://localhost:8080/monitorix-cgi/monitorix.cgi?mode=localhost&graph=all&when=1week&color=black" > /dev/null 2>&1; fi;
if [[ $1 = "all" ]] || [[ $1 = "month" ]]; then /usr/bin/nice -n19 /usr/bin/w3m -dump "http://localhost:8080/monitorix-cgi/monitorix.cgi?mode=localhost&graph=all&when=1month&color=black" > /dev/null 2>&1; fi;
if [[ $1 = "all" ]] || [[ $1 = "year" ]]; then /usr/bin/nice -n19 /usr/bin/w3m -dump "http://localhost:8080/monitorix-cgi/monitorix.cgi?mode=localhost&graph=all&when=1year&color=black" > /dev/null 2>&1; fi;
