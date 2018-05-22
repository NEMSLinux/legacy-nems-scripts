#!/bin/bash
echo "Running legacy fixes... you may want to consider upgrading your NEMS version."

# NEMS 1.2.1 was released with an incorrect permission on this file
if [[ $ver = "1.2.1" ]]; then
  chown www-data:www-data /etc/nagios3/global/timeperiods.cfg
fi

echo $ver

exit
