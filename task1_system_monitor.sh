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

