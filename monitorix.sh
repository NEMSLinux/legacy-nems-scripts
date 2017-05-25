#!/bin/bash
# This script generates all the images for Monitorix via cronjob rather than on-demand, giving the perception of much faster processing and reducing load on page refresh
# It also ensures certain graphs (ie. Yearly) are not updated every time since the data won't be affected

/bin/sleep 15

# Detect the default network interface and use it for net graphs
adapter=`/sbin/route | /bin/grep '^default' | /bin/grep -o '[^ ]*$'`
/bin/cat <<EOF > /tmp/monitorix.nems
<net>
        list = $adapter
        <desc>
                $adapter = Network on $adapter, 0, 10000000
        </desc>
        gateway = $adapter
</net>
EOF
if [ ! -f /etc/monitorix/conf.d/nems.conf ]; then
    touch /etc/monitorix/conf.d/nems.conf
fi
/usr/bin/diff /tmp/monitorix.nems /etc/monitorix/conf.d/nems.conf
  if [ $? == 1 ]; then
      /bin/cat /tmp/monitorix.nems > /etc/monitorix/conf.d/nems.conf
      /bin/systemctl restart monitorix
  fi;
rm /tmp/monitorix.nems

# Generate the graphs
if [[ $1 = "all" ]] || [[ $1 = "day" ]]; then /usr/bin/nice -n19 /usr/bin/w3m -dump "http://localhost:8080/monitorix-cgi/monitorix.cgi?mode=localhost&graph=all&when=1day&color=black" > /dev/null 2>&1; fi;
if [[ $1 = "all" ]] || [[ $1 = "week" ]]; then /usr/bin/nice -n19 /usr/bin/w3m -dump "http://localhost:8080/monitorix-cgi/monitorix.cgi?mode=localhost&graph=all&when=1week&color=black" > /dev/null 2>&1; fi;
if [[ $1 = "all" ]] || [[ $1 = "month" ]]; then /usr/bin/nice -n19 /usr/bin/w3m -dump "http://localhost:8080/monitorix-cgi/monitorix.cgi?mode=localhost&graph=all&when=1month&color=black" > /dev/null 2>&1; fi;
if [[ $1 = "all" ]] || [[ $1 = "year" ]]; then /usr/bin/nice -n19 /usr/bin/w3m -dump "http://localhost:8080/monitorix-cgi/monitorix.cgi?mode=localhost&graph=all&when=1year&color=black" > /dev/null 2>&1; fi;
