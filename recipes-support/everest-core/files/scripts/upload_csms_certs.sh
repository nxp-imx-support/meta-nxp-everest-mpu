#!/bin/bash
#
# Check for required arguments
if [ "$#" -ne 1 ]; then
       echo "Usage: $0 <Path to everest-dev-keys directory"
       exit 1
fi

mkdir -p certs

HOME="$1"
cp $HOME/certs/ca/csms/* certs/
cp $HOME/certs/client/csms/* certs/

cd certs
openssl ec -in OCPP_SERVER.key -passin pass:123456 -out OCPP_SERVER_dec.key

# Check if mc is installed
install_mc() {
    echo " Installing MinIO Client (mc)..."
    curl -O https://dl.min.io/client/mc/release/linux-amd64/mc
    chmod +x mc
    sudo mv mc /usr/local/bin/mc
    echo " MinIO Client (mc) installed successfully."
}

# Check if mc is installed
if ! command -v mc >/dev/null 2>&1;
then
	install_mc
else
	echo " MinIO Client (mc) is already installed."
fi

# Configure MinIO alias
mc alias set minio_mc http://localhost:9000 minioadmin minioadmin

# Create bucket
mc mb minio_mc/citrineos-s3-bucket
# Prompt for station ID
echo "Uploading Keys / Certificates ... "
#upload the Certifictaes/Keys to minio
mc cp OCPP_SERVER.pem minio_mc/citrineos-s3-bucket/
mc cp OCPP_SERVER_dec.key minio_mc/citrineos-s3-bucket/
mc cp OCPP_SERVER_CHAIN.pem minio_mc/citrineos-s3-bucket/
mc cp CSMS_ROOT_CA.pem minio_mc/citrineos-s3-bucket/

# Enable CSMS to use new Certificates
echo "Updating CSMS Certificates & Keys ..."
curl -X 'PUT' \
  'http://localhost:8080/data/certificates/tlsCertificates?id=2' \
  -H "Authorization: Bearer api" \
  -H 'Content-Type: application/json' \
  -d '{
  "certificateChain": [
    "OCPP_SERVER_CHAIN.pem"
  ],
  "privateKey": "OCPP_SERVER_dec.key",
  "rootCA": "CSMS_ROOT_CA.pem"
}'
#  "rootCA": "CSMS_ROOT_CA.pem",
#  "subCAKey": "CSMS_ROOT_CA.key"

mc ls minio_mc/citrineos-s3-bucket

echo "All operations completed."

