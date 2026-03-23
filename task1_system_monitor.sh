# File used to store all system administration logs
LOG_FILE="system_monitor_log.txt"

# Directory where archived log files will be stored
ARCHIVE_DIR="ArchiveLogs"

# Critical PIDs that should not be killed
# PID 1 is init/systemd, $$ is the current shell script process
CRITICAL_PIDS="1 $$"

# Function to write actions into the log file with a timestamp
log_action() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Function to display current CPU and memory usage
show_system_usage() {
    echo "===== Current CPU Usage ====="
    top -bn1 | grep "Cpu(s)"

    echo
    echo "===== Current Memory Usage ====="
    free -h

    log_action "Displayed CPU and memory usage"
}


# Function to display the top 10 memory consuming processes
show_top_processes() {
    echo "===== Top 10 Memory Consuming Processes ====="

    # ps displays PID, user, CPU%, MEM%, command
    # --sort=-%mem sorts by memory usage descending
    ps -eo pid,user,%cpu,%mem,comm --sort=-%mem | head -n 11

    log_action "Displayed top 10 memory consuming processes"
}


# Function to safely terminate a process
terminate_process() {
    read -p "Enter PID to terminate: " pid

    # Validate that PID contains only numbers
    if ! [[ "$pid" =~ ^[0-9]+$ ]]; then
        echo "Invalid PID."
        log_action "Invalid PID entered for termination: $pid"
        return
    fi

    # Check if PID exists
    if ! ps -p "$pid" > /dev/null 2>&1; then
        echo "Process does not exist."
        log_action "Attempted termination of non-existent PID: $pid"
        return
    fi

    # Prevent killing critical processes
    for critical in $CRITICAL_PIDS; do
        if [ "$pid" -eq "$critical" ]; then
            echo "Cannot terminate critical system process: PID $pid"
            log_action "Blocked attempt to terminate critical PID $pid"
            return
        fi
    done

    # Ask for confirmation before termination
    read -p "Are you sure you want to terminate PID $pid? (Y/N): " confirm

    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        kill "$pid" 2>/dev/null

        if [ $? -eq 0 ]; then
            echo "Process $pid terminated successfully."
            log_action "Terminated process PID $pid"
        else
            echo "Failed to terminate process PID $pid"
            log_action "Failed to terminate process PID $pid"
        fi
    else
        echo "Termination cancelled."
        log_action "Cancelled termination of PID $pid"
    fi
}


# Function to inspect disk usage of a user-provided directory
inspect_disk_usage() {
    read -p "Enter directory path to inspect: " dir

    if [ ! -d "$dir" ]; then
        echo "Directory does not exist."
        log_action "Invalid directory inspected: $dir"
        return
    fi

    echo "===== Disk Usage for $dir ====="
    du -sh "$dir"

    log_action "Inspected disk usage for directory $dir"
}


# Function to archive large .log files
archive_large_logs() {
    read -p "Enter directory path to scan for large log files: " dir

    if [ ! -d "$dir" ]; then
        echo "Directory does not exist."
        log_action "Invalid directory scanned for log archival: $dir"
        return
    fi

    # Create archive directory if it does not already exist
    mkdir -p "$ARCHIVE_DIR"

    found=0

    # Find all .log files larger than 50MB
    while IFS= read -r -d '' file; do
        found=1

        # Get the base name of the file
        base=$(basename "$file")

        # Add timestamp to archived filename
        timestamp=$(date '+%Y%m%d_%H%M%S')

        # Compress the file into ArchiveLogs
        gzip -c "$file" > "$ARCHIVE_DIR/${base}_${timestamp}.gz"

        echo "Archived: $file -> $ARCHIVE_DIR/${base}_${timestamp}.gz"
        log_action "Archived large log file $file"
    done < <(find "$dir" -type f -name "*.log" -size +50M -print0)

    if [ $found -eq 0 ]; then
        echo "No log files larger than 50MB found."
        log_action "No large log files found in $dir"
    fi

    # Check size of ArchiveLogs directory in bytes
    archive_size=$(du -sb "$ARCHIVE_DIR" 2>/dev/null | awk '{print $1}')

    # 1GB = 1073741824 bytes
    if [ -n "$archive_size" ] && [ "$archive_size" -gt 1073741824 ]; then
        echo "WARNING: ArchiveLogs exceeds 1GB."
        log_action "Warning issued: ArchiveLogs exceeds 1GB"
    fi
}