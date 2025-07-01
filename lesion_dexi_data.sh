#!/bin/bash

# lesion_dexi_data.sh - Script for collecting lesion and Dexi data
# This script has been updated with security improvements

# Load utility scripts
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils/input_validation.sh"
source "$SCRIPT_DIR/utils/file_utils.sh"
source "$SCRIPT_DIR/utils/logging.sh"

# Initialize logging
LOG_FILE="${LOG_FILE:-/var/log/lesion_dexi_data.log}"
init_logging "$LOG_FILE"

log_info "Starting lesion and Dexi data collection process"

# Check if destination directory is provided
if [ -z "$1" ]; then
  log_info "No destination directory provided, using default"
  destination_dir="dermoscopy_data_folder"
else
  destination_dir="$1"
  log_info "Using provided destination directory: $destination_dir"
fi

# Create the destination directory with secure permissions
log_info "Creating destination directory: $destination_dir"
create_secure_dir "$destination_dir"

# Find all files matching the pattern 'lesion_data_*.json'
log_info "Searching for lesion data JSON files"
find_count=0
find . -type f -name 'lesion_data_*.json' | while read -r file; do
    # Validate the file path
    validated_file=$(validate_file_path "$file")
    if [ $? -ne 0 ]; then
        log_error "Invalid file path: $file"
        continue
    fi
    
    # Get the immediate parent directory name
    parent_dir=$(basename "$(dirname "$validated_file")")
    
    # Check if the parent directory is 'analysis'
    if [ "$parent_dir" == "analysis" ]; then
        log_info "Processing lesion data file: $validated_file"
        
        # Create the destination directory structure
        dest_dir="$destination_dir/$(dirname "$validated_file")"
        create_secure_dir "$dest_dir"
        
        # Copy the file to the destination directory, preserving the directory structure
        cp "$validated_file" "$dest_dir/"
        if [ $? -eq 0 ]; then
            log_info "Copied $validated_file to $dest_dir/"
            echo "Copied $validated_file to $dest_dir/"
            find_count=$((find_count + 1))
        else
            log_error "Failed to copy $validated_file to $dest_dir/"
        fi
    fi
done

# Find all files in folders matching the pattern DexiData_*
log_info "Searching for DexiData files"
find . -type f -path '*/DexiData_*/*' | while read -r file; do
    # Validate the file path
    validated_file=$(validate_file_path "$file")
    if [ $? -ne 0 ]; then
        log_error "Invalid file path: $file"
        continue
    fi
    
    # Get the immediate parent directory name
    parent_dir=$(basename "$(dirname "$validated_file")")
    
    # Check if the parent directory starts with 'DexiData_' and is not exactly 'DexiData'
    if [[ "$parent_dir" == DexiData_* ]] && [[ "$parent_dir" != "DexiData" ]]; then
        log_info "Processing DexiData file: $validated_file"
        
        # Create the destination directory structure
        dest_dir="$destination_dir/$(dirname "$validated_file")"
        create_secure_dir "$dest_dir"
        
        # Copy the file to the destination directory, preserving the directory structure
        cp "$validated_file" "$dest_dir/"
        if [ $? -eq 0 ]; then
            log_info "Copied $validated_file to $dest_dir/"
            echo "Copied $validated_file to $dest_dir/"
            find_count=$((find_count + 1))
        else
            log_error "Failed to copy $validated_file to $dest_dir/"
        fi
    fi
done

# Set secure permissions on the destination directory
chmod -R 700 "$destination_dir"

log_info "Lesion and Dexi data collection completed. Files copied: $find_count"
echo "Lesion and Dexi data collection completed. Files copied: $find_count"
