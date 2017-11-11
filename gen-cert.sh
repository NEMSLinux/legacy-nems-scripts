#!/bin/bash
# Generate Self-Signed Certificates for NEMS Linux
# By Robbie Ferguson
# nemslinux.com | baldnerd.com | category5.tv

  # Setup SSL Certificates
  mkdir /tmp/certs
  cd /tmp/certs

  echo ""
  echo "Let's generate your SSL Certificates..."

HEIGHT=15
WIDTH=40
CHOICE_HEIGHT=4
BACKTITLE="NEMS Linux"
TITLE="Certificate Generator"
MENU="Choose one of the following options:"

OPTIONS=(1 "Use Generic Settings"
         2 "Use Custom Settings")

CHOICE=$(dialog --clear \
                --backtitle "$BACKTITLE" \
                --title "$TITLE" \
                --menu "$MENU" \
                $HEIGHT $WIDTH $CHOICE_HEIGHT \
                "${OPTIONS[@]}" \
                2>&1 >/dev/tty)

if test $? -eq 0
then 
  clear
else
  clear
  echo "Canceled"
  cd /tmp
  rm -rf /tmp/certs
  exit
fi

case $CHOICE in
        1)
            echo "Using generic settings:"
            country="CA"
            province="Ontario"
            city="Toronto"
            company="NEMS Linux"
            email="noreply@nemslinux.com"
            ;;
        2)

            # open fd
            exec 3>&1

            # Declare Variables
            country=$(/usr/local/share/nems/nems-scripts/country.sh)
            province=""
            city=""
            company=""
            email=""

            VALUES=$(dialog --ok-label "Generate" \
            --backtitle "NEMS Linux" \
            --title "Custom Cert Settings" \
            --form "Fill in the following:" \
            15 50 0 \
	"Country Code:" 1 1	"$country" 	1 15 2 0 \
	"Province:"    2 1	"$province"  	2 15 14 0 \
	"City:"    3 1	"$city"  	3 15 14 0 \
	"Company:"     4 1	"$company" 	4 15 30 0 \
	"Email:"     5 1	"$email" 	5 15 30 0 \
          2>&1 1>&3)

          if test $? -eq 0
          then 
            clear
            echo "Using custom settings:"
            echo ""
          else
            clear
            echo "Canceled"
            cd /tmp
            rm -rf /tmp/certs
            exit
          fi

          # close fd
          exec 3>&-


echo "$VALUES" > /tmp/certs/input.tmp
IFS=$'\n' read -d '' -r -a data < /tmp/certs/input.tmp
country="${data[0]}"
province="${data[1]}"
city="${data[2]}"
company="${data[3]}"
email="${data[4]}"

            ;;
esac

  echo "Country: $country"
  echo "Province: $province"
  echo "City: $city"
  echo "Company: $company"
  echo "Email: $email"
  echo ""

  if [[ "$country" == "" ]] || [[ "$province" == "" ]] || [[ "$city" == "" ]] || [[ "$company" == "" ]] || [[ "$email" == "" ]]; then
    echo "Error: You missed some required information."
    echo "       ALL FIELDS ARE REQUIRED."
    echo ""
    exit
  fi

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
#  CN = *.$(hostname).local
  emailAddress = $email
  [v3_req]
  basicConstraints = CA:FALSE
  keyUsage = nonRepudiation, digitalSignature, keyEncipherment, dataEncipherment
  subjectAltName = @alt_names
  [alt_names]
  DNS.1 = nems.local
  DNS.2 = *.nems.local
  " > /tmp/certs/config.txt

  echo "Generating certificates..."
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
