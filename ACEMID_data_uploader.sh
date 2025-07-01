#!/bin/bash

# ACEMID_data_uploader.sh - Script for uploading ACEMID data to XNAT
# This script has been updated with security improvements

# Load utility scripts
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils/load_config.sh"
source "$SCRIPT_DIR/utils/input_validation.sh"
source "$SCRIPT_DIR/utils/file_utils.sh"
source "$SCRIPT_DIR/utils/logging.sh"
source "$SCRIPT_DIR/utils/network_utils.sh"

# Initialize logging
LOG_FILE="${LOG_FILE:-/var/log/acemid_uploader.log}"
init_logging "$LOG_FILE"

log_info "Starting ACEMID data upload process"

# Create XNAT session
log_info "Creating XNAT session"
JS_ID=$(create_xnat_session)
if [ $? -ne 0 ] || [ -z "$JS_ID" ]; then
    log_error "Failed to create XNAT session"
    echo "Error: Failed to create XNAT session. Check your credentials and XNAT URL."
    exit 1
fi

log_info "XNAT session created successfully"
log_debug "JSESSION_ID is $JS_ID"
echo "JSESSION_ID is $JS_ID"

# Create the "error" directory with secure permissions
log_info "Creating error directory"
create_secure_dir "error"

# Loop through all .db files in the current directory
log_info "Processing .db files"
for file in *.db; do
    # Check if the file exists and is a regular file
    if [[ -f "$file" && ! -L "$file" ]]; then
        log_info "Processing file: $file"
        
        # Validate the file path
        validated_file=$(validate_file_path "$file")
        if [ $? -ne 0 ]; then
            log_error "Invalid file path: $file"
            continue
        fi
        
        # Extract the filename without the extension
        filename=$(basename "$validated_file" .db)
        
        # Extract the part before and after the underscore
        before_underscore=${filename%%_*}
        after_underscore=${filename#*_}
        
        # Check if the part before the underscore is empty
        if [[ -z "$before_underscore" ]]; then
            log_warning "Empty part before underscore in filename: $file"
            
            # Move the file to the "error" directory
            mv "$validated_file" error/
            log_info "Moved $file to error/ directory due to empty part before underscore"
            echo "Moved $file to error/ directory due to empty part before underscore."
            
            # Check if the after_underscore directory exists
            if [ -d "$after_underscore" ] && [ ! -L "$after_underscore" ]; then
                # Move the folder to "error" directory
                mv "$after_underscore" error/
                log_info "Moved directory $after_underscore to error/ directory"
            fi
        else
            # Log and print the results
            log_info "File: $file"
            log_info "Before underscore: $before_underscore"
            log_info "After underscore: $after_underscore"
            echo "File: $file"
            echo "Before underscore: $before_underscore"
            echo "After underscore: $after_underscore"

            # Validate the after_underscore directory
            if [ ! -d "$after_underscore" ] || [ -L "$after_underscore" ]; then
                log_error "Directory $after_underscore does not exist or is a symlink"
                continue
            fi

            # Create a secure temporary directory
            TEMP_DIR=$(create_secure_temp_dir "temp_$filename")
            log_debug "Created temporary directory: $TEMP_DIR"
            
            # Copy data to the temporary directory
            cp -r "$after_underscore" "$TEMP_DIR/"
            log_debug "Copied data to temporary directory"

            # Loop through all items in the after_underscore directory
            for dir in "$after_underscore"/*/ ; do
                # Check if the item is a directory and not a symlink
                if [ -d "$dir" ] && [ ! -L "$dir" ]; then
                    # Remove the trailing slash from the directory name
                    dir_name=$(basename "$dir")
                    log_info "Processing directory: $dir_name"
                    
                    # Create a zip file for the directory
                    log_debug "Creating zip file for directory: $dir_name"
                    zip -r "${dir_name}.zip" "$dir"
                    
                    # Validate the zip file was created
                    if [ ! -f "${dir_name}.zip" ]; then
                        log_error "Failed to create zip file for directory: $dir_name"
                        continue
                    fi
                    
                    # Move the zip file into the original directory
                    log_debug "Moving zip file to directory: $dir"
                    mv "${dir_name}.zip" "$dir"
                    
                    # Remove all files and folders in the original directory except the zip file
                    log_debug "Removing original files after zipping: $dir"
                    find "$dir" -mindepth 1 ! -name "${dir_name}.zip" -exec rm -rf {} \;
                fi
            done

            # Loop through all zip files in the current directory and its subdirectories
            log_info "Processing zip files in $after_underscore"
            find "$after_underscore" -type f -name "*.zip" | while read -r FILENAME; do
                # Validate the file path
                validated_zip=$(validate_file_path "$FILENAME")
                if [ $? -ne 0 ]; then
                    log_error "Invalid zip file path: $FILENAME"
                    continue
                fi
                
                log_info "Processing zip file: $validated_zip"
                echo "Filename: $validated_zip"

                # Use before_underscore as SUBJECT_ID
                SUBJECT_ID=$before_underscore
                SESSION_ID=$(echo "$validated_zip" | cut -d'/' -f2)
                SCAN_ID=$(echo "$validated_zip" | cut -d'/' -f3 | cut -d'.' -f1)

                # Validate IDs
                if ! validate_not_empty "$SUBJECT_ID" "Subject ID"; then
                    log_error "Empty Subject ID"
                    continue
                fi
                
                if ! validate_not_empty "$SESSION_ID" "Session ID"; then
                    log_error "Empty Session ID"
                    continue
                fi
                
                if ! validate_not_empty "$SCAN_ID" "Scan ID"; then
                    log_error "Empty Scan ID"
                    continue
                fi

                # Subject label and session label can be the same as their IDs or customized
                SUBJECT_LABEL=$SUBJECT_ID
                SESSION_LABEL=$SESSION_ID
                log_info "Subject ID: $SUBJECT_ID"
                log_info "Session ID: $SESSION_ID"
                log_info "Scan ID: $SCAN_ID"
                echo "Subject ID: $SUBJECT_ID"
                echo "Session ID: $SESSION_ID"
                echo "Scan ID: $SCAN_ID"

                # Check if the session already exists
                log_debug "Checking if session $SESSION_ID already exists"
                RESPONSE=$(xnat_api_call "/data/archive/projects/$XNAT_PROJECT_ID/subjects/$SUBJECT_ID/experiments/$SESSION_ID" "GET" "" "$JS_ID")
                
                if [ "$RESPONSE" -eq 200 ]; then
                    log_info "Session $SESSION_ID already exists. Skipping creation."
                    echo "Session $SESSION_ID already exists. Skipping creation."
                else
                    # Create a subject
                    log_info "Creating subject: $SUBJECT_ID"
                    RESPONSE=$(xnat_api_call "/data/archive/projects/$XNAT_PROJECT_ID/subjects/$SUBJECT_ID?label=$SUBJECT_LABEL" "PUT" "" "$JS_ID")
                    
                    if [ "$RESPONSE" -ne 200 ] && [ "$RESPONSE" -ne 201 ]; then
                        log_error "Failed to create subject. HTTP response code: $RESPONSE"
                        echo "Failed to create subject. HTTP response code: $RESPONSE"
                        continue
                    fi

                    # Create a session (experiment) with session type
                    SESSION_TYPE="xnat:xcSessionData"  # Replace with the correct session type
                    log_info "Creating session: ${SESSION_ID}_single_zip"
                    RESPONSE=$(xnat_api_call "/data/archive/projects/$XNAT_PROJECT_ID/subjects/$SUBJECT_ID/experiments/$SESSION_ID?xsiType=$SESSION_TYPE&label=${SESSION_LABEL}_single_zip" "PUT" "" "$JS_ID")
                    
                    if [ "$RESPONSE" -ne 200 ] && [ "$RESPONSE" -ne 201 ]; then
                        log_error "Failed to create session ${SESSION_ID}_single_zip. HTTP response code: $RESPONSE"
                        echo "Failed to create session ${SESSION_ID}_single_zip. HTTP response code: $RESPONSE"
                        continue
                    fi
                    
                    log_info "Creating session: ${SESSION_ID}_loose_files"
                    RESPONSE=$(xnat_api_call "/data/archive/projects/$XNAT_PROJECT_ID/subjects/$SUBJECT_ID/experiments/$SESSION_ID?xsiType=$SESSION_TYPE&label=${SESSION_LABEL}_loose_files" "PUT" "" "$JS_ID")

                    # Check if the session creation was successful
                    if [ "$RESPONSE" -eq 200 ] || [ "$RESPONSE" -eq 201 ]; then
                        log_info "Session created successfully."
                        echo "Session created successfully."
                    else
                        log_error "Failed to create session ${SESSION_ID}_loose_files. HTTP response code: $RESPONSE"
                        echo "Failed to create session ${SESSION_ID}_loose_files. HTTP response code: $RESPONSE"
                        continue
                    fi
                fi

                # Create a scan
                SCAN_TYPE="xnat:xcScanData"  # Replace with the correct scan type
                log_info "Creating scan: $SCAN_ID for session ${SESSION_ID}_single_zip"
                RESPONSE=$(xnat_api_call "/data/archive/projects/$XNAT_PROJECT_ID/subjects/$SUBJECT_ID/experiments/${SESSION_ID}_single_zip/scans/$SCAN_ID?xsiType=$SCAN_TYPE" "PUT" "" "$JS_ID")
                
                if [ "$RESPONSE" -ne 200 ] && [ "$RESPONSE" -ne 201 ]; then
                    log_error "Failed to create scan for ${SESSION_ID}_single_zip. HTTP response code: $RESPONSE"
                    echo "Failed to create scan for ${SESSION_ID}_single_zip. HTTP response code: $RESPONSE"
                    continue
                fi
                
                log_info "Creating scan: $SCAN_ID for session ${SESSION_ID}_loose_files"
                RESPONSE=$(xnat_api_call "/data/archive/projects/$XNAT_PROJECT_ID/subjects/$SUBJECT_ID/experiments/${SESSION_ID}_loose_files/scans/$SCAN_ID?xsiType=$SCAN_TYPE" "PUT" "" "$JS_ID")

                # Check if the scan creation was successful
                if [ "$RESPONSE" -eq 200 ] || [ "$RESPONSE" -eq 201 ]; then
                    log_info "Scan created successfully."
                    echo "Scan created successfully."
                else
                    log_error "Failed to create scan for ${SESSION_ID}_loose_files. HTTP response code: $RESPONSE"
                    echo "Failed to create scan for ${SESSION_ID}_loose_files. HTTP response code: $RESPONSE"
                    continue
                fi

                # Upload the single zip file
                log_info "Uploading single zip file: $validated_zip to ${SESSION_ID}_single_zip"
                curl --cookie JSESSIONID=$JS_ID -X PUT "$XNAT_URL/data/projects/$XNAT_PROJECT_ID/subjects/$SUBJECT_ID/experiments/${SESSION_ID}_single_zip/scans/$SCAN_ID/resources/RAW/files?extract=false" -F "file=@$validated_zip" &
                
                # Upload the extract content file
                log_info "Uploading zip file with extraction: $validated_zip to ${SESSION_ID}_loose_files"
                curl --cookie JSESSIONID=$JS_ID -X PUT "$XNAT_URL/data/projects/$XNAT_PROJECT_ID/subjects/$SUBJECT_ID/experiments/${SESSION_ID}_loose_files/scans/$SCAN_ID/resources/RAW/files?extract=true" -F "file=@$validated_zip" &
            done
        fi
    fi
done

log_info "ACEMID data upload process completed"
