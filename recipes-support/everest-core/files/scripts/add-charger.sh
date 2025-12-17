#!/usr/bin/env bash

# Check for required arguments
if [ "$#" -ne 2 ]; then
       echo "Usage: $0 <CSMS IP/Hostname> <CHARGEPOINT_ID>"
       exit 1
fi

SERVER_ID="$1"
CHARGEPOINT_ID="$2"
GRAPHQL_API_URL="http://${SERVER_ID}:8090/v1/graphql"

# Configuration
CP_PASSWORD="DEADBEEFDEADBEEF"

# Function to execute GraphQL mutation
execute_graphql() {
    local query="$1"
    echo "DEBUG: Executing query: $query" >&2
    local json_payload=$(jq -n --arg query "$query" '{"query": $query}')
    echo "DEBUG: JSON payload: $json_payload" >&2
    local response=$(curl -s -X POST "$GRAPHQL_API_URL" \
        -H "Content-Type: application/json" \
	-H "x-hasura-admin-secret: hasura" \
        -d "$json_payload")
    echo "$response"
}

# Function to add a new location via GraphQL
add_location() {
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    # First try to find existing location
    local existing_query="query { Locations(where: {name: {_eq: \"New EVerst\"}}) { id name address } }"
    echo "Checking for existing location..." >&2
    local existing_response=$(execute_graphql "$existing_query")
    local existing_id=$(echo "$existing_response" | jq -r '.data.Locations[0].id // empty')
    
    if [ -n "$existing_id" ]; then
        echo "Found existing location with ID: $existing_id" >&2
        echo "$existing_id"
        return
    fi
    
    local query="mutation { insert_Locations_one(object: { name: \"New EVerst\", address: \"123 EV Station Rd\", city: \"Electric City\", state: \"NY\", country: \"USA\", postalCode: \"10001\", createdAt: \"$timestamp\", updatedAt: \"$timestamp\" }) { id name address } }"
    
    echo "Adding a new location via GraphQL..." >&2
    local response=$(execute_graphql "$query")
    echo "Location response: $response" >&2
    
    local location_id=$(echo "$response" | jq -r '.data.insert_Locations_one.id')
    echo "$location_id"
}

# Function to add a charging station via GraphQL
add_charging_station() {
    local location_id="$1"
    local chargepointId="$2"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    # First try to find existing charging station
    local existing_query="query { ChargingStations(where: {id: {_eq: \"$chargepointId\"}}) { id locationId chargePointVendor } }"
    echo "Checking for existing charging station..." >&2
    local existing_response=$(execute_graphql "$existing_query")
    local existing_station=$(echo "$existing_response" | jq -r '.data.ChargingStations[0].id // empty')
    
    if [ -n "$existing_station" ]; then
        echo "Found existing charging station with ID: $existing_station" >&2
        return
    fi
    
    local query="mutation { insert_ChargingStations_one(object: { id: \"$chargepointId\", locationId: $location_id, chargePointVendor: \"EVerest\", chargePointModel: \"Demo Station\", protocol: \"OCPP2.0.1\", createdAt: \"$timestamp\", updatedAt: \"$timestamp\" }) { id locationId chargePointVendor } }"
    
    echo "Adding charging station via GraphQL..." >&2
    local response=$(execute_graphql "$query")
    echo "Charging station response: $response" >&2
}

# Function to update SP1 password (same as original - uses different API)
add_cp_password() {
    local response
    local success=false
    local attempt=1
    local passwordString=$1

    until $success; do
        echo "Attempt $attempt: Updating SP1 password..."
        response=$(curl -s -o /dev/null -w "%{http_code}" --location --request PUT "http://${SERVER_ID}:8080/data/monitoring/variableAttribute?stationId=${CHARGEPOINT_ID}&setOnCharger=true" \
            --header "Content-Type: application/json" \
            --data-raw '{
                "component": {
                    "name": "SecurityCtrlr"
                },
                "variable": {
                    "name": "BasicAuthPassword"
                },
                "variableAttribute": [
                    {
                        "value": "'"$passwordString"'"
                    }
                ],
                "variableCharacteristics": {
                    "dataType": "passwordString",
                    "supportsMonitoring": false
                }
            }')

        if [[ $response -ge 200 && $response -lt 300 ]]; then
            echo "Password update successful."
            success=true
        else
            echo "Password update failed with HTTP status: $response. Retrying in 2 seconds..."
            sleep 2
            ((attempt++))
        fi
    done
}

# Main script execution
echo "Starting GraphQL-based setup..."

echo "Adding a new location..."
LOCATION_ID=$(add_location)

if [ -z "$LOCATION_ID" ] || [ "$LOCATION_ID" = "null" ]; then
    echo "Failed to add new location."
    exit 1
fi

echo "Location ID: $LOCATION_ID"

echo "Adding new charging station..."
add_charging_station "$LOCATION_ID" "$CHARGEPOINT_ID"

echo "Adding $CHARGEPOINT_ID password to citrine..."
add_cp_password "$CP_PASSWORD"

echo "CP Setup completed successfully!" 
