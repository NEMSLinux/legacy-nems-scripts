#!/bin/bash
/root/nems/nagios-api/nagios-api -p 8090 -c /var/lib/nagios3/rw/live.sock -s /var/cache/nagios3/status.dat -l /var/log/nagios3/nagios.log
