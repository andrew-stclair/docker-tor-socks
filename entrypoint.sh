#!/bin/sh
set -e

echo "Starting Tor SOCKS proxy..."
echo "SOCKS proxy will be available on port 9050"
echo "Control port will be available on port 9051"
echo ""
echo "This container is configured as a client-only proxy."
echo "It does NOT function as a relay, exit node, or bridge."
echo ""

# Start Tor
exec tor -f /etc/tor/torrc
