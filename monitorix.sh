#!/bin/bash
/bin/sleep 15

if [[ $1 = "all" ]] || [[ $1 = "day" ]]; then /usr/bin/nice -n19 /usr/bin/w3m -dump "http://localhost:8080/monitorix-cgi/monitorix.cgi?mode=localhost&graph=all&when=1day&color=black" > /dev/null 2>&1; fi;
if [[ $1 = "all" ]] || [[ $1 = "week" ]]; then /usr/bin/nice -n19 /usr/bin/w3m -dump "http://localhost:8080/monitorix-cgi/monitorix.cgi?mode=localhost&graph=all&when=1week&color=black" > /dev/null 2>&1; fi;
if [[ $1 = "all" ]] || [[ $1 = "month" ]]; then /usr/bin/nice -n19 /usr/bin/w3m -dump "http://localhost:8080/monitorix-cgi/monitorix.cgi?mode=localhost&graph=all&when=1month&color=black" > /dev/null 2>&1; fi;
if [[ $1 = "all" ]] || [[ $1 = "year" ]]; then /usr/bin/nice -n19 /usr/bin/w3m -dump "http://localhost:8080/monitorix-cgi/monitorix.cgi?mode=localhost&graph=all&when=1year&color=black" > /dev/null 2>&1; fi;
