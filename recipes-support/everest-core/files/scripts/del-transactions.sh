#!/usr/bin/env bash

# Check for required arguments
if [ "$#" -ne 2 ]; then
       echo "Usage: $0 <CSMS IP/Hostname> <CHARGEPOINT_ID>"
       exit 1
fi

# Assign input arguments
SERVER_ID="$1"
CHARGEPOINT_ID="$2"
# Configuration
GRAPHQL_API_URL="http://${SERVER_ID}:8090/v1/graphql"

# Function to show usage
show_usage() {
    echo "  Usage: $0 <CSMS IP/Hostname> : Delete the tranctions data created by this script"
    exit 1
}

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

# Function to add authorization for RFID token via GraphQL
del_transactions() {
    local query="mutation { delete_Transactions(where: {stationId: {_eq: \"$CHARGEPOINT_ID\"}}) { affected_rows } }"
    local response=$(execute_graphql "$query")
    echo "del_transactions response: $response" >&2
}

# If sourced, skip argument parsing and just run the setup
del_transactions
