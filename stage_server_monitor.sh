#!/bin/bash

# stage_server_monitor.sh - Script for monitoring stage server directory
# This script has been updated with security improvements

# Load utility scripts
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils/input_validation.sh"
source "$SCRIPT_DIR/utils/file_utils.sh"
source "$SCRIPT_DIR/utils/logging.sh"

# Initialize logging
LOG_FILE="${LOG_FILE:-/var/log/stage_server_monitor.log}"
init_logging "$LOG_FILE"

log_info "Starting stage server monitoring"

# Stage server directory to monitor
if [ -z "$1" ]; then
    WATCH_DIR="/path/to/stage/server/directory"
    log_warning "No watch directory provided, using default: $WATCH_DIR"
else
    WATCH_DIR="$1"
    log_info "Using provided watch directory: $WATCH_DIR"
fi

# Validate the watch directory
if ! validate_dir_exists "$WATCH_DIR" "Watch directory"; then
    log_error "Watch directory does not exist: $WATCH_DIR"
    echo "Error: Watch directory does not exist: $WATCH_DIR"
    exit 1
fi

# Check if the watch directory is a symlink
if [ -L "$WATCH_DIR" ]; then
    log_warning "Watch directory is a symbolic link: $WATCH_DIR"
    echo "Warning: Watch directory is a symbolic link. This may pose security risks."
fi

# Check if inotifywait is installed
if ! command -v inotifywait &> /dev/null; then
    log_error "inotifywait is not installed"
    echo "Error: inotifywait is not installed. Please install inotify-tools."
    exit 1
fi

log_info "Monitoring $WATCH_DIR for new files and directories"
echo "Monitoring $WATCH_DIR for new files and directories..."
echo "Logging to $LOG_FILE"

# Set up a trap to handle script termination
cleanup() {
    log_info "Stopping stage server monitoring"
    echo "Monitoring stopped."
    exit 0
}

trap cleanup SIGINT SIGTERM

# Start monitoring the stage server
inotifywait -m -e create --format '%w%f' "$WATCH_DIR" | while read -r NEW_ENTRY
do
    # Validate the new entry
    validated_entry=$(validate_file_path "$NEW_ENTRY" "$WATCH_DIR")
    if [ $? -ne 0 ]; then
        log_error "Invalid entry detected: $NEW_ENTRY"
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Invalid entry detected: $NEW_ENTRY" | tee -a "$LOG_FILE"
        continue
    fi
    
    # Check the type of the new entry
    if [ -d "$validated_entry" ]; then
        log_info "New directory detected: $validated_entry"
        echo "$(date '+%Y-%m-%d %H:%M:%S') - New directory detected: $validated_entry" | tee -a "$LOG_FILE"
        
        # Check for suspicious directory names
        dir_name=$(basename "$validated_entry")
        if [[ "$dir_name" == *"../"* || "$dir_name" == *"~"* || "$dir_name" == *"|"* || "$dir_name" == *";"* ]]; then
            log_warning "Suspicious directory name detected: $dir_name"
            echo "$(date '+%Y-%m-%d %H:%M:%S') - WARNING: Suspicious directory name detected: $dir_name" | tee -a "$LOG_FILE"
        fi
        
    elif [ -f "$validated_entry" ]; then
        log_info "New file detected: $validated_entry"
        echo "$(date '+%Y-%m-%d %H:%M:%S') - New file detected: $validated_entry" | tee -a "$LOG_FILE"
        
        # Check for suspicious file extensions
        file_ext="${validated_entry##*.}"
        if [[ "$file_ext" == "sh" || "$file_ext" == "exe" || "$file_ext" == "bat" || "$file_ext" == "cmd" ]]; then
            log_warning "Suspicious file extension detected: $file_ext"
            echo "$(date '+%Y-%m-%d %H:%M:%S') - WARNING: Suspicious file extension detected: $file_ext" | tee -a "$LOG_FILE"
        fi
        
    else
        log_warning "New item detected (unknown type): $validated_entry"
        echo "$(date '+%Y-%m-%d %H:%M:%S') - New item detected (unknown type): $validated_entry" | tee -a "$LOG_FILE"
    fi
done

log_info "Stage server monitoring stopped"
