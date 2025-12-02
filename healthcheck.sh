#!/bin/sh
# Health check script for Tor SOCKS proxy
# This script verifies that:
# 1. The Tor process is running
# 2. The SOCKS port (9050) is listening
# 3. Tor has successfully bootstrapped and connected to the network

# Check if Tor process is running
if ! pgrep -x tor > /dev/null; then
    echo "ERROR: Tor process is not running"
    exit 1
fi

# Check if SOCKS port 9050 is listening
# Use netstat (available in busybox/Alpine by default)
if ! netstat -tuln | grep -q ":9050.*LISTEN"; then
    echo "ERROR: SOCKS port 9050 is not listening"
    exit 1
fi

# Check Tor connectivity by attempting a SOCKS connection to an external service
# This verifies that Tor has bootstrapped and can route traffic through the network
# Use a short timeout to avoid blocking the health check
if curl --socks5-hostname localhost:9050 --max-time 10 --silent --fail https://check.torproject.org/ > /dev/null 2>&1; then
    echo "OK: Tor SOCKS proxy is healthy and connected to the Tor network"
    exit 0
fi

# If the external check fails, it could be due to network issues or Tor still bootstrapping
# As a fallback, verify basic functionality is present (process running + port listening)
# This prevents false negatives during temporary network issues
# Allow fallback only during initial grace period after container startup
GRACE_PERIOD=60  # seconds
UPTIME=$(awk '{print int($1)}' /proc/uptime)
if [ "$UPTIME" -lt "$GRACE_PERIOD" ]; then
    echo "WARNING: Tor SOCKS proxy is running but external connectivity test failed (may still be bootstrapping; within grace period)"
    exit 0
else
    echo "ERROR: Tor SOCKS proxy is running but cannot connect to the Tor network (outside grace period)"
    exit 1
fi
