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