#!/bin/bash
echo Testing fix of SSL...

printf "Backing up your current settings... "
if [[ ! -f /etc/apache2/sites-available/000-default.conf~ ]]; then
  cp /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/000-default.conf~
  echo Done.
else
  echo Not needed - was already backed up.
fi

printf "Generating new cert... "
/usr/sbin/make-ssl-cert generate-default-snakeoil --force-overwrite
cat /etc/ssl/certs/ssl-cert-snakeoil.pem /etc/ssl/private/ssl-cert-snakeoil.key > /etc/ssl/certs/ssl-cert-snakeoil-combined.pem
echo Done.

printf "Patching your Apache2 Configuration... "
  # Comment out the CA
  if grep -q "  SSLCertificateChainFile /var/www/certs/ca.pem" /etc/apache2/sites-available/000-default.conf; then
    /bin/sed -i -- 's,SSLCertificateChainFile,# SSLCertificateChainFile,g' /etc/apache2/sites-available/000-default.conf
  fi

  # Change the cert files
  if grep -q "/var/www/certs/server-cert.pem" /etc/apache2/sites-available/000-default.conf; then
    /bin/sed -i -- 's,/var/www/certs/server-cert.pem,/etc/ssl/certs/ssl-cert-snakeoil.pem,g' /etc/apache2/sites-available/000-default.conf
  fi
  if grep -q "/var/www/certs/server-key.pem" /etc/apache2/sites-available/000-default.conf; then
    /bin/sed -i -- 's,/var/www/certs/server-key.pem,/etc/ssl/private/ssl-cert-snakeoil.key,g' /etc/apache2/sites-available/000-default.conf
  fi
echo Done.

printf "Restarting Apache2..."
/bin/systemctl restart apache2
echo Done.

printf "Patching your Webmin Configuration... "
  if grep -q "/var/www/certs/combined.pem" /etc/webmin/miniserv.conf; then
    /bin/sed -i -- 's,/var/www/certs/combined.pem,/etc/ssl/certs/ssl-cert-snakeoil-combined.pem,g' /etc/webmin/miniserv.conf
  fi
echo Done.

printf "Restarting Webmin..."
/bin/systemctl restart webmin
echo Done.


echo ""
echo Patch complete. Please test a secure connection to your NEMS server in your browser.
echo ""
