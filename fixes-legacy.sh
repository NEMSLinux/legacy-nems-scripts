#!/bin/bash
echo "Running legacy fixes... you may want to consider upgrading your NEMS version."

 # using hard file location rather than symlink as symlink may not exist yet on older versions
 platform=$(/usr/local/share/nems/nems-scripts/info.sh platform)
 ver=$(/usr/local/share/nems/nems-scripts/info.sh nemsver) 

# NEMS 1.2.1 was released with an incorrect permission on this file
if [[ $ver = "1.2.1" ]]; then
  chown www-data:www-data /etc/nagios3/global/timeperiods.cfg
fi

echo $ver

exit
