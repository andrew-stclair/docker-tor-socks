#!/bin/sh
# Health check script for Tor SOCKS proxy
# This script verifies that:
# 1. The Tor process is running
# 2. The SOCKS port (9050) is listening
# 3. Tor has successfully bootstrapped and connected to the network

set -e

# Check if Tor process is running
if ! pgrep -x tor > /dev/null; then
    echo "ERROR: Tor process is not running"
    exit 1
fi

# Check if SOCKS port 9050 is listening
if ! netstat -tuln | grep -q ":9050.*LISTEN"; then
    echo "ERROR: SOCKS port 9050 is not listening"
    exit 1
fi

# Check Tor bootstrap status by attempting a simple SOCKS connection
# We'll use curl to test the SOCKS proxy with a simple connection test
if ! curl --socks5-hostname localhost:9050 --max-time 10 --silent --fail https://check.torproject.org/ > /dev/null; then
    echo "ERROR: Unable to connect through Tor SOCKS proxy"
    exit 1
fi

echo "OK: Tor SOCKS proxy is healthy and connected to the Tor network"
exit 0
