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