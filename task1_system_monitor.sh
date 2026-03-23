# Resolve the script directory so output paths are stable regardless of launch location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# File used to store all system administration logs
LOG_FILE="$SCRIPT_DIR/system_monitor_log.txt"

# Directory where archived log files will be stored
ARCHIVE_DIR="$SCRIPT_DIR/ArchiveLogs"

# Critical PIDs that should not be killed
# PID 1 is init/systemd, $$ is the current shell script process
CRITICAL_PIDS="1 $$"

# Function to write actions into the log file with a timestamp
log_action() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}


# Function to check whether a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}


# Function to display CPU usage with Linux and Windows fallbacks
show_cpu_usage() {
    if command_exists top; then
        top -bn1 2>/dev/null | grep "Cpu(s)"
    elif command_exists powershell; then
        powershell -NoProfile -Command '(Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average | ForEach-Object { "CPU Load: " + $_ + "%" }'
    else
        echo "CPU usage command not available in this environment."
    fi
}


# Function to display memory usage with Linux and Windows fallbacks
show_memory_usage() {
    if command_exists free; then
        free -h
    elif command_exists powershell; then
        powershell -NoProfile -Command '$os = Get-CimInstance Win32_OperatingSystem; $total = [math]::Round($os.TotalVisibleMemorySize/1024/1024,2); $free = [math]::Round($os.FreePhysicalMemory/1024/1024,2); $used = [math]::Round($total - $free,2); Write-Output ("Total: " + $total + " GB"); Write-Output ("Used : " + $used + " GB"); Write-Output ("Free : " + $free + " GB")'
    else
        echo "Memory usage command not available in this environment."
    fi
}


# Function to return directory size in bytes with fallback
get_dir_size_bytes() {
    local dir="$1"

    if du -sb "$dir" >/dev/null 2>&1; then
        du -sb "$dir" 2>/dev/null | awk '{print $1}'
    else
        du -sk "$dir" 2>/dev/null | awk '{print $1 * 1024}'
    fi
}


# Function to check process existence with Linux and Windows fallbacks
process_exists() {
    local pid="$1"

    if ps -p "$pid" >/dev/null 2>&1; then
        return 0
    elif command_exists powershell; then
        powershell -NoProfile -Command "if (Get-Process -Id $pid -ErrorAction SilentlyContinue) { exit 0 } else { exit 1 }" >/dev/null 2>&1
        return $?
    else
        return 1
    fi
}


# Function to terminate a process with Linux and Windows fallbacks
terminate_pid() {
    local pid="$1"

    if kill "$pid" >/dev/null 2>&1; then
        return 0
    elif command_exists powershell; then
        powershell -NoProfile -Command "try { Stop-Process -Id $pid -Force -ErrorAction Stop; exit 0 } catch { exit 1 }" >/dev/null 2>&1
        return $?
    else
        return 1
    fi
}

# Function to display current CPU and memory usage
show_system_usage() {
    echo "===== Current CPU Usage ====="
    show_cpu_usage

    echo
    echo "===== Current Memory Usage ====="
    show_memory_usage

    log_action "Displayed CPU and memory usage"
}


# Function to display the top 10 memory consuming processes
show_top_processes() {
    echo "===== Top 10 Memory Consuming Processes ====="

    # Prefer GNU/Linux ps output when available.
    if ps -eo pid,user,%cpu,%mem,comm --sort=-%mem >/dev/null 2>&1; then
        ps -eo pid,user,%cpu,%mem,comm --sort=-%mem | head -n 11
    # Fallback for Windows/Git Bash environments where ps options differ.
    elif command_exists powershell; then
        powershell -NoProfile -Command 'Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First 10 @{Name="PID";Expression={$_.Id}}, @{Name="Name";Expression={$_.ProcessName}}, @{Name="MemoryMB";Expression={[math]::Round($_.WorkingSet64/1MB,2)}} | Format-Table -AutoSize'
    else
        echo "Cannot list top memory processes in this environment."
    fi

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
    if ! process_exists "$pid"; then
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
        if terminate_pid "$pid"; then
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
    archive_size=$(get_dir_size_bytes "$ARCHIVE_DIR")

    # 1GB = 1073741824 bytes
    if [ -n "$archive_size" ] && [ "$archive_size" -gt 1073741824 ]; then
        echo "WARNING: ArchiveLogs exceeds 1GB."
        log_action "Warning issued: ArchiveLogs exceeds 1GB"
    fi
}


# Function to exit the system cleanly
exit_system() {
    echo "Exiting..."
    log_action "User exited the system monitor"
    exit 0
}


# Main menu loop
while true; do
    echo
    echo "===== University Data Centre Process and Resource Management System ====="
    echo "1. Display current CPU and memory usage"
    echo "2. List top 10 memory consuming processes"
    echo "3. Terminate a process"
    echo "4. Inspect disk usage of a directory"
    echo "5. Detect and archive large log files"
    echo "6. Bye"

    read -p "Choose an option: " choice

    case $choice in
        1) show_system_usage ;;
        2) show_top_processes ;;
        3) terminate_process ;;
        4) inspect_disk_usage ;;
        5) archive_large_logs ;;
        6) exit_system ;;
        *) echo "Invalid option. Please try again." ;;
    esac
done