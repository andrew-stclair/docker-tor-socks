#!/bin/sh
set -e

echo "Starting Tor SOCKS proxy..."
echo "SOCKS proxy will be available on port 9050"
echo "Control port will be available on port 9051"
echo ""
echo "This container is configured as a client-only proxy."
echo "It does NOT function as a relay, exit node, or bridge."
echo ""

# Handle ControlPort password configuration
TORRC_PATH="/etc/tor/torrc"

if [ -n "$TOR_CONTROL_PASSWORD" ]; then
    echo "Configuring ControlPort authentication..."
    
    # Generate hashed password
    # Note: Password briefly appears in process args, but in a single-user container
    # environment this is acceptable. The password is never logged or persisted.
    HASHED_PASSWORD=$(tor --hash-password "$TOR_CONTROL_PASSWORD")
    
    if [ -z "$HASHED_PASSWORD" ]; then
        echo "Error: Failed to generate hashed password" >&2
        exit 1
    fi
    
    # Create modified torrc in /tmp (writable with read-only filesystem)
    TORRC_PATH="/tmp/torrc"
    if ! cp /etc/tor/torrc "$TORRC_PATH"; then
        echo "Error: Failed to copy torrc configuration" >&2
        exit 1
    fi
    
    # Add HashedControlPassword to the config
    if ! echo "HashedControlPassword $HASHED_PASSWORD" >> "$TORRC_PATH"; then
        echo "Error: Failed to write HashedControlPassword to torrc" >&2
        exit 1
    fi
    
    echo "ControlPort authentication enabled"
else
    echo "Warning: ControlPort has no authentication configured."
    echo "Consider setting TOR_CONTROL_PASSWORD environment variable."
fi

echo ""

# Start Tor
exec tor -f "$TORRC_PATH"
