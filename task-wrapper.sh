#!/bin/bash

# Path to your task repository
TASK_REPO_PATH="$HOME/.task"  # Change this to your task repository path

# Change to the task repository directory
cd "$TASK_REPO_PATH" || { echo "Error: Task repository not found"; exit 1; }

# Function to pull from GitHub
pull_from_github() {
  echo "Pulling latest changes from GitHub..."
  git pull origin main || { echo "Error: Failed to pull from GitHub"; exit 1; }
}

# Function to commit and push changes
commit_and_push() {
  local action="$1"
  shift
  local args="$*"
  
  echo "Committing changes..."
  git add .
  git commit -m "$action: $args" || { echo "Warning: Nothing to commit"; return 0; }
  
  echo "Pushing changes to GitHub..."
  git push origin main || { echo "Error: Failed to push to GitHub"; exit 1; }
}

# Main script logic
case "$1" in
  "add"|"done"|"delete")
    action="$1"
    shift
    
    # Run the original task command with all arguments
    echo "Running: task $action $*"
    task "$action" "$@"
    
    # Commit and push changes
    commit_and_push "$action" "$*"
    ;;
  "")
    # Just "task" with no arguments - pull first then run task
    pull_from_github
    task
    ;;
  *)
    # Any other task command - just run it normally
    task "$@"
    ;;
esac
