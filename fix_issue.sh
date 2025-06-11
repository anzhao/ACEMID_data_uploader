#!/bin/bash

# Usage: ./fix_issue.sh your-issue "Fix login error"

ISSUE_ID=$1
COMMIT_MSG=$2
BRANCH_NAME="fix/$ISSUE_ID"

# Check if repo is initialized
if [ ! -d .git ]; then
  echo "This is not a Git repository. Please run this script inside a cloned repo."
  exit 1
fi

# Create and switch to new branch
git checkout -b $BRANCH_NAME

# Stage all changes
git add .

# Commit with message
git commit -m "$COMMIT_MSG"

# Push to origin
git push origin $BRANCH_NAME

echo "Branch '$BRANCH_NAME' pushed. Now go to GitHub to create a pull request."
