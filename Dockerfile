FROM debian:bookworm-slim

# Install required tools
RUN apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    bash curl tzdata && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Copy the heartbeat script into the image
COPY heartbeat.sh /usr/local/bin/heartbeat.sh
RUN chmod +x /usr/local/bin/heartbeat.sh

# Copy the healthcheck script into the image
COPY healthcheck.sh /usr/local/bin/healthcheck.sh
RUN chmod +x /usr/local/bin/healthcheck.sh

# Configure healthcheck
HEALTHCHECK --interval=35s --timeout=5s --start-period=10s --retries=3 \
  CMD ["/usr/local/bin/healthcheck.sh"]

ENTRYPOINT ["/usr/local/bin/heartbeat.sh"]
