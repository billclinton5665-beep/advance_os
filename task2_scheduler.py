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


# Function to load pending jobs from file
def load_jobs():
    jobs = []

    if os.path.exists(QUEUE_FILE):
        with open(QUEUE_FILE, "r") as f:
            for line in f:
                parts = line.strip().split(",")

                # Each line must have 4 values
                if len(parts) == 4:
                    jobs.append({
                        "student_id": parts[0],
                        "job_name": parts[1],
                        "exec_time": int(parts[2]),
                        "priority": int(parts[3])
                    })

    return jobs


# Function to save the current queue back to file
def save_jobs(jobs):
    with open(QUEUE_FILE, "w") as f:
        for job in jobs:
            f.write(f"{job['student_id']},{job['job_name']},{job['exec_time']},{job['priority']}\n")

# Function to add a completed job to completed_jobs.txt
def append_completed(job):
    with open(COMPLETED_FILE, "a") as f:
        f.write(f"{job['student_id']},{job['job_name']},{job['exec_time']},{job['priority']}\n")


# Function to display all pending jobs
def view_pending_jobs():
    jobs = load_jobs()

    if not jobs:
        print("No pending jobs.")
        return

    print("\n===== Pending Jobs =====")
    for i, job in enumerate(jobs, 1):
        print(
            f"{i}. Student ID: {job['student_id']}, "
            f"Job Name: {job['job_name']}, "
            f"Execution Time: {job['exec_time']}s, "
            f"Priority: {job['priority']}"
        )


# Function to submit a new job
def submit_job():
    student_id = input("Enter Student ID: ").strip()
    job_name = input("Enter Job Name: ").strip()

    try:
        exec_time = int(input("Enter Estimated Execution Time (seconds): ").strip())
        priority = int(input("Enter Priority (1-10): ").strip())

        # Validate input values
        if exec_time <= 0 or not (1 <= priority <= 10):
            raise ValueError

    except ValueError:
        print("Invalid execution time or priority.")
        return

    # Save the job to the queue file
    with open(QUEUE_FILE, "a") as f:
        f.write(f"{student_id},{job_name},{exec_time},{priority}\n")

    log_event(student_id, job_name, "Submission", "Queued")
    print("Job submitted successfully.")