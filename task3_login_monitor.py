#!/usr/bin/env python3

import json
import os
import time
from datetime import datetime

# JSON file used to persist login attempt data
DATA_FILE = "login_attempts.json"

# Log file shared with the submission system
LOG_FILE = "submission_log.txt"

# Number of failed attempts allowed before account lock
LOCK_THRESHOLD = 3

# Time window in seconds for suspicious repeated attempts
SUSPICIOUS_WINDOW = 60


# Function to load student login data from JSON file
def load_data():
    if os.path.exists(DATA_FILE):
        with open(DATA_FILE, "r") as f:
            try:
                return json.load(f)
            except json.JSONDecodeError:
                return {}
    return {}

# Function to save student login data back to JSON
def save_data(data):
    with open(DATA_FILE, "w") as f:
        json.dump(data, f, indent=4)


# Function to record login-related events in the log file
def log_event(student_id, status):
    with open(LOG_FILE, "a") as f:
        f.write(
            f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] "
            f"StudentID={student_id}, LoginStatus={status}\n"
        )

# Function to simulate a login attempt
def simulate_login():
    data = load_data()
    student_id = input("Enter Student ID: ").strip()

    # Create student record if it does not already exist
    if student_id not in data:
        data[student_id] = {
            "failed_attempts": 0,
            "timestamps": [],
            "locked": False
        }

    user = data[student_id]

    # If account already locked, deny access immediately
    if user["locked"]:
        print("Account is locked.")
        log_event(student_id, "Locked_Account_Attempt")
        return

    password = input("Enter password: ").strip()

    current_time = time.time()

    # Keep only recent timestamps within the suspicious activity window
    user["timestamps"] = [
        t for t in user["timestamps"]
        if current_time - t <= SUSPICIOUS_WINDOW
    ]

    # For demonstration, the correct password is hardcoded
    if password != "securepass":
        user["failed_attempts"] += 1
        user["timestamps"].append(current_time)

        # If there is more than one recent attempt, flag as suspicious
        if len(user["timestamps"]) > 1:
            print("Suspicious activity detected: repeated login attempts within 60 seconds.")
            log_event(student_id, "Suspicious_Login_Pattern")

        # Lock the account after 3 failed attempts
        if user["failed_attempts"] >= LOCK_THRESHOLD:
            user["locked"] = True
            print("Account locked after three failed attempts.")
            log_event(student_id, "Account_Locked")
        else:
            print(f"Login failed. Attempt {user['failed_attempts']} of 3.")
            log_event(student_id, "Failed_Login")

    else:
        print("Login successful.")
        user["failed_attempts"] = 0
        user["timestamps"] = []
        log_event(student_id, "Successful_Login")

    data[student_id] = user
    save_data(data)


# Program entry point
if __name__ == "__main__":
    simulate_login()