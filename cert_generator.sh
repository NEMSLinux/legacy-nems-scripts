#!/bin/bash

# Create clean environment
DATE=`date +%Y-%m-%d.certs`
mkdir /tmp/$DATE
cd /tmp/$DATE

# Generate the config file
# Will move the configuration into a config file which will be included in .gitignore
# For now, this is under development and these settings don't REALLY matter (it's self-signed anyways).
echo "[req]
prompt = no
distinguished_name = req_distinguished_name
req_extensions = v3_req

[req_distinguished_name]
C = CA
ST = Ontario
L = Barrie
O = Nagios Enterprise Management Server
#OU = Org Unit
CN = NEMS
emailAddress = nems@baldnerd.com

[v3_req]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = nems.local
DNS.2 = nems" > config.txt

echo "*** CREATE CERTIFICATE AUTHORITY CERTS ***"
echo ""

# Create CA private key
openssl genrsa 2048 > ca-key.pem

# Create CA cert based on private key
openssl req -sha256 -new -x509 -config config.txt -nodes -days 3650 \
        -key ca-key.pem -out ca.pem

# Create server certificate, remove passphrase, and sign it
# server-cert.pem = public key, server-key.pem = private key
echo "*** CREATE SERVER CERTS ***"
echo ""
openssl req -sha256 -newkey rsa:2048 -config config.txt -days 3650 \
        -nodes -keyout server-key.pem -out server-req.pem

openssl rsa -in server-key.pem -out server-key.pem

openssl x509 -req -in server-req.pem -days 3600 \
        -CA ca.pem -CAkey ca-key.pem -set_serial 01 -out server-cert.pem

# Create client certificate, remove passphrase, and sign it
# client-cert.pem = public key, client-key.pem = private key
echo "*** CREATE CLIENT CERTS ***"
echo ""
openssl req -sha256 -newkey rsa:2048 -config config.txt -days 3600 \
        -nodes -keyout client-key.pem -out client-req.pem

openssl rsa -in client-key.pem -out client-key.pem

openssl x509 -req -in client-req.pem -days 3600 \
        -CA ca.pem -CAkey ca-key.pem -set_serial 01 -out client-cert.pem

rm config.txt
