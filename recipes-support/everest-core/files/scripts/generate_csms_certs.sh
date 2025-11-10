#!/bin/bash
set -e
rm -rf certs

# Prompt user for connection method
read -p "How do you want to connect to the EVSE? Enter IP address, domain name, or localhost: " CONNECT_INPUT

# Determine CN and SAN usage
if [[ "$CONNECT_INPUT" == "localhost" ]]; then
    CN="localhost"
    USE_SAN=false
else
    CN="$CONNECT_INPUT"
    USE_SAN=true
    if [[ "$CONNECT_INPUT" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        SAN_TYPE="IP"
    else
        SAN_TYPE="DNS"
    fi
fi


mkdir -p certs
cd certs

echo "🔐 Generating Root CA..."

openssl ecparam -name prime256v1 -genkey -noout -out rootCA.key

openssl req -x509 -new -key rootCA.key -sha256 -days 3650 -out rootCA.crt -subj "/C=IN/O=NXP/CN=MyRootCA"

cat rootCA.key rootCA.crt > rootCertificate.pem

echo "🔐 Generating Sub-CA..."

openssl ecparam -name prime256v1 -genkey -noout -out subCA.key

openssl req -new -key subCA.key -out subCA.csr -subj "/C=IN/O=NXP/CN=MySubCA"

cat > subca_ext.cnf <<EOF

basicConstraints=CA:TRUE,pathlen:0

keyUsage=keyCertSign, cRLSign

subjectKeyIdentifier=hash

authorityKeyIdentifier=keyid,issuer

EOF

openssl x509 -req -in subCA.csr -CA rootCA.crt -CAkey rootCA.key -CAcreateserial -out subCA.crt -days 1825 -sha256 -extfile subca_ext.cnf

cat subCA.key subCA.crt > subCAKey.pem

echo "🔐 Generating Leaf/server cert with SAN..."

openssl ecparam -name prime256v1 -genkey -noout -out leaf.key

if [ "$USE_SAN" = true ]; then
  openssl req -new -key leaf.key -out leaf.csr -subj "/CN=$CN"
else
  openssl req -new -key leaf.key -out leaf.csr -subj "/CN=$CN"
fi

# Create SAN config if needed
if [ "$USE_SAN" = true ]; then
cat > leaf_san.cnf <<EOF
[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[ alt_names ]
$SAN_TYPE.1 = $CONNECT_INPUT
EOF
fi

if [ "$USE_SAN" = true ]; then
  openssl x509 -req -in leaf.csr -CA subCAKey.pem -CAkey subCA.key -CAcreateserial -out leaf.crt -days 825 -sha256 -extfile leaf_san.cnf -extensions v3_req
else
  openssl x509 -req -in leaf.csr -CA subCAKey.pem -CAkey subCA.key -CAcreateserial -out leaf.crt -days 825 -sha256
fi

cat leaf.key leaf.crt > leafKey.pem

echo "📎 Building full certificate chain..."

cat leaf.crt subCA.crt rootCA.crt > fullchain.crt

cat leaf.key fullchain.crt > certChain.pem  # Used by CitrineOS

echo "✅ All certificates generated in ./certs:"

ls -1
 

