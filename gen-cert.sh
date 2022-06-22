#!/bin/bash
# Generate Self-Signed Certificates for NEMS Linux
# By Robbie Ferguson
# nemslinux.com | baldnerd.com | category5.tv

  platform=$(/usr/local/bin/nems-info platform)

  echo ""
  echo "Generating unique SSL Certificates..."

  # Install make-ssl-cert if it isn't already installed
  if [[ ! -e /usr/sbin/make-ssl-cert ]]; then
    apt -y install ssl-cert
  fi

  # Using snakeoil for the time being since we had issues with nems-cert and Windows 10.

  # Generating new Snakeoil cert
  /usr/sbin/make-ssl-cert generate-default-snakeoil --force-overwrite

  # Combine for Webmin and other interfaces
  cat /etc/ssl/certs/ssl-cert-snakeoil.pem /etc/ssl/private/ssl-cert-snakeoil.key > /etc/ssl/certs/ssl-cert-snakeoil-combined.pem
  # Maximum permission for monit to use the cert is 700 and since we don't need an x bit, we'll do 600
  # Cert is owned by root:root
  chmod 600 /etc/ssl/certs/ssl-cert-snakeoil-combined.pem

  echo "Generating unique SSH Certificates..."
  /bin/rm /etc/ssh/ssh_host_*
  if [[ ! $platform == "21" ]]; then
    dpkg-reconfigure openssh-server
    systemctl restart ssh
  fi

  echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@    WARNING: NEMS SERVER IDENTIFICATION HAS CHANGED!     @
@    Next time you connect, you'll need to re-import!     @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
"
  echo Done.

  # Restart services
  echo "Restarting NEMS services..."
  if (( $platform >= 0 )) && (( $platform <= 9 )); then
    systemctl restart rpimonitor
  fi
  systemctl restart nagios
  systemctl restart apache2

  echo "Done."

exit 1



