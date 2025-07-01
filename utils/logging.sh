#!/bin/bash

# logging.sh - Functions for secure logging
# Usage: source utils/logging.sh

# Default log file
LOG_FILE="${LOG_FILE:-/var/log/acemid_uploader.log}"

# Log levels
LOG_LEVEL_DEBUG=0
LOG_LEVEL_INFO=1
LOG_LEVEL_WARNING=2
LOG_LEVEL_ERROR=3

# Current log level (default: INFO)
CURRENT_LOG_LEVEL="${CURRENT_LOG_LEVEL:-1}"

# Initialize logging
init_logging() {
    local log_file="$1"
    
    # Set the log file if provided
    if [ -n "$log_file" ]; then
        LOG_FILE="$log_file"
    fi
    
    # Create the log directory if it doesn't exist
    local log_dir=$(dirname "$LOG_FILE")
    mkdir -p "$log_dir" 2>/dev/null
    
    # Check if the log file is writable
    if ! touch "$LOG_FILE" 2>/dev/null; then
        echo "Warning: Cannot write to log file $LOG_FILE. Logging to stdout instead." >&2
        LOG_FILE="/dev/stdout"
    fi
    
    # Set log level based on DEBUG_LOGGING
    if [ "${DEBUG_LOGGING:-0}" -eq 1 ]; then
        CURRENT_LOG_LEVEL=$LOG_LEVEL_DEBUG
    fi
    
    return 0
}

# Log a message with a specific level
log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local user="${USER:-unknown}"
    local pid=$$
    
    # Check if the message should be logged based on the current log level
    if [ "$level" -ge "$CURRENT_LOG_LEVEL" ]; then
        # Get the level name
        local level_name
        case "$level" in
            $LOG_LEVEL_DEBUG)
                level_name="DEBUG"
                ;;
            $LOG_LEVEL_INFO)
                level_name="INFO"
                ;;
            $LOG_LEVEL_WARNING)
                level_name="WARNING"
                ;;
            $LOG_LEVEL_ERROR)
                level_name="ERROR"
                ;;
            *)
                level_name="UNKNOWN"
                ;;
        esac
        
        # Log the message
        echo "[$timestamp] [$level_name] [$user] [$pid] $message" >> "$LOG_FILE"
    fi
    
    return 0
}

# Log a debug message
log_debug() {
    log_message $LOG_LEVEL_DEBUG "$1"
}

# Log an info message
log_info() {
    log_message $LOG_LEVEL_INFO "$1"
}

# Log a warning message
log_warning() {
    log_message $LOG_LEVEL_WARNING "$1"
}

# Log an error message
log_error() {
    log_message $LOG_LEVEL_ERROR "$1"
}

# Log a security event (always logged)
log_security() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local user="${USER:-unknown}"
    local pid=$$
    local ip=$(hostname -I 2>/dev/null || echo "unknown")
    
    echo "[$timestamp] [SECURITY] [$user] [$pid] [$ip] $message" >> "$LOG_FILE"
    
    return 0
}

# Initialize logging with default settings
init_logging