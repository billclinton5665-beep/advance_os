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


# Function to process jobs using Round Robin scheduling
def process_round_robin():
    jobs = load_jobs()

    if not jobs:
        print("No jobs to process.")
        return

    print("\n===== Processing with Round Robin =====")

    while jobs:
        # Get the first job in queue
        current_job = jobs.pop(0)

        # Job runs for either the full quantum or remaining time
        run_time = min(TIME_QUANTUM, current_job["exec_time"])

        print(f"Running {current_job['job_name']} for {run_time} seconds...")
        
        # Simulated execution pause
        time.sleep(1)

        # Reduce remaining execution time
        current_job["exec_time"] -= run_time

        if current_job["exec_time"] > 0:
            # Put unfinished job back into queue
            jobs.append(current_job)
            log_event(
                current_job["student_id"],
                current_job["job_name"],
                "Round Robin",
                f"Remaining {current_job['exec_time']}s"
            )
        else:
            # If job is complete, add it to completed jobs
            append_completed(current_job)
            log_event(
                current_job["student_id"],
                current_job["job_name"],
                "Round Robin",
                "Completed"
            )

        # Save updated queue after every cycle
        save_jobs(jobs)

    print("All jobs processed using Round Robin.")


# Function to process jobs using Priority Scheduling
def process_priority():
    jobs = load_jobs()

    if not jobs:
        print("No jobs to process.")
        return

    # Highest priority should execute first
    jobs.sort(key=lambda job: job["priority"], reverse=True)

    print("\n===== Processing with Priority Scheduling =====")

    for job in jobs:
        print(f"Running {job['job_name']} with priority {job['priority']} for {job['exec_time']} seconds...")
        
        # Simulated execution pause
        time.sleep(1)

        append_completed(job)
        log_event(job["student_id"], job["job_name"], "Priority", "Completed")

    # Queue becomes empty after all jobs complete
    save_jobs([])

    print("All jobs processed using Priority Scheduling.")


 # Function to display completed jobs
def view_completed_jobs():
    if not os.path.exists(COMPLETED_FILE) or os.path.getsize(COMPLETED_FILE) == 0:
        print("No completed jobs.")
        return

    print("\n===== Completed Jobs =====")
    with open(COMPLETED_FILE, "r") as f:
        for i, line in enumerate(f, 1):
            student_id, job_name, exec_time, priority = line.strip().split(",")
            print(
                f"{i}. Student ID: {student_id}, "
                f"Job Name: {job_name}, "
                f"Execution Time: {exec_time}s, "
                f"Priority: {priority}"
            )