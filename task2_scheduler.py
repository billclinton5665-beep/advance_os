#!/usr/bin/env python3

import os
import time
from datetime import datetime

# File names used by the scheduler
QUEUE_FILE = "job_queue.txt"
COMPLETED_FILE = "completed_jobs.txt"
LOG_FILE = "scheduler_log.txt"

# Round Robin time quantum required by the assignment
TIME_QUANTUM = 5


# Function to log scheduling actions
def log_event(student_id, job_name, scheduling_type, result):
    with open(LOG_FILE, "a") as f:
        f.write(
            f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] "
            f"StudentID={student_id}, Job={job_name}, "
            f"Type={scheduling_type}, Result={result}\n"
        )


