#!/bin/bash
# NEMS Server Info Script (primarily used for MOTD)

# Force decimals to use ... decimals (for compatibility with foreign locales)
export LC_NUMERIC=C

export COMMAND=$1
export VARIABLE=$2

me=`basename "$0"`

# Some functions

  function SecondsToDaysHoursMinutesSeconds() {
    local seconds=$1
    local days=$(($seconds/86400))
    seconds=$(($seconds-($days*86400) ))
    local hours=$(($seconds/3600))
    seconds=$((seconds-($hours*3600) ))
    local minutes=$(($seconds/60))
    seconds=$(( $seconds-($minutes*60) ))
    echo -n "${days}D ${hours}H ${minutes}M ${seconds}S"
  }

  function FileAge() {
    echo $((`date +%s` - `stat -c %Z $1`))
  }

# End of functions

# Output local IP address
if [[ $COMMAND == "ip" ]]; then
  # Work with any NIC
  ip=$(/sbin/ip -f inet addr show $($0 nic) | grep -Po 'inet \K[\d.]+' | head -n 1)
  if [[ $ip == "" ]]; then
    # Never reply with a blank string - instead, use localhost if no IP is found
    # This would be the case if no network connection is non-existent
    echo "127.0.0.1"
  else
    # Reply with the real IP of the first network interface.
    # If multiple networks, only the first will report.
    echo $ip
  fi

elif [[ $COMMAND == "nic" ]]; then
  # Show the active NIC
  # OLD way causes errors if connected to two interfaces (eg., eth0 and wlan0)
#  interface=`/sbin/route | /bin/grep '^default' | /bin/grep -o '[^ ]*$'`
  # NEW way (20181201) tests the route based on $host and treats that as the interface
  host=google.com
  host_ip=$(getent ahosts "$host" | awk '{print $1; exit}')
  interface=`ip route get "$host_ip" | grep -Po '(?<=(dev )).*(?= src| proto)' | cut -f 1 -d " "`
  echo $interface

elif [[ $COMMAND == "fileage" ]]; then
  if [[ -e $VARIABLE ]]; then
     echo $(SecondsToDaysHoursMinutesSeconds $(FileAge $VARIABLE) )
  else
    echo "ERROR: File not found $VARIABLE"
  fi
elif [[ $COMMAND == "checkport" ]]; then
  response=`/bin/nc -v -z -w2 127.0.0.1 $VARIABLE 2>&1`
  if echo "$response" | grep -q 'refused'; then
    echo 0
  else
    echo 1
  fi

# Output current running NEMS version
elif [[ $COMMAND == "nemsver" ]]; then
  cat /usr/local/share/nems/nems.conf | grep version |  printf '%s' $(cut -n -d '=' -f 2)

# Output the current available NEMS version (update.sh generates this every day at midnight and at reboot)
elif [[ $COMMAND == "nemsveravail" ]]; then
  if [[ -f /root/nems/nems-migrator/data/nems/ver-current.txt ]]; then
    /bin/cat /root/nems/nems-migrator/data/nems/ver-current.txt
  elif [[ -f /var/www/html/inc/ver-available.txt ]]; then
    /bin/cat /var/www/html/inc/ver-available.txt
  fi

# Output the number of users connected to server
elif [[ $COMMAND == "users" ]]; then
  export USERCOUNT=`/usr/bin/users | /usr/bin/wc -w`
  if [ $USERCOUNT -eq 1 -o $USERCOUNT -eq -1 ]
		then
			echo $USERCOUNT user
		else
			echo $USERCOUNT users
	fi

# Output disk usage in percent
elif [[ $COMMAND == "diskusage" ]]; then
  df -hl /home | awk '/^\/dev\// { sum+=$5 } END { print sum }'

