#!/bin/bash

# This script wraps around the 'task' command to integrate with Git
# It should be placed in your PATH and named something like 'gtask' 
# to avoid conflicts with the original task command

# Path to your task data directory (where the .git repository is)
TASK_DATA_DIR="$HOME/.task"

# Make sure the task data directory exists and is a git repository
if [ ! -d "$TASK_DATA_DIR/.git" ]; then
  echo "Error: $TASK_DATA_DIR is not a git repository."
  echo "Please run: cd $TASK_DATA_DIR && git init && git add . && git commit -m 'Initial commit'"
  exit 1
fi

# Change to the task data directory
cd "$TASK_DATA_DIR" || { echo "Error: Could not change to $TASK_DATA_DIR"; exit 1; }

# Function to pull from GitHub
pull_from_github() {
  echo "Pulling latest changes from GitHub..."
  git pull origin "$(git rev-parse --abbrev-ref HEAD)" 2>/dev/null || 
    echo "Warning: Could not pull from remote. Is the repository set up with a remote?"
}

# Function to commit and push changes
commit_and_push() {
  local action="$1"
  shift
  local args="$*"
  
  echo "Committing changes..."
  git add .
  git commit -m "task $action: $args" || echo "Warning: Nothing to commit"
  
  echo "Pushing changes to GitHub..."
  git push origin "$(git rev-parse --abbrev-ref HEAD)" 2>/dev/null || 
    echo "Warning: Could not push to remote. Is the repository set up with a remote?"
}

# Main script logic
case "$1" in
  "add"|"done"|"delete")
    action="$1"
    shift
    
    # Run the original task command with all arguments
    /usr/bin/task "$action" "$@"
    
    # Commit and push changes
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
