#!/bin/bash
# Cron script to transfer data between resources without granting permissions to those resources

# Save new resource.cfg file from NEMS System Configuration
if [ -f /tmp/transfer.resource.cfg ]; then
  if [ -f /etc/nagios3/resource.cfg.bak ]; then
    rm /etc/nagios3/resource.cfg.bak
  fi
  systemctl stop nagios3
  mv /etc/nagios3/resource.cfg /etc/nagios3/resource.cfg.bak
  mv /tmp/transfer.resource.cfg /etc/nagios3/resource.cfg
  systemctl start nagios3
fi
