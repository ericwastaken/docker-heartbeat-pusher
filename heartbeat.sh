#!/usr/bin/env bash
#==============================================================================
# heartbeat.sh
#==============================================================================
# Description:
#   This script sends periodic heartbeat signals to a specified URL and logs
#   the responses. It's designed to work with uptime monitoring services like
#   Uptime Kuma that support push-based monitoring, but can work with any monitor
#   capable of receiving a webhook.
#
# Usage:
#   This script is intended to be run in a Docker container with the following
#   environment variables set:
#     - HEARTBEAT_URL: The URL to send heartbeat signals to
#     - INTERVAL_SECONDS: The interval between heartbeat signals in seconds
#     - LOGFILE: The path to the log file
#
#==============================================================================

# Check if required environment variables are set
# HEARTBEAT_URL is the endpoint to send heartbeat signals to
if [ -z "$HEARTBEAT_URL" ]; then
  echo "ERROR: HEARTBEAT_URL is not set"
  exit 1
fi

# INTERVAL_SECONDS defines how often to send heartbeat signals
if [ -z "$INTERVAL_SECONDS" ]; then
  echo "ERROR: INTERVAL_SECONDS is not set"
  exit 1
fi

# LOGFILE is where the heartbeat responses will be logged
if [ -z "$LOGFILE" ]; then
  echo "ERROR: LOGFILE is not set"
  exit 1
fi

# Verify that the log file is writable
if ! touch "$LOGFILE" 2>/dev/null; then
  echo "ERROR: Cannot write to LOGFILE at $LOGFILE"
  exit 1
fi

# Print startup message
echo "Starting Kuma heartbeat pusher (every $INTERVAL_SECONDS seconds)..."
echo "Writing to $LOGFILE"

# Main loop - runs indefinitely
while true; do
  # Generate timestamp in ISO 8601 format
  TIMESTAMP="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  echo "$TIMESTAMP :: Sending heartbeat to $HEARTBEAT_URL"

  # Send HTTP request to the heartbeat URL
  # Using -k to skip SSL certificate validation (fixes curl exit code 77 error)
  # --max-time 10: Timeout after 10 seconds
  # -fsS: Fail silently on server errors, but show error messages
  # 2>/dev/null: Redirect stderr to /dev/null to suppress error messages
  RESPONSE=$(curl --max-time 10 -fsS -k "$HEARTBEAT_URL" 2>/dev/null)
  CURL_EXIT=$?

  # Process the response
  if [ "$CURL_EXIT" -eq 0 ]; then
    # Success - log the response
    echo "$TIMESTAMP :: OK :: $RESPONSE" | tee -a "$LOGFILE"
  else
    # Failure - log the error
    echo "$TIMESTAMP :: Failed to send heartbeat (exit code $CURL_EXIT) :: $RESPONSE" | tee -a "$LOGFILE"
  fi

  # Log rotation - Keep only the last 10 entries in the log file
  # This prevents the log file from growing indefinitely
  if [ -f "$LOGFILE" ]; then
    tail -n 10 "$LOGFILE" > "$LOGFILE.tmp" && mv "$LOGFILE.tmp" "$LOGFILE"
  fi

  # Wait for the specified interval before sending the next heartbeat
  sleep "$INTERVAL_SECONDS"
done
