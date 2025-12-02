FROM alpine:3.19

# Install Tor and curl for health checks
RUN apk add --no-cache tor curl

# Create tor user's home directory for rootless/readonly operation
RUN mkdir -p /var/lib/tor && \
    chown -R tor:tor /var/lib/tor && \
    chmod 700 /var/lib/tor

# Copy custom torrc configuration
COPY torrc /etc/tor/torrc

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Copy health check script
COPY healthcheck.sh /healthcheck.sh
RUN chmod +x /healthcheck.sh

# Expose SOCKS proxy port (9050) and control port (9051)
EXPOSE 9050 9051

# Define volume for Tor's data directory (for readonly filesystem support)
VOLUME ["/var/lib/tor"]

# Switch to tor user for rootless operation
USER tor

# Health check to verify Tor SOCKS proxy is running and connected
HEALTHCHECK --interval=60s --timeout=12s --start-period=90s --retries=3 \
    CMD ["/healthcheck.sh"]

# Set entrypoint
ENTRYPOINT ["/entrypoint.sh"]
