#!/bin/bash
# Just a dummy port listener by Robbie Ferguson
# See https://docs.nemslinux.com/en/latest/basic/9590.html

# This script can be removed from 1.6 (now installed via repository)

set -e

pid=""
if [[ -f /run/9590.pid ]]; then
  pid=$(cat /run/9590.pid)
fi

case "${1:-}" in
  stop|reload|restart|force-reload)
        echo "Stopping 9590."
        kill $pid
	rm /run/9590.pid ;;

  start)
     if [[ -f /run/9590.pid ]]; then
       if ps -p $pid > /dev/null; then
         echo "Already running."
         exit 0
       else
         rm /run/9590.pid
       fi
     fi
        echo "Starting 9590."
        /bin/nc -l -p 9590 & echo $! > /run/9590.pid ;;

  *)
        echo "Usage: ${0:-} {start|stop|status|restart|reload|force-reload}" >&2
        exit 1
        ;;
esac


