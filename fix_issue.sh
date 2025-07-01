#!/bin/bash

# fix_issue.sh - Script for creating fix branches
# This script has been updated with security improvements

# Load utility scripts
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils/input_validation.sh"
source "$SCRIPT_DIR/utils/logging.sh"

# Initialize logging
LOG_FILE="${LOG_FILE:-/var/log/fix_issue.log}"
init_logging "$LOG_FILE"

log_info "Starting fix issue process"

# Check if required arguments are provided
if [ $# -lt 2 ]; then
  log_error "Insufficient arguments provided"
  echo "Usage: ./fix_issue.sh <issue-id> \"<commit-message>\""
  echo "Example: ./fix_issue.sh security-123 \"Fix login error\""
  exit 1
fi

ISSUE_ID="$1"
COMMIT_MSG="$2"

# Validate inputs
if ! validate_not_empty "$ISSUE_ID" "Issue ID"; then
  log_error "Empty issue ID provided"
  echo "Error: Issue ID cannot be empty"
  exit 1
fi

if ! validate_not_empty "$COMMIT_MSG" "Commit message"; then
  log_error "Empty commit message provided"
  echo "Error: Commit message cannot be empty"
  exit 1
fi

# Sanitize inputs to prevent command injection
ISSUE_ID=$(echo "$ISSUE_ID" | tr -cd 'a-zA-Z0-9-_')
if [ "$ISSUE_ID" != "$1" ]; then
  log_warning "Issue ID contained invalid characters and was sanitized"
  echo "Warning: Issue ID contained invalid characters and was sanitized to: $ISSUE_ID"
fi

# Create branch name
BRANCH_NAME="fix/$ISSUE_ID"
log_info "Creating branch: $BRANCH_NAME"

# Check if repo is initialized
if [ ! -d .git ]; then
  log_error "Not a Git repository"
  echo "This is not a Git repository. Please run this script inside a cloned repo."
  exit 1
fi

# Check if there are any changes to commit
if git diff --quiet && git diff --staged --quiet; then
  log_warning "No changes to commit"
  echo "Warning: There are no changes to commit. Make your changes first."
  exit 1
fi

# Create and switch to new branch
log_info "Creating and switching to branch: $BRANCH_NAME"
if ! git checkout -b "$BRANCH_NAME"; then
  log_error "Failed to create branch: $BRANCH_NAME"
  echo "Error: Failed to create branch. The branch may already exist."
  exit 1
fi

# Stage all changes
log_info "Staging changes"
git add .

# Commit with message
log_info "Committing changes with message: $COMMIT_MSG"
if ! git commit -m "$COMMIT_MSG"; then
  log_error "Failed to commit changes"
  echo "Error: Failed to commit changes."
  exit 1
fi

# Push to origin
log_info "Pushing branch to origin"
if ! git push origin "$BRANCH_NAME"; then
  log_error "Failed to push branch to origin"
  echo "Error: Failed to push branch to origin. Check your permissions."
  exit 1
fi

log_info "Branch '$BRANCH_NAME' pushed successfully"
echo "Branch '$BRANCH_NAME' pushed. Now go to GitHub to create a pull request."

# Log the security event
log_security "Fix branch created and pushed: $BRANCH_NAME, Commit message: $COMMIT_MSG"
