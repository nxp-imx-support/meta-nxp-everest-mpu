#!/bin/bash
SEARCH_PATH="/usr/share/"
FOUND_DIR=$(find "$SEARCH_PATH" -type f -name "InternalCtrlr.json" -exec dirname {} \;)
if [ "" == "$FOUND_DIR" ]; then
	echo "NOT FOUND in /usr/share/"
	FOUND_DIR=$(find ../ -type f -name "InternalCtrlr.json" -exec dirname {} \;)
	if [ "" == "$FOUND_DIR" ]; then
		echo "'InternalCtrlr.json' not found."
		exit;
	fi
fi
echo "Directory containing 'InternalCtrlr.json': $FOUND_DIR"

# Check for required arguments
if [ "$#" -ne 3 ]; then
       echo "Run in  'everest-core/build/run-scripts'"
       echo "Usage: $0 <CSMS IP/Hostname> <CHARGE_STATION_ID> <sp1/sp2/sp3>"
       exit 1
fi

# Assign input arguments
CHARGE_STATION_ID="$2"
SERVER_ID="$1"
SP="$3"
CSMS_SP1_BASE="ws://${SERVER_ID}:8081"
CSMS_SP2_BASE="wss://${SERVER_ID}:8443"
CSMS_SP3_BASE="wss://${SERVER_ID}:8444"


if [[ "$SP" =~ sp1 ]]; then
    CSMS_SP1_URL=${CSMS_SP1_BASE}/${CHARGE_STATION_ID}
    echo "Configured to SecurityProfile: 1, disabling TLS and configuring server to ${CSMS_SP1_URL}"
    ### For default file
    sed -i "s|ws[s]*://[^/]*:[0-9][0-9][0-9][0-9]|${CSMS_SP1_BASE}|g" ${FOUND_DIR}/InternalCtrlr.json
    sed -i 's#securityProfile\\": [0-9]#securityProfile\\": 1#' ${FOUND_DIR}/InternalCtrlr.json
    jq '.properties.SecurityProfile.attributes[0].value |= 1' ${FOUND_DIR}/SecurityCtrlr.json > /var/tmp/SecurityCtrlr.modified.json && mv /var/tmp/SecurityCtrlr.modified.json ${FOUND_DIR}/SecurityCtrlr.json

elif [[ "$SP" =~ sp2 ]]; then

    CSMS_SP2_URL=${CSMS_SP2_BASE}/${CHARGE_STATION_ID}
    echo "Configured to SecurityProfile: 2, configuring server to  ${CSMS_SP2_URL}"
    sed -i "s|ws[s]*://[^/]*:[0-9][0-9][0-9][0-9]|${CSMS_SP2_BASE}|g" ${FOUND_DIR}/InternalCtrlr.json
    sed -i 's#securityProfile\\": [0-9]#securityProfile\\": 2#' ${FOUND_DIR}/InternalCtrlr.json
    jq '.properties.SecurityProfile.attributes[0].value |= 2' ${FOUND_DIR}/SecurityCtrlr.json > /var/tmp/SecurityCtrlr.modified.json && mv /var/tmp/SecurityCtrlr.modified.json ${FOUND_DIR}/SecurityCtrlr.json

elif [[ "$SP" =~ sp3 ]]; then

    CSMS_SP3_URL=${CSMS_SP3_BASE}/${CHARGE_STATION_ID}
    echo "Running with SP3, TLS should be enabled"
    echo "Configured to SecurityProfile: 3, configuring server to  ${CSMS_SP3_URL}"
    sed -i "s|ws[s]*://[^/]*:[0-9][0-9][0-9][0-9]|${CSMS_SP3_BASE}|g" ${FOUND_DIR}/InternalCtrlr.json
    sed -i 's#securityProfile\\": [0-9]#securityProfile\\": 3#' ${FOUND_DIR}/InternalCtrlr.json
    jq '.properties.SecurityProfile.attributes[0].value |= 3' ${FOUND_DIR}/SecurityCtrlr.json > /var/tmp/SecurityCtrlr.modified.json && mv /var/tmp/SecurityCtrlr.modified.json ${FOUND_DIR}/SecurityCtrlr.json

fi

echo "Verifying security settings for $SP : SecurityCtrlr.json"
jq '.properties.SecurityProfile.attributes[0]' ${FOUND_DIR}/SecurityCtrlr.json
echo "Verifying security settings for $SP : InternalCtrlr.json"
jq '.properties.NetworkConnectionProfiles.attributes[0].value | fromjson[0] ' ${FOUND_DIR}/InternalCtrlr.json

#   echo "${CHARGE_STATION_ID}, replacing in InternalCtrlr.json and SecurityCtrlr.json"
sed -i "s#cp0[0-9][0-9]#${CHARGE_STATION_ID}#g" "${FOUND_DIR}/InternalCtrlr.json"
sed -i "s#cp0[0-9][0-9]#${CHARGE_STATION_ID}#g" "${FOUND_DIR}/SecurityCtrlr.json"

#if [[ "$CHARGE_STATION_ID" != cp001 ]]; then
#   echo "Found non-standard CHARGE_STATION_ID ${CHARGE_STATION_ID}, replacing in InternalCtrlr.json and SecurityCtrlr.json"
#   sed -i "s#cp001#${CHARGE_STATION_ID}#" ${FOUND_DIR}/InternalCtrlr.json
#   sed -i "s#cp001#${CHARGE_STATION_ID}#" ${FOUND_DIR}/SecurityCtrlr.json
    # If we change the STATION_ID but don't delete this, the STATION_ID gets
    # appended to the end of the URL, so we end up with 
#fi

rm ${FOUND_DIR}/../../device_model_storage.db
