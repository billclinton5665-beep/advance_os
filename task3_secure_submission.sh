#!/bin/bash

# Resolve script directory so paths are stable regardless of launch location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Directory where accepted assignment files will be stored
SUBMISSION_DIR="$SCRIPT_DIR/submissions"

# Common log file for both file submissions and login monitoring
LOG_FILE="$SCRIPT_DIR/submission_log.txt"

# Ensure required directory and log file exist
mkdir -p "$SUBMISSION_DIR"
touch "$LOG_FILE"

# Function to log actions with timestamps
log_action() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}


# Function to check whether a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}


# Normalize Windows-style paths (e.g., D:\folder\file.pdf) for Bash checks
normalize_input_path() {
    local input_path="$1"

    if command_exists cygpath; then
        cygpath -u "$input_path" 2>/dev/null || printf '%s' "$input_path"
    elif [[ "$input_path" =~ ^[A-Za-z]:\\ ]]; then
        local drive_letter="${input_path:0:1}"
        local remaining_path="${input_path:2}"
        remaining_path="${remaining_path//\\//}"
        printf '/%s/%s' "$(echo "$drive_letter" | tr 'A-Z' 'a-z')" "$remaining_path"
    else
        printf '%s' "$input_path"
    fi
}


# Function to submit an assignment
submit_assignment() {
    read -p "Enter Student ID: " student_id
    read -r -p "Enter file path: " filepath_raw
    filepath="$(normalize_input_path "$filepath_raw")"

    # Check if file exists
    if [ ! -f "$filepath" ]; then
        echo "File does not exist."
        log_action "StudentID=$student_id, File=$filepath_raw, Status=Rejected_File_Not_Found"
        return
    fi

    # Get file extension
    ext="${filepath##*.}"

    # Only allow pdf and docx
    if [[ "$ext" != "pdf" && "$ext" != "docx" ]]; then
        echo "Invalid file type. Only .pdf and .docx files are allowed."
        log_action "StudentID=$student_id, File=$filepath_raw, Status=Rejected_Invalid_Format"
        return
    fi

    # Get file size in bytes
    filesize=$(stat -c%s "$filepath")

    # 5MB = 5242880 bytes
    if [ "$filesize" -gt 5242880 ]; then
        echo "File too large. Maximum size is 5MB."
        log_action "StudentID=$student_id, File=$filepath_raw, Status=Rejected_File_Too_Large"
        return
    fi

    # Get only the file name
    filename=$(basename "$filepath")

    # Calculate new file hash for duplicate detection
    new_hash=$(sha256sum "$filepath" | awk '{print $1}')

    # Compare against files already submitted
    for existing in "$SUBMISSION_DIR"/*; do
        [ -e "$existing" ] || break

        existing_name=$(basename "$existing")
        existing_hash=$(sha256sum "$existing" | awk '{print $1}')

        # Duplicate only if both filename and content match
        if [ "$filename" == "$existing_name" ] && [ "$new_hash" == "$existing_hash" ]; then
            echo "Duplicate submission detected. Rejected."
            log_action "StudentID=$student_id, File=$filename, Status=Rejected_Duplicate"
            return
        fi
    done

    # Copy file into submissions folder
    cp "$filepath" "$SUBMISSION_DIR/$filename"

    echo "Submission accepted."
    log_action "StudentID=$student_id, File=$filename, Status=Accepted"
}


# Function to check whether a file has already been submitted
check_existing_submission() {
    read -r -p "Enter file path to check: " filepath_raw
    filepath="$(normalize_input_path "$filepath_raw")"

    if [ ! -f "$filepath" ]; then
        echo "File does not exist."
        return
    fi

    filename=$(basename "$filepath")
    new_hash=$(sha256sum "$filepath" | awk '{print $1}')

    for existing in "$SUBMISSION_DIR"/*; do
        [ -e "$existing" ] || break

        existing_name=$(basename "$existing")
        existing_hash=$(sha256sum "$existing" | awk '{print $1}')

        if [ "$filename" == "$existing_name" ] && [ "$new_hash" == "$existing_hash" ]; then
            echo "This file has already been submitted."
            return
        fi
    done

    echo "No duplicate found."
}


# Function to list all submitted assignments
list_submissions() {
    echo "===== Submitted Assignments ====="
    ls -lh "$SUBMISSION_DIR"
}

# Function to launch the Python login monitoring system
simulate_login() {
    local venv_python="$SCRIPT_DIR/../.venv/Scripts/python.exe"

    if [ -f "$venv_python" ]; then
        "$venv_python" "$SCRIPT_DIR/task3_login_monitor.py"
    elif command_exists python3; then
        python3 "$SCRIPT_DIR/task3_login_monitor.py"
    elif command_exists python; then
        python "$SCRIPT_DIR/task3_login_monitor.py"
    else
        echo "Python is not available in this environment."
    fi
}

# Function to exit with confirmation
exit_system() {
    read -p "Bye? Confirm exit (Y/N): " confirm

    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        echo "Goodbye."
        exit 0
    else
        echo "Exit cancelled."
    fi
}


# Main menu loop
while true; do
    echo
    echo "===== Secure Examination Submission and Access Control System ====="
    echo "1. Submit an assignment"
    echo "2. Check if a file has already been submitted"
    echo "3. List all submitted assignments"
    echo "4. Simulate login attempt"
    echo "5. Bye"

    read -p "Choose an option: " choice

    case $choice in
        1) submit_assignment ;;
        2) check_existing_submission ;;
        3) list_submissions ;;
        4) simulate_login ;;
        5) exit_system ;;
        *) echo "Invalid option. Please try again." ;;
    esac
done