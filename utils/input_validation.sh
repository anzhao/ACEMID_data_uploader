#!/bin/bash

# input_validation.sh - Functions for validating user input
# Usage: source utils/input_validation.sh

# Validate if a string is not empty
validate_not_empty() {
    local input="$1"
    local name="$2"
    
    if [ -z "$input" ]; then
        echo "Error: $name cannot be empty" >&2
        return 1
    fi
    
    return 0
}

# Validate if a file exists
validate_file_exists() {
    local file_path="$1"
    local name="${2:-File}"
    
    if [ ! -f "$file_path" ]; then
        echo "Error: $name does not exist at path: $file_path" >&2
        return 1
    fi
    
    return 0
}

# Validate if a directory exists
validate_dir_exists() {
    local dir_path="$1"
    local name="${2:-Directory}"
    
    if [ ! -d "$dir_path" ]; then
        echo "Error: $name does not exist at path: $dir_path" >&2
        return 1
    fi
    
    return 0
}

# Sanitize a file path to prevent directory traversal
sanitize_path() {
    local path="$1"
    
    # Remove any ".." components to prevent directory traversal
    local sanitized_path=$(realpath -m --no-symlinks "$path" 2>/dev/null)
    
    if [ $? -ne 0 ]; then
        echo "Error: Invalid path: $path" >&2
        return 1
    fi
    
    # Ensure the path is within the expected directory
    local base_dir=$(realpath -m --no-symlinks "$(pwd)")
    if [[ ! "$sanitized_path" =~ ^"$base_dir" ]]; then
        echo "Error: Path traversal attempt detected: $path" >&2
        return 1
    fi
    
    echo "$sanitized_path"
    return 0
}

# Validate a URL (basic validation)
validate_url() {
    local url="$1"
    local require_https="${2:-1}"
    
    # Check if URL is not empty
    if [ -z "$url" ]; then
        echo "Error: URL cannot be empty" >&2
        return 1
    fi
    
    # Check if URL starts with http:// or https://
    if [[ ! "$url" =~ ^https?:// ]]; then
        echo "Error: Invalid URL format: $url" >&2
        return 1
    fi
    
    # Check if HTTPS is required
    if [ "$require_https" -eq 1 ] && [[ ! "$url" =~ ^https:// ]]; then
        echo "Error: URL must use HTTPS for secure communication: $url" >&2
        return 1
    fi
    
    return 0
}

# Validate if input is a valid integer
validate_integer() {
    local input="$1"
    local name="$2"
    
    if ! [[ "$input" =~ ^[0-9]+$ ]]; then
        echo "Error: $name must be a valid integer" >&2
        return 1
    fi
    
    return 0
}