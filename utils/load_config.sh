#!/bin/bash

# load_config.sh - Securely load configuration from .env file
# Usage: source utils/load_config.sh

# Default config file location
CONFIG_FILE="${CONFIG_FILE:-/workspace/config/.env}"

# Function to load configuration
load_config() {
    local config_file="$1"
    
    # Check if config file exists
    if [ ! -f "$config_file" ]; then
        echo "Error: Configuration file not found at $config_file" >&2
        echo "Please copy config/.env.template to $config_file and update with your settings" >&2
        return 1
    fi
    
    # Check file permissions (should be 600 or 400)
    local file_perms=$(stat -c "%a" "$config_file")
    if [[ "$file_perms" != "600" && "$file_perms" != "400" ]]; then
        echo "Warning: Insecure permissions on $config_file. Setting to 600." >&2
        chmod 600 "$config_file"
    fi
    
    # Load the configuration
    set -a
    source "$config_file"
    set +a
    
    # Validate required configuration
    if [ -z "$XNAT_URL" ]; then
        echo "Error: XNAT_URL not set in $config_file" >&2
        return 1
    fi
    
    if [ -z "$XNAT_USERNAME" ]; then
        echo "Error: XNAT_USERNAME not set in $config_file" >&2
        return 1
    fi
    
    if [ -z "$XNAT_PASSWORD" ]; then
        echo "Error: XNAT_PASSWORD not set in $config_file" >&2
        return 1
    fi
    
    if [ -z "$XNAT_PROJECT_ID" ]; then
        echo "Error: XNAT_PROJECT_ID not set in $config_file" >&2
        return 1
    fi
    
    # Ensure XNAT_URL uses HTTPS
    if [[ ! "$XNAT_URL" =~ ^https:// ]]; then
        echo "Error: XNAT_URL must use HTTPS for secure communication" >&2
        return 1
    fi
    
    # Set default values for optional settings
    STRICT_CERT_VALIDATION="${STRICT_CERT_VALIDATION:-1}"
    DEBUG_LOGGING="${DEBUG_LOGGING:-0}"
    CONNECTION_TIMEOUT="${CONNECTION_TIMEOUT:-30}"
    
    return 0
}

# Load the configuration
load_config "$CONFIG_FILE"