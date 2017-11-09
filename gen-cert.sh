#!/bin/bash
# Generate Self-Signed Certificates for NEMS Linux

  # Setup SSL Certificates
  mkdir /tmp/certs
  cd /tmp/certs

  echo ""
  echo "Let's generate your SSL Certificates..."
  echo "DO NOT LEAVE ANYTHING BLANK - If you do, the certs will fail."
  echo ""
  echo "Fill in the following:"
  country=$(/usr/local/share/nems/nems-scripts/country.sh)

  read -p "Country Code: " -i "$country" -e country
  read -p "Province/State: " province
  read -p "Your City: " city
  read -p "Company Name or Your Name: " company
  read -p "Your email address: " email

  echo "[req]
  prompt = no
  default_bits = 2048
  default_md = sha256
  distinguished_name = req_distinguished_name
  req_extensions = v3_req
  [req_distinguished_name]
  C = $country
  ST = $province
  L = $city
  O = $company
  CN = *.nems.local
  emailAddress = $email
  [v3_req]
  basicConstraints = CA:FALSE
  keyUsage = nonRepudiation, digitalSignature, keyEncipherment, dataEncipherment
  subjectAltName = @alt_names
  [alt_names]
  DNS.1 = nems.local
  " > /tmp/certs/config.txt

  # Create CA private key
  /usr/bin/openssl genrsa 2048 > ca-key.pem

  # Create CA cert based on private key
  /usr/bin/openssl req -sha256 -new -x509 -config /tmp/certs/config.txt -nodes -days 3650 \
          -key ca-key.pem -out ca.pem

  # Create server certificate, remove passphrase, and sign it
  # server-cert.pem = public key, server-key.pem = private key
  /usr/bin/openssl req -sha256 -newkey rsa:2048 -config /tmp/certs/config.txt -days 3650 \
          -nodes -keyout server-key.pem -out server-req.pem

  /usr/bin/openssl rsa -in server-key.pem -out server-key.pem

  /usr/bin/openssl x509 -req -in server-req.pem -days 3600 \
          -CA ca.pem -CAkey ca-key.pem -set_serial 01 -out server-cert.pem

  # Create client certificate, remove passphrase, and sign it
  # client-cert.pem = public key, client-key.pem = private key
  /usr/bin/openssl req -sha256 -newkey rsa:2048 -config /tmp/certs/config.txt -days 3600 \
          -nodes -keyout client-key.pem -out client-req.pem

  /usr/bin/openssl rsa -in client-key.pem -out client-key.pem

  /usr/bin/openssl x509 -req -in client-req.pem -days 3600 \
          -CA ca.pem -CAkey ca-key.pem -set_serial 01 -out client-cert.pem

  rm /tmp/certs/config.txt

  # Create combined PEM for webmin miniserver
  cat server-cert.pem server-key.pem > combined.pem


  # Create combined PEM for webmin miniserver
  cat server-cert.pem server-key.pem > combined.pem

  echo "Done."
  
  echo ""
  rm -rf /var/www/certs/
  mv /tmp/certs /var/www/
  chown -R root:root /var/www/certs
  chmod -R 700 /var/www/certs

  # Restart services
  echo "Restarting NEMS services..."
  systemctl restart rpimonitor
  systemctl restart webmin
  systemctl restart nagios3
  systemctl restart apache2

  echo "Done."
