!/bin/bash

# Directory where accepted assignment files will be stored
SUBMISSION_DIR="submissions"

# Common log file for both file submissions and login monitoring
LOG_FILE="submission_log.txt"

# Ensure required directory and log file exist
mkdir -p "$SUBMISSION_DIR"
touch "$LOG_FILE"

# Function to log actions with timestamps
log_action() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}