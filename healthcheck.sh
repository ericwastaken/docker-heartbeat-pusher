#!/usr/bin/env bash
#==============================================================================
# healthcheck.sh
#==============================================================================
# Description:
#   This script checks if the heartbeat log has a recent entry within the
#   expected interval (INTERVAL_SECONDS + 5 seconds). It's used as a Docker
#   healthcheck to determine if the heartbeat service is functioning properly.
#
# Usage:
#   This script is intended to be run as a Docker HEALTHCHECK command.
#   It uses the same environment variables as the main heartbeat.sh script:
#     - INTERVAL_SECONDS: The interval between heartbeat signals in seconds
#     - LOGFILE: The path to the log file
#
#==============================================================================

# Check if required environment variables are set
if [ -z "$INTERVAL_SECONDS" ]; then
  echo "ERROR: INTERVAL_SECONDS is not set"
  exit 1
fi

if [ -z "$LOGFILE" ]; then
  echo "ERROR: LOGFILE is not set"
  exit 1
fi

# Check if the log file exists
if [ ! -f "$LOGFILE" ]; then
  echo "ERROR: Log file $LOGFILE does not exist"
  exit 1
fi

# Check if the log file has content
if [ ! -s "$LOGFILE" ]; then
  echo "ERROR: Log file $LOGFILE is empty"
  exit 1
fi

# Get the timestamp of the most recent log entry
# The log format is: "YYYY-MM-DDTHH:MM:SSZ :: OK :: response"
LATEST_TIMESTAMP=$(grep -o "[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}T[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}Z" "$LOGFILE" | tail -1)

if [ -z "$LATEST_TIMESTAMP" ]; then
  echo "ERROR: Could not find a valid timestamp in the log file"
  exit 1
fi

# Get the current time in UTC
CURRENT_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Convert timestamps to seconds since epoch for comparison
LATEST_SECONDS=$(date -u -d "$LATEST_TIMESTAMP" +%s 2>/dev/null)
if [ $? -ne 0 ]; then
  # Try macOS date format if Linux format fails
  LATEST_SECONDS=$(date -u -j -f "%Y-%m-%dT%H:%M:%SZ" "$LATEST_TIMESTAMP" +%s 2>/dev/null)
  if [ $? -ne 0 ]; then
    echo "ERROR: Could not parse timestamp format"
    exit 1
  fi
fi

CURRENT_SECONDS=$(date -u +%s)

# Calculate the time difference in seconds
TIME_DIFF=$((CURRENT_SECONDS - LATEST_SECONDS))

# Allow for a grace period of INTERVAL_SECONDS + 5 seconds
MAX_ALLOWED_DIFF=$((INTERVAL_SECONDS + 5))

if [ "$TIME_DIFF" -le "$MAX_ALLOWED_DIFF" ]; then
  echo "HEALTHY: Last heartbeat was $TIME_DIFF seconds ago (within threshold of $MAX_ALLOWED_DIFF seconds)"
  exit 0
else
  echo "UNHEALTHY: Last heartbeat was $TIME_DIFF seconds ago (exceeds threshold of $MAX_ALLOWED_DIFF seconds)"
  exit 1
fi