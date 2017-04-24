#!/bin/bash
# NEMS Server Info Script

export COMMAND=$1
me=`basename "$0"`
USAGE="Usage: ./$me COMMAND"
if [ -z "$COMMAND" ]; then echo $USAGE; exit; fi

if [ -z "$COMMAND" == "ip" ]; then
  /sbin/ip -f inet addr show eth0 | grep -Po 'inet \K[\d.]+'
exit; fi
