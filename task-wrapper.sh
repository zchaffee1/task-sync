#!/bin/bash

# This script wraps around the 'task' command to integrate with Git
# It should be placed in your PATH and named something like 'gtask' 
# to avoid conflicts with the original task command

# Path to your task data directory (where the .git repository is)
TASK_DATA_DIR="$HOME/.task"
TASK_LOG="$TASK_DATA_DIR/git_operations.log"

# Make sure the task data directory exists and is a git repository
if [ ! -d "$TASK_DATA_DIR/.git" ]; then
  echo "Error: $TASK_DATA_DIR is not a git repository." > /dev/stderr
  echo "Please run: cd $TASK_DATA_DIR && git init && git add . && git commit -m 'Initial commit'" > /dev/stderr
  exit 1
fi

# Change to the task data directory
cd "$TASK_DATA_DIR" || { echo "Error: Could not change to $TASK_DATA_DIR" > /dev/stderr; exit 1; }

# Function to pull from GitHub silently
pull_from_github() {
  # Try BatchMode first (avoids passphrase prompt)
  GIT_SSH_COMMAND="ssh -o BatchMode=yes -o StrictHostKeyChecking=no" git pull origin "$(git rev-parse --abbrev-ref HEAD)" >> "$TASK_LOG" 2>&1 || {
    # If BatchMode fails, use credential helper
    git config credential.helper 'cache --timeout=86400' >> "$TASK_LOG" 2>&1
    git pull origin "$(git rev-parse --abbrev-ref HEAD)" >> "$TASK_LOG" 2>&1 || 
    echo "Warning: Could not pull from remote." >> "$TASK_LOG" 2>&1
  }
}

# Function to commit and push changes silently
commit_and_push() {
  local action="$1"
  shift
  local args="$*"
  
  # Add and commit changes
  git add . >> "$TASK_LOG" 2>&1
  git commit -m "task $action: $args" >> "$TASK_LOG" 2>&1 || true
  
  # Try BatchMode first (avoids passphrase prompt)
  GIT_SSH_COMMAND="ssh -o BatchMode=yes -o StrictHostKeyChecking=no" git push origin "$(git rev-parse --abbrev-ref HEAD)" >> "$TASK_LOG" 2>&1 || {
    # If BatchMode fails, use credential helper
    git config credential.helper 'cache --timeout=86400' >> "$TASK_LOG" 2>&1
    git push origin "$(git rev-parse --abbrev-ref HEAD)" >> "$TASK_LOG" 2>&1 || 
    echo "Warning: Could not push to remote." >> "$TASK_LOG" 2>&1
  }
}

# Main script logic
case "$1" in
  "add"|"done"|"delete")
    action="$1"
    shift
    
    # Run the original task command with all arguments
    /usr/bin/task "$action" "$@"
    
    # Commit and push changes silently
    commit_and_push "$action" "$*"
    ;;
  "")
    # Just "task" with no arguments - pull first then run task
    pull_from_github
    /usr/bin/task
    ;;
  *)
    # Any other task command - just run it normally
    /usr/bin/task "$@"
    ;;
esac
