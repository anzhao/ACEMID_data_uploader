#!/bin/bash
# Make the script executable with: chmod +x open_security_pr.sh

# open_security_pr.sh - Script to create a pull request for security fixes
# This script uses the fix_issue.sh script to create a branch and push changes

# Load utility scripts
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils/logging.sh"

# Initialize logging
LOG_FILE="${LOG_FILE:-/var/log/security_pr.log}"
init_logging "$LOG_FILE"

log_info "Starting security pull request creation process"

# Issue ID for the security fixes
ISSUE_ID="security-fixes"

# Commit message for the security fixes
COMMIT_MSG="Fix security issues in repository

This pull request addresses several security issues:
- Secure credential management
- Input validation and sanitization
- Secure network communication
- PHI protection
- Secure file operations
- Comprehensive logging
- Docker security enhancements

See SECURITY_REPORT.md for details."

# Create a branch and push changes using fix_issue.sh
log_info "Creating branch and pushing changes"
"$SCRIPT_DIR/fix_issue.sh" "$ISSUE_ID" "$COMMIT_MSG"

if [ $? -ne 0 ]; then
  log_error "Failed to create branch and push changes"
  echo "Error: Failed to create branch and push changes."
  exit 1
fi

log_info "Security pull request creation process completed"
echo "Security pull request branch created. Please go to GitHub to create the pull request."
echo "Branch name: fix/$ISSUE_ID"