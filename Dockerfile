FROM alpine:3.19

# Update repositories and install Tor
RUN apk update && apk add --no-cache tor

# Create tor user's home directory and required directories for rootless/readonly operation
RUN mkdir -p /var/lib/tor /tmp /var/tmp && \
    chown -R tor:tor /var/lib/tor /tmp /var/tmp && \
    chmod 700 /var/lib/tor && \
    chmod 1777 /tmp /var/tmp

# Copy custom torrc configuration
COPY torrc /etc/tor/torrc

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Expose SOCKS proxy port (9050) and control port (9051)
EXPOSE 9050 9051

# Define volumes for writable directories (for readonly filesystem support)
VOLUME ["/var/lib/tor", "/tmp", "/var/tmp"]

# Switch to tor user for rootless operation
USER tor

# Set entrypoint
ENTRYPOINT ["/entrypoint.sh"]