# Output memory usage breakdown
elif [[ $COMMAND == "memusage" ]]; then
  for file in /proc/*/status ; do awk '/VmSwap|Name/{printf $2 " " $3}END{ print ""}' $file; done | sort -k 2 -n -r | less

# Output country code
elif [[ $COMMAND == "country" ]]; then
  /usr/local/share/nems/nems-scripts/country.sh

# Output revision of Raspberry Pi board
elif [[ $COMMAND == "hwver" ]]; then
# if is pi
 cat /proc/cpuinfo | grep 'Revision' | awk '{print $3}' | sed 's/^1000//'

# Output an MD5 of the Pi board serial number - we'll call this the NEMS Pi ID
elif [[ $COMMAND == "hwid" ]]; then
  platform=$(/usr/local/share/nems/nems-scripts/info.sh platform)
  # Raspberry Pi
  if (( $platform >= 0 )) && (( $platform <= 9 )); then
    cat /proc/cpuinfo | grep Serial |  printf '%s' $(cut -n -d ' ' -f 2) | md5sum | cut -d"-" -f1 -
  # Pine64 Devices
  elif (( $platform >= 40 )) && (( $platform <= 49 )); then 
    /sbin/ifconfig eth0 | grep -o -E '([[:xdigit:]]{1,2}:){5}[[:xdigit:]]{1,2}' | md5sum | cut -d"-" -f1 -
  # ODROID XU3/XU4
  elif (( $platform == 11 )); then 
    /sbin/ifconfig eth0 | grep -o -E '([[:xdigit:]]{1,2}:){5}[[:xdigit:]]{1,2}' | md5sum | cut -d"-" -f1 -
  # Virtual Appliance
  elif (( $platform >= 20 )); then 
    /sbin/ifconfig enp0s3 | grep -o -E '([[:xdigit:]]{1,2}:){5}[[:xdigit:]]{1,2}' | md5sum | cut -d"-" -f1 -
  fi

elif [[ $COMMAND == "speedtest" ]]; then
# output json response of detected wifi networks
  /usr/local/share/nems/nems-scripts/info2.sh 10 $VARIABLE

elif [[ $COMMAND == "rootfulldev" ]]; then
  /bin/mount | /bin/sed -n 's|^/dev/\(.*\) on / .*|\1|p'

elif [[ $COMMAND == "rootdev" ]]; then
# output json response of detected wifi networks
  /usr/local/share/nems/nems-scripts/info2.sh 8

elif [[ $COMMAND == "rootpart" ]]; then
# output json response of detected wifi networks
  /usr/local/share/nems/nems-scripts/info2.sh 9

elif [[ $COMMAND == "wifi" ]]; then
# output json response of detected wifi networks
  /usr/local/share/nems/nems-scripts/info2.sh 7

elif [[ $COMMAND == "platform" ]]; then
# show if is pi or if is xu4, etc. by numerical value
  /usr/local/share/nems/nems-scripts/info2.sh 3

elif [[ $COMMAND == "platform-name" ]]; then
# show if is pi or if is xu4, etc. by name
  /usr/local/share/nems/nems-scripts/info2.sh 4

elif [[ $COMMAND == "drives" ]]; then
# Generate a list of drives
# Used by NEMS to configure external storage
  lsblk -J --output NAME,MOUNTPOINT,FSTYPE,UUID,SIZE,TYPE

elif [[ $COMMAND == "loadaverage" ]]; then
# See 1 week load average
if [ -f /var/log/nems/load-average.log ]; then
  cat /var/log/nems/load-average.log
  echo ""
else
  echo 0
fi

elif [[ $COMMAND == "loadaverageround" ]]; then
# See 1 week load average
if [ -f /var/log/nems/load-average.log ]; then
  la=$(cat /var/log/nems/load-average.log)
  printf '%.*f\n' 2 $la
else
  echo 0
fi

elif [[ $COMMAND == "username" ]]; then
  # Get NEMS username
  # From nems.conf
  if [[ -f /usr/local/share/nems/nems.conf ]]; then
    if grep -q "username" /usr/local/share/nems/nems.conf; then
      username=`cat /usr/local/share/nems/nems.conf | grep username |  printf '%s' $(cut -n -d '=' -f 2)`
    fi
  fi
  # Legacy support: from htpasswd
  if [[ $username == "" ]]; then
    if [[ -f /var/www/htpasswd ]] ; then
      username=`cat /var/www/htpasswd | cut -d: -f1`
    fi
  fi
  if [[ $username == "" ]]; then
    username='nemsadmin' # Default if none found
  fi
  echo $username

elif [[ $COMMAND == "allowupdate" ]]; then
  # See if we're allowed to run automated updates
  # From nems.conf (set in NEMS SST)
  if [[ -f /usr/local/share/nems/nems.conf ]]; then
    if grep -q "allowupdate" /usr/local/share/nems/nems.conf; then
      allowupdate=`cat /usr/local/share/nems/nems.conf | grep allowupdate |  printf '%s' $(cut -n -d '=' -f 2)`
    fi
  fi
  # Default is allow (if not set)
  if [[ $allowupdate == "" ]]; then
    # 1 = Not allowed
    # 2 = Allowed monthly
    # 3 = Allowed semi-weekly
    # 4 = Allowed weekly
    # 5 = Allowed daily
    allowupdate=5 # Not allowed
  fi
  echo $allowupdate

elif [[ $COMMAND == "checkin" ]]; then
  # See if user has enabled checkin
  # From nems.conf (set in NEMS SST)
  # Default is to not checkin
  # This does not affect NEMS Anonymous stats. This is the email function that notifies a user if their NEMS server fails to checkin.
  checkin=0
  if [[ -f /usr/local/share/nems/nems.conf ]]; then
    if grep -q "checkin.enabled" /usr/local/share/nems/nems.conf; then
      checkin=`cat /usr/local/share/nems/nems.conf | grep checkin.enabled |  printf '%s' $(cut -n -d '=' -f 2)`
    fi
  fi
  echo $checkin

elif [[ $COMMAND == "checkinemail" ]]; then
  # Get the checkin email address
  # From nems.conf (set in NEMS SST)
  checkinemail=""
  if [[ -f /usr/local/share/nems/nems.conf ]]; then
    if grep -q "checkin.email" /usr/local/share/nems/nems.conf; then
      checkinemail=`cat /usr/local/share/nems/nems.conf | grep checkin.email |  printf '%s' $(cut -n -d '=' -f 2)`
    fi
  fi
  echo $checkinemail

elif [[ $COMMAND == "checkininterval" ]]; then
  # Get the checkin interval
  # From nems.conf (set in NEMS SST)
  checkininterval=8
  if [[ -f /usr/local/share/nems/nems.conf ]]; then
    if grep -q "checkin.interval" /usr/local/share/nems/nems.conf; then
      checkininterval=`cat /usr/local/share/nems/nems.conf | grep checkin.interval |  printf '%s' $(cut -n -d '=' -f 2)`
    fi
  fi
  echo $checkininterval



# See current CPU usage in percent
elif [[ $COMMAND == "cpupercent" ]]; then
grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$4+$5)} END {print usage}'

elif [[ $COMMAND == "temperature" ]]; then
  /usr/local/share/nems/nems-scripts/info2.sh 1

elif [[ $COMMAND == "nemsbranch" ]]; then
  /usr/local/share/nems/nems-scripts/info2.sh 2

elif [[ $COMMAND == "sslcert" ]]; then
  /usr/bin/openssl s_client -connect localhost:443 < /dev/null 2>/dev/null | openssl x509 -text -in /dev/stdin

elif [[ $COMMAND == "init" ]]; then
  if [[ -f /var/www/htpasswd ]]; then
    lenhtpass=$(wc -m /var/www/htpasswd | awk '{print $1}')
    if [ "$lenhtpass" -gt "0" ]; then
      echo 1
    else
      echo 0
    fi
  else
    echo 0
  fi

elif [[ $COMMAND == "online" ]]; then
  # Check if Github responds
  online=$(ping -q -w 1 -c 1 github.com > /dev/null 2>&1 && echo 1 || echo 0)
  if [[ $online == 1 ]]; then
    echo 1
  else
    # Try a second time as failsafe
    ping -q -w 1 -c 1 github.com > /dev/null 2>&1 && echo 1 || echo 0
  fi

elif [[ $COMMAND == "socket" ]]; then
  ver=$(/usr/local/bin/nems-info nemsver)
  if (( $(awk 'BEGIN {print ("'$ver'" >= "'1.4.1'")}') )); then
    socket=/usr/local/nagios/var/rw/live.sock
  else
    socket=/var/lib/nagios3/rw/live.sock
  fi
  echo $socket

elif [[ $COMMAND == "socketstatus" ]]; then
  socket=$(/usr/local/bin/nems-info socket)
  if [[ -e $socket ]]; then
    echo 1
  else
    echo 0
  fi

elif [[ $COMMAND == "hosts" ]]; then
  socket=$(/usr/local/bin/nems-info socket)
  if [[ -e $socket ]]; then
    /usr/local/share/nems/nems-scripts/stats-livestatus.py $socket hosts
  else
    echo 0
  fi

elif [[ $COMMAND == "services" ]]; then
  socket=$(/usr/local/bin/nems-info socket)
  if [[ -e $socket ]]; then
    /usr/local/share/nems/nems-scripts/stats-livestatus.py $socket services
  else
    echo 0
  fi

elif [[ $COMMAND == "downtimes" ]]; then
  /usr/local/share/nems/nems-scripts/info2.sh 6

elif [[ $COMMAND == "benchmark" ]]; then
  if [[ $VARIABLE == 'cpu' ]]; then
    cat /var/log/nems/benchmarks/cpu
  fi
  if [[ $VARIABLE == 'mutex' ]]; then
    cat /var/log/nems/benchmarks/mutex
  fi
  if [[ $VARIABLE == 'io' ]]; then
    cat /var/log/nems/benchmarks/io
  fi
  if [[ $VARIABLE == 'ram' ]]; then
    cat /var/log/nems/benchmarks/ram
  fi


elif [[ $COMMAND == "alias" ]]; then
  # From nems.conf
  if [[ -f /usr/local/share/nems/nems.conf ]]; then
    if grep -q "alias" /usr/local/share/nems/nems.conf; then
      alias=`cat /usr/local/share/nems/nems.conf | grep alias | printf '%s ' $(cut -n -d '=' -f 2)`
    fi
    # Remove carriage return, and trim
    alias=$(echo "$alias" | tr '\n' ' ' | xargs)
  fi
  # From hostname (if alias is not set)
  if [[ $alias == "" ]]; then
    alias=`hostname`
  fi
  # Fallback to the obvious
  if [[ $alias == "" ]]; then
    alias='NEMS'
  fi
  echo $alias

elif [[ $COMMAND == "state" ]]; then
  /usr/local/share/nems/nems-scripts/stats-livestatus-full.sh

elif [[ $COMMAND == "cloudauth" ]]; then
  hwid=`/usr/local/bin/nems-info hwid`
  osbpass=$(cat /usr/local/share/nems/nems.conf | grep osbpass | printf '%s' $(cut -n -d '=' -f 2))
  osbkey=$(cat /usr/local/share/nems/nems.conf | grep osbkey | printf '%s' $(cut -n -d '=' -f 2))
  if [[ $osbpass == '' ]] || [[ $osbkey == '' ]]; then
#    echo NEMS Cloud is not currently enabled.
    echo 0
    exit
  fi;
  data=$(curl -s -F "hwid=$hwid" -F "osbkey=$osbkey" -F "query=status" https://nemslinux.com/api-backend/offsite-backup-checkin.php)
  if [[ $data == '1' ]]; then # this account passes authentication
    echo 1
  else
    echo 0
  fi

elif [[ $COMMAND == "webhook" ]]; then
  # From nems.conf
  if [[ -f /usr/local/share/nems/nems.conf ]]; then
    if grep -q "webhook" /usr/local/share/nems/nems.conf; then
      webhook=`cat /usr/local/share/nems/nems.conf | grep webhook | printf '%s ' $(cut -n -d '=' -f 2)`
    fi
    # Remove carriage return, and trim
    webhook=$(echo "$webhook" | tr '\n' ' ' | xargs)
  fi
  echo $webhook

elif [[ $COMMAND == "quickfix" ]]; then
  if [[ -e /var/run/nems-quickfix.pid ]]; then
    pid=$(cat /var/run/nems-quickfix.pid)
    if ps -p $pid > /dev/null
    then
      echo 1
    else
      echo 0
    fi
  else
    echo 0
  fi

elif [[ $COMMAND == "fixes" ]]; then
  if [[ -e /var/run/nems-fixes.pid ]]; then
    pid=$(cat /var/run/nems-fixes.pid)
    if ps -p $pid > /dev/null
    then
      echo 1
    else
      echo 0
    fi
  else
    echo 0
  fi

elif [[ $COMMAND == "update" ]]; then
  if [[ -e /var/run/nems-update.pid ]]; then
    pid=$(cat /var/run/nems-update.pid)
    if ps -p $pid > /dev/null
    then
      echo 1
    else
      echo 0
    fi
  else
    echo 0
  fi

elif [[ $COMMAND == "piwatcher" ]]; then
  if [[ -e /var/log/nems/piwatcher ]]; then
    piwatcher=$(cat /var/log/nems/piwatcher)
    if [[ $piwatcher == "1" ]]; then
      echo 1
    else
      echo 0
    fi
  else
    echo 0
  fi


# Output usage info as no valid command line argument was provided
else
  echo "Usage: ./$me command"
  echo "For help, visit https://docs.nemslinux.com/commands/nems-info"
fi

