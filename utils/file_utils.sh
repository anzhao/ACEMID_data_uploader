#!/bin/bash

# file_utils.sh - Functions for secure file operations
# Usage: source utils/file_utils.sh

# Create a secure temporary file
create_secure_temp_file() {
    local prefix="${1:-temp}"
    local temp_file
    
    # Create a temporary file with secure permissions
    temp_file=$(mktemp "/tmp/${prefix}.XXXXXX")
    if [ $? -ne 0 ]; then
        echo "Error: Failed to create temporary file" >&2
        return 1
    fi
    
    # Set secure permissions
    chmod 600 "$temp_file"
    
    echo "$temp_file"
    return 0
}

# Create a secure temporary directory
create_secure_temp_dir() {
    local prefix="${1:-temp_dir}"
    local temp_dir
    
    # Create a temporary directory with secure permissions
    temp_dir=$(mktemp -d "/tmp/${prefix}.XXXXXX")
    if [ $? -ne 0 ]; then
        echo "Error: Failed to create temporary directory" >&2
        return 1
    fi
    
    # Set secure permissions
    chmod 700 "$temp_dir"
    
    echo "$temp_dir"
    return 0
}

# Securely remove a file
secure_remove() {
    local file_path="$1"
    
    if [ -f "$file_path" ]; then
        # Overwrite the file with random data before removing
        dd if=/dev/urandom of="$file_path" bs=1k count=1 conv=notrunc >/dev/null 2>&1
        rm -f "$file_path"
    fi
    
    return 0
}

# Create a directory with secure permissions
create_secure_dir() {
    local dir_path="$1"
    
    mkdir -p "$dir_path"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to create directory: $dir_path" >&2
        return 1
    fi
    
    # Set secure permissions
    chmod 700 "$dir_path"
    
    return 0
}

# Check if a path contains symbolic links
check_for_symlinks() {
    local path="$1"
    
    if [ -L "$path" ]; then
        echo "Warning: Path is a symbolic link: $path" >&2
        return 1
    fi
    
    return 0
}

# Validate and sanitize a file path
validate_file_path() {
    local file_path="$1"
    local base_dir="${2:-$(pwd)}"
    
    # Resolve the absolute path
    local abs_path=$(realpath -m --no-symlinks "$file_path" 2>/dev/null)
    if [ $? -ne 0 ]; then
        echo "Error: Invalid file path: $file_path" >&2
        return 1
    fi
    
    # Check if the path is within the base directory
    local abs_base=$(realpath -m --no-symlinks "$base_dir")
    if [[ ! "$abs_path" =~ ^"$abs_base" ]]; then
        echo "Error: Path traversal attempt detected: $file_path" >&2
        return 1
    fi
    
    echo "$abs_path"
    return 0
}