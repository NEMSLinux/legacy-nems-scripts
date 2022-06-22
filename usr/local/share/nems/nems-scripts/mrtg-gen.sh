#!/bin/bash

# If user has not run mrtgsetup, /var/www/mrtg will not exist yet, so only generate graphs if it exists (is configured)

if [[ -d /var/www/mrtg ]]; then

  # Generate MRTG graphs
    env LANG=C /usr/local/mrtg2/bin/mrtg /etc/mrtg/mrtg.cfg

  # Generate MRTG index
    /usr/local/mrtg2/bin/indexmaker /etc/mrtg/mrtg.cfg --output=/var/www/mrtg/index.php

fi
