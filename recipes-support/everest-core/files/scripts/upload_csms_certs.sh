#!/bin/bash
cd certs;

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

# Prompt for station ID
echo "Uploading Keys / Certificates ... "

#upload the Certifictaes/Keys to minio
mc cp leaf.key minio_mc/citrineos-s3-bucket/
sleep 1
mc cp leafKey.pem minio_mc/citrineos-s3-bucket/
sleep 1
mc cp subCA.key minio_mc/citrineos-s3-bucket/
sleep 1
mc cp subCAKey.pem minio_mc/citrineos-s3-bucket/
sleep 1
mc cp rootCertificate.pem minio_mc/citrineos-s3-bucket/

# Enable CSMS to use new Certificates
echo "Updating CSMS Certificates & Keys ..."
curl -X 'PUT' \
  'http://localhost:8080/data/certificates/tlsCertificates?id=2' \
  -H "Authorization: Bearer api" \
  -H 'Content-Type: application/json' \
  -d '{
  "certificateChain": [
    "leafKey.pem","subCAKey.pem"
  ],
  "privateKey": "leaf.key",
  "rootCA": "rootCertificate.pem",
  "subCAKey": "subCA.key"
}'

echo "All operations completed."

