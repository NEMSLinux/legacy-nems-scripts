#!/bin/bash
# This script generates all the images for Monitorix via cronjob rather than on-demand, giving the perception of much faster processing and reducing load on page refresh
# It also ensures certain graphs (ie. Yearly) are not updated every time since the data won't be affected

  # Ping Google to see if Internet is up. Don't begin until we have Internet.
  count=1
  while ! ping -c 1 -W 1 google.com; do
    if [ $count -eq 60 ]
      then
         echo "Google not responding. Resuming, but if Internet is down, updates will fail."
         break;
    fi     
    ((count++))
    sleep 1
  done

# Sometimes Monitorix (the daemon) stops responding even though it is running.
# Restart it here just in case, before loading the data.
/bin/systemctl restart monitorix
sleep 5

# Detect the default network interface and use it for net graphs
adapter=`/usr/local/bin/nems-info nic`
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

# Only proceed if Monitorix is running
running=$(/usr/local/bin/nems-info checkport 8080)
if [[ $running == 0 ]]; then
  echo "Monitorix is not running. Aborting."
  exit 1
fi

# Generate the graphs

if [[ $1 = "all" ]] || [[ $1 = "day" ]]; then
  until $(/usr/bin/curl --output /dev/null --silent --fail "http://127.0.0.1:8080/monitorix-cgi/monitorix.cgi?mode=localhost&graph=all&when=1day&color=black"); do
    sleep .5
  done;
fi;

if [[ $1 = "all" ]] || [[ $1 = "week" ]]; then
  until $(/usr/bin/curl --output /dev/null --silent --fail "http://127.0.0.1:8080/monitorix-cgi/monitorix.cgi?mode=localhost&graph=all&when=1week&color=black"); do
    sleep .5
  done;
fi;

if [[ $1 = "all" ]] || [[ $1 = "month" ]]; then
  until $(/usr/bin/curl --output /dev/null --silent --fail "http://127.0.0.1:8080/monitorix-cgi/monitorix.cgi?mode=localhost&graph=all&when=1month&color=black"); do
    sleep .5
  done;
fi;

if [[ $1 = "all" ]] || [[ $1 = "year" ]]; then
  until $(/usr/bin/curl --output /dev/null --silent --fail "http://127.0.0.1:8080/monitorix-cgi/monitorix.cgi?mode=localhost&graph=all&when=1year&color=black"); do
    sleep .5
  done;
fi;

