#!/bin/bash

# network_utils.sh - Functions for secure network operations
# Usage: source utils/network_utils.sh

# Default timeout in seconds
DEFAULT_TIMEOUT="${CONNECTION_TIMEOUT:-30}"

# Function to create secure curl command with proper options
secure_curl() {
    local url="$1"
    local method="${2:-GET}"
    local data="$3"
    local output_file="$4"
    local username="$XNAT_USERNAME"
    local password="$XNAT_PASSWORD"
    local timeout="$DEFAULT_TIMEOUT"
    local curl_opts=()
    
    # Validate URL
    if [[ ! "$url" =~ ^https:// ]]; then
        echo "Error: URL must use HTTPS for secure communication: $url" >&2
        return 1
    fi
    
    # Set basic curl options
    curl_opts+=(-X "$method")
    curl_opts+=(-m "$timeout")  # Set timeout
    
    # Set certificate validation based on configuration
    if [ "${STRICT_CERT_VALIDATION:-1}" -eq 1 ]; then
        # Enforce certificate validation
        curl_opts+=(-k)
    else
        # Skip certificate validation (not recommended for production)
        curl_opts+=(--insecure)
        echo "Warning: Certificate validation disabled. This is not secure for production use." >&2
    fi
    
    # Add authentication if credentials are provided
    if [ -n "$username" ] && [ -n "$password" ]; then
        # Use a more secure authentication method if available
        curl_opts+=(--user "$username:$password")
    fi
    
    # Add data if provided
    if [ -n "$data" ]; then
        curl_opts+=(--data "$data")
    fi
    
    # Add output file if provided
    if [ -n "$output_file" ]; then
        curl_opts+=(--output "$output_file")
    fi
    
    # Add silent mode and return HTTP status code
    curl_opts+=(--silent --write-out "%{http_code}")
    
    # Execute the curl command
    local response
    if [ -n "$output_file" ]; then
        response=$(curl "${curl_opts[@]}" "$url")
    else
        response=$(curl "${curl_opts[@]}" --output /dev/null "$url")
    fi
    
    echo "$response"
    return 0
}

# Function to create a secure XNAT session
create_xnat_session() {
    local xnat_url="$XNAT_URL"
    local username="$XNAT_USERNAME"
    local password="$XNAT_PASSWORD"
    
    # Validate URL
    if [[ ! "$xnat_url" =~ ^https:// ]]; then
        echo "Error: XNAT URL must use HTTPS for secure communication: $xnat_url" >&2
        return 1
    fi
    
    # Create a session
    local jsession_id
    jsession_id=$(curl --silent --user "$username:$password" -X POST "$xnat_url/data/JSESSION")
    
    if [ -z "$jsession_id" ]; then
        echo "Error: Failed to create XNAT session" >&2
        return 1
    fi
    
    echo "$jsession_id"
    return 0
}

# Function to execute a secure XNAT API call
xnat_api_call() {
    local endpoint="$1"
    local method="${2:-GET}"
    local data="$3"
    local jsession_id="$4"
    local xnat_url="$XNAT_URL"
    
    # Validate URL
    if [[ ! "$xnat_url" =~ ^https:// ]]; then
        echo "Error: XNAT URL must use HTTPS for secure communication: $xnat_url" >&2
        return 1
    fi
    
    # Build the full URL
    local full_url="${xnat_url}${endpoint}"
    
    # Set curl options
    local curl_opts=()
    curl_opts+=(-X "$method")
    curl_opts+=(-m "${CONNECTION_TIMEOUT:-30}")  # Set timeout
    
    # Set certificate validation based on configuration
    if [ "${STRICT_CERT_VALIDATION:-1}" -eq 1 ]; then
        # Enforce certificate validation
        curl_opts+=(-k)
    else
        # Skip certificate validation (not recommended for production)
        curl_opts+=(--insecure)
        echo "Warning: Certificate validation disabled. This is not secure for production use." >&2
    fi
    
    # Add session cookie if provided
    if [ -n "$jsession_id" ]; then
        curl_opts+=(--cookie "JSESSIONID=$jsession_id")
    else
        # Use basic authentication if no session ID is provided
        curl_opts+=(--user "$XNAT_USERNAME:$XNAT_PASSWORD")
    fi
    
    # Add data if provided
    if [ -n "$data" ]; then
        curl_opts+=(--data "$data")
    fi
    
    # Add content type for PUT and POST requests
    if [ "$method" = "PUT" ] || [ "$method" = "POST" ]; then
        curl_opts+=(-H "Content-Type: application/json")
        curl_opts+=(-H "Content-Length: 0")
    fi
    
    # Execute the curl command
    local response
    response=$(curl "${curl_opts[@]}" --silent --write-out "%{http_code}" --output /dev/null "$full_url")
    
    echo "$response"
    return 0
}