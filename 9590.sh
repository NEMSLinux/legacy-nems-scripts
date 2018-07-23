#!/bin/bash

set -e

case "${1:-}" in
  stop|reload|restart|force-reload)
        echo "Stopping 9590."
        kill $(cat /run/9590.pid)
	rm /run/9590.pid ;;

  start)
     if [[ -f /run/9590.pid ]]; then
       echo "Already running."
       exit 0
     fi
        echo "Starting 9590."
        /bin/nc -l -p 9590 &
        echo $! > /run/9590.pid ;;

  *)
        echo "Usage: ${0:-} {start|stop|status|restart|reload|force-reload}" >&2
        exit 1
        ;;
esac


