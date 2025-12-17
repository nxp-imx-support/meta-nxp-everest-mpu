#!/usr/bin/env bash

# Check for required arguments
if [ "$#" -ne 3 ]; then
       echo "Usage: $0 <CSMS IP/Hostname> <ID_TOKEN> <TOKEN_TYPE Local/ISO14443>"
       exit 1
fi

# Assign input arguments
# 046A1A52645780 Local
# 041614220C5980 Local
ID_TOKEN="$2"
ID_TOKEN_TYPE="$3"
SERVER_ID="$1"
# Configuration
GRAPHQL_API_URL="http://${SERVER_ID}:8090/v1/graphql"

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

# Function to add RFID token via GraphQL
add_rfid_token() {
    local idToken="$1"
    local idTokenType="$2"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    # First try to find existing token
    local existing_query="query { IdTokens(where: {idToken: {_eq: \"$idToken\"}, type: {_eq: \"$idTokenType\"}}) { id idToken type } }"
    echo "Checking for existing RFID token..." >&2
    local existing_response=$(execute_graphql "$existing_query")
    local existing_id=$(echo "$existing_response" | jq -r '.data.IdTokens[0].id // empty')
    
    if [ -n "$existing_id" ]; then
        echo "Found existing RFID token with ID: $existing_id" >&2
        echo "$existing_id"
        return
    fi
    
    local query="mutation { insert_IdTokens_one(object: { idToken: \"$idToken\", type: \"$idTokenType\", createdAt: \"$timestamp\", updatedAt: \"$timestamp\" }) { id idToken type } }"
    
    echo "Adding RFID token via GraphQL..." >&2
    local response=$(execute_graphql "$query")
    echo "RFID token response: $response" >&2
    
    local token_id=$(echo "$response" | jq -r '.data.insert_IdTokens_one.id')
    echo "$token_id"
}

# Function to add authorization for RFID token via GraphQL
add_authorization() {
    local token_id="$1"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    # First try to find existing authorization
    local existing_query="query { Authorizations(where: {idTokenId: {_eq: $token_id}}) { id idTokenId } }"
    echo "Checking for existing authorization..." >&2
    local existing_response=$(execute_graphql "$existing_query")
    local existing_auth=$(echo "$existing_response" | jq -r '.data.Authorizations[0].id // empty')
    
    if [ -n "$existing_auth" ]; then
        echo "Found existing authorization with ID: $existing_auth" >&2
        return
    fi
    
    local query="mutation { insert_Authorizations_one(object: { idTokenId: $token_id, createdAt: \"$timestamp\", updatedAt: \"$timestamp\" }) { id idTokenId } }"
    
    echo "Adding authorization via GraphQL..." >&2
    local response=$(execute_graphql "$query")
    echo "Authorization response: $response" >&2
}

# Function to add new ev driver authorization information (same as original - uses different API)
add_evdriver_authorization() {
    local response
    local success=false
    local attempt=1
    local idToken=$1
    local idTokenType=$2

    until $success; do
        echo "Attempt $attempt: Adding ev driver authorization..."
        response=$(curl -s -o /dev/null -w "%{http_code}" --location --request PUT "http://${SERVER_ID}:8080/data/evdriver/authorization?idToken=${idToken}&type=${idTokenType}" \
            --header "Content-Type: application/json" \
            --data-raw '{
               "idToken": {
                   "idToken": "'"$idToken"'",
                   "type": "'"$idTokenType"'"
               },
               "idTokenInfo": {
                   "status": "Accepted"
               }
           }')

        if [[ $response -ge 200 && $response -lt 300 ]]; then
            echo "Authorization update successful."
            success=true
        else
            echo "Authorization update failed with HTTP status: $response. Retrying in 2 seconds..."
            sleep 2
            ((attempt++))
        fi
    done
}


##########################################
# Main script execution


echo "Starting GraphQL-based setup..."

# If sourced, skip argument parsing and just run the setup
echo "Adding RFID token..."
TOKEN_ID=$(add_rfid_token "$ID_TOKEN" "$ID_TOKEN_TYPE")

if [ -z "$TOKEN_ID" ] || [ "$TOKEN_ID" = "null" ]; then
    echo "Failed to add RFID token."
    exit 1
fi

echo "Token ID: $TOKEN_ID"

echo "Adding authorization for RFID token..."
add_authorization "$TOKEN_ID"

echo "Adding ev driver rfid authorization to citrine..."
add_evdriver_authorization "$ID_TOKEN" "$ID_TOKEN_TYPE"

echo "RFID Setup completed successfully!" 
