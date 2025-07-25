# Docker Heartbeat Pusher

A Docker container that persistently sends HTTP requests (heartbeats) to a remote URL at regular intervals. This is useful for monitoring system uptime, as it allows another monitoring system to detect when the source system is down if heartbeats stop arriving.

## Purpose

This project is best used in situations where a system needs to send out a heartbeat to another monitor so the other monitor knows the system is up. For example:

- Sending regular pings to uptime monitoring services
- Notifying a central monitoring system that a distributed service is still running
- Creating a "dead man's switch" that triggers alerts when a system stops sending heartbeats

## Environment Variables

Before running the container, you need to define the following environment variables:

- `HEARTBEAT_URL`: The URL to which the heartbeat will be sent
- `INTERVAL_SECONDS`: How often the heartbeat should be sent (in seconds)
- `LOGFILE`: Where logs should be stored

See the example template.env file provided in the GitHub repo for more information. (See the bottom of this page for the link.)

## Running with Docker CLI

To run the container using the Docker CLI, use the following command (assuming you have a .env file with the needed environment variables):

```sh
docker run -d \
  --name heartbeat-pusher \
  --env-file .env \
  --restart unless-stopped \
  ericwastaken/heartbeat-pusher:latest
```

### With Custom Healthcheck Parameters

The container includes a built-in healthcheck, but you can customize its parameters:

```sh
docker run -d \
  --name heartbeat-pusher \
  --env-file .env \
  --restart unless-stopped \
  --health-cmd="/usr/local/bin/healthcheck.sh" \
  --health-interval=35s \
  --health-timeout=5s \
  --health-retries=3 \
  --health-start-period=10s \
  ericwastaken/heartbeat-pusher:latest
```

## Running with Docker Compose

To run the container using Docker Compose, create a `compose.yml` file in your project directory (assuming you have a .env file with the needed environment variables):

```yaml
services:
  heartbeat-pusher:
    image: ericwastaken/heartbeat-pusher:latest
    container_name: heartbeat-pusher
    restart: unless-stopped
    environment:
      - HEARTBEAT_URL
      - INTERVAL_SECONDS
      - LOGFILE
    healthcheck:
      test: ["CMD", "/usr/local/bin/healthcheck.sh"]
      interval: 35s
      timeout: 5s
      retries: 3
      start_period: 10s
```

Ensure you have your `.env` file in the same directory as `compose.yml`.

To start the service with Docker Compose, run:

```sh
# For newer Docker versions
docker compose up -d --build

# For older Docker versions
docker-compose up -d --build
```

## Additional Commands

To stop the container:

```sh
# For newer Docker versions
docker compose down

# For older Docker versions
docker-compose down
```

To view the logs:

```sh
docker logs heartbeat-pusher
```

Or by examining the log file specified in your `.env` configuration.

## How It Works

The container runs a simple bash script that:

1. Sends an HTTP request to the configured URL at the specified interval
2. Logs the result of each attempt
3. Continues running indefinitely, restarting automatically if the container is restarted

### Healthcheck

The container includes a built-in healthcheck that verifies the heartbeat service is functioning properly:

1. It checks if the log file has recent entries within the expected timeframe (INTERVAL_SECONDS + 5 seconds)
2. Reports the container as healthy if recent entries exist, unhealthy otherwise
3. Runs automatically every 35 seconds (by default)

You can check the health status of the container using:

```sh
docker inspect --format='{{.State.Health.Status}}' heartbeat-pusher
```

This will return one of the following statuses:
- `starting`: Initial state during the start period
- `healthy`: The container is functioning properly
- `unhealthy`: The container is not functioning properly

## Usage Notes

- Ensure Docker and Docker Compose are installed on your machine.
- Adapt environment variables according to your needs.
- The container keeps only the last 10 log entries to prevent the log file from growing too large.
- The container is configured to restart automatically unless explicitly stopped.

## GitHub

See the GitHub repo for more information including how to fork and build your own version.

https://github.com/ericwastaken/docker-heartbeat-pusher
