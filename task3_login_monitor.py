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
