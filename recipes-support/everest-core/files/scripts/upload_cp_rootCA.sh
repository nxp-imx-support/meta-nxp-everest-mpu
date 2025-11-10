#!/bin/bash
cd certs;

# Prompt user for prerequisites
echo "Please confirm the following prerequisites before proceeding:"
echo "1. EVSE/CSMS is connected in Security Profile 1."
read -p "(yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
  echo "Please complete the prerequisites and run the script again."
  exit 1
fi

# Prompt for station ID
read -p "Enter the Station ID: " STATION_ID

# Call rootCertificate API
echo "Updating EVSE rootCertificate ..."
curl --location --request PUT 'http://localhost:8080/data/certificates/rootCertificate?tenant=1' \
  -H "Authorization: Bearer api" \
  -H 'Content-Type: application/json' \
  --data "{
  \"stationId\": \"$STATION_ID\",
  \"certificateType\": \"CSMSRootCertificate\",
  \"tenantId\": \"1\",
  \"fileId\": \"rootCertificate.pem\"
}"

echo "All operations completed."

