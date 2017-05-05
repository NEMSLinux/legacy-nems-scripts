#!/bin/bash
sleep 15
/usr/bin/nice -n19 /usr/bin/w3m -dump "http://localhost:8080/monitorix-cgi/monitorix.cgi?mode=localhost&graph=all&when=1day&color=black" > /dev/null 2>&1
/usr/bin/nice -n19 /usr/bin/w3m -dump "http://localhost:8080/monitorix-cgi/monitorix.cgi?mode=localhost&graph=all&when=1week&color=black" > /dev/null 2>&1
/usr/bin/nice -n19 /usr/bin/w3m -dump "http://localhost:8080/monitorix-cgi/monitorix.cgi?mode=localhost&graph=all&when=1month&color=black" > /dev/null 2>&1
/usr/bin/nice -n19 /usr/bin/w3m -dump "http://localhost:8080/monitorix-cgi/monitorix.cgi?mode=localhost&graph=all&when=1year&color=black" > /dev/null 2>&1
