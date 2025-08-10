# Docker Heartbeat Pusher

A Docker container that persistently sends HTTP requests (heartbeats) to a remote URL at regular intervals. This is 
useful for monitoring system uptime, as it allows another monitoring system to detect when the source system is down if
heartbeats stop arriving. For a concrete example of a receiver, see the "Example Heartbeat Webhook Receiver" section 
below that uses Uptime Kuma, however any other system that accepts HTTP requests can be used.

## Purpose

This project is best used in situations where a system needs to send out a heartbeat to another monitor so the other monitor knows the system is up. For example:

- Sending regular pings to uptime monitoring services
- Notifying a central monitoring system that a distributed service is still running
- Creating a "dead man's switch" that triggers alerts when a system stops sending heartbeats

## Example Heartbeat Webhook Receiver

Uptime Kuma is a popular, self-hosted monitoring tool (similar to UptimeRobot) that can act as a webhook heartbeat 
receiver. It provides a unique Push URL for each monitor; your systems send periodic HTTP requests to that URL. If 
Uptime Kuma does not receive a heartbeat within the configured interval, it marks the monitor as down and can send 
alerts via email, Slack, Discord, webhooks, and many other channels.

Learn more: https://github.com/louislam/uptime-kuma

How to use Uptime Kuma as the heartbeat receiver for this container:

1. Deploy Uptime Kuma (Docker or other) and access its web UI.
2. Create a new monitor:
   - Type: Push
   - Name: e.g., "Heartbeat from Server A"
   - Heartbeat Interval: choose how often you expect a heartbeat (e.g., 60 seconds)
   - Expiry Notification: optional, controls when Kuma triggers an alert after missing heartbeats
   - Save, then copy the generated Push URL
3. Configure this container to send to that Push URL:
   - In your `.env` file set `HEARTBEAT_URL` to the Push URL from Uptime Kuma
   - Set `INTERVAL_SECONDS` slightly less than the Heartbeat Interval you configured in Uptime Kuma (e.g., if Kuma is 60s, use 50–55s here) so the heartbeat always arrives in time
   - Optionally set `LOGFILE` to a path for persistent logs
4. Start this container (see Setup Instructions below). The service will send an HTTP request to Uptime Kuma on each interval. If Uptime Kuma does not receive a heartbeat within the expected timeframe, it will mark the monitor as down and trigger your configured notifications.

Notes:
- Ensure network connectivity from this container to your Uptime Kuma instance (open firewall/ports as needed).
- Uptime Kuma accepts GET or POST to the Push URL; no body is required for a simple "up" heartbeat.

## Available on Docker Hub

This container is available on Docker Hub at [ericwastakenondocker/heartbeat-pusher](https://hub.docker.com/r/ericwastakenondocker/heartbeat-pusher).

## Setup Instructions

### 1. Clone the repository

```bash
git clone https://github.com/ericwastaken/docker-heartbeat-pusher.git
cd docker-heartbeat-pusher
```

### 2. Configure environment variables

Copy the template environment file and edit it with your specific settings:

```bash
cp template.env .env
```

Edit the `.env` file to configure:

- `HEARTBEAT_URL`: The URL to which the heartbeat will be sent
- `INTERVAL_SECONDS`: How often the heartbeat should be sent (in seconds)
- `LOGFILE`: Where logs should be stored

### 3. Build and run the container

Using Docker Compose:

```bash
# For newer Docker versions
docker compose up -d --build

# For older Docker versions
docker-compose up -d --build
```

## How It Works

The container runs a simple bash script that:

1. Sends an HTTP request to the configured URL at the specified interval
2. Logs the result of each attempt
3. Continues running indefinitely, restarting automatically if the container is restarted

### Healthcheck

The container includes a built-in healthcheck that verifies the heartbeat service is functioning properly. The healthcheck:

1. Checks if the log file has recent entries within the expected timeframe (INTERVAL_SECONDS + 5 seconds)
2. Reports the container as healthy if recent entries exist, unhealthy otherwise
3. Runs automatically every 35 seconds (by default)

You can check the health status of the container using:

```bash
docker inspect --format='{{.State.Health.Status}}' heartbeat-pusher
```

To run the container with custom healthcheck parameters:

```bash
docker run -d \
  --name heartbeat-pusher \
  --env-file .env \
  --health-cmd="/usr/local/bin/healthcheck.sh" \
  --health-interval=35s \
  --health-timeout=5s \
  --health-retries=3 \
  --health-start-period=10s \
  ericwastaken/heartbeat-pusher:latest
```

## Logs

You can view the logs of the heartbeat attempts by:

```bash
docker logs heartbeat-pusher
```

Or by examining the log file specified in your `.env` configuration.

## Building and Deploying

This project includes scripts for building and deploying the Docker image to Docker Hub or another container registry.

### Configuration

Before building or deploying, configure the build settings in `docker-build-manifest.env`:

- `BUILDER_NAME`: Name of the Docker buildx builder
- `CURR_TAG`: Version tag for the image (typically a date in YYYYMMDD format)
- `NAME`: Full image name including repository (e.g., username/image-name)

### Building the Image

The `x_build.sh` script builds the Docker image:

```bash
./x_build.sh
```

This script offers two options:
1. **Multi-platform build**: Creates images for both AMD64 and ARM64 architectures (requires Docker buildx with QEMU support, which is built into macOS Docker Desktop)
2. **Current platform only**: Builds an image only for your current architecture

### Deploying the Image

The `x_deploy.sh` script tags and pushes the image to a container registry:

```bash
./x_deploy.sh
```

This script:
1. Verifies you're logged into Docker
2. Confirms you want to proceed with tagging and pushing
3. Offers options for multi-platform or single-platform deployment
4. Tags the image with both the version in `CURR_TAG` and as `latest`
5. Pushes the images to the repository specified in `NAME`

Before running this script, ensure you're logged into your container registry:

```bash
docker login
```
