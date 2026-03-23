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


# Function to submit an assignment
submit_assignment() {
    read -p "Enter Student ID: " student_id
    read -p "Enter file path: " filepath

    # Check if file exists
    if [ ! -f "$filepath" ]; then
        echo "File does not exist."
        log_action "StudentID=$student_id, File=$filepath, Status=Rejected_File_Not_Found"
        return
    fi

    # Get file extension
    ext="${filepath##*.}"

    # Only allow pdf and docx
    if [[ "$ext" != "pdf" && "$ext" != "docx" ]]; then
        echo "Invalid file type. Only .pdf and .docx files are allowed."
        log_action "StudentID=$student_id, File=$filepath, Status=Rejected_Invalid_Format"
        return
    fi

    # Get file size in bytes
    filesize=$(stat -c%s "$filepath")

    # 5MB = 5242880 bytes
    if [ "$filesize" -gt 5242880 ]; then
        echo "File too large. Maximum size is 5MB."
        log_action "StudentID=$student_id, File=$filepath, Status=Rejected_File_Too_Large"
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
    read -p "Enter file path to check: " filepath

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
    python3 task3_login_monitor.py
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
