# docker-tor-socks

Tor SOCKS proxy sidecar container for secure, anonymous networking. This container is configured as a client-only proxy and does NOT function as a relay, exit node, or bridge on the Tor network.

## Features

- 🔒 SOCKS5 proxy on port 9050
- 🎛️ Control port on port 9051
- 🐳 Multi-architecture support (amd64, arm64, arm/v7)
- 🚫 Client-only mode (does NOT route traffic for others)
- 📦 Lightweight Alpine-based image
- 🔄 Perfect for use as a sidecar container
- 🛡️ Rootless operation (runs as non-root 'tor' user)
- 📖 Read-only filesystem support with tmpfs mounts

## Quick Start

### Pull from GitHub Container Registry

```bash
docker pull ghcr.io/andrew-stclair/tor-socks:latest
```

### Run the Container

```bash
docker run -d \
  --name tor-socks \
  -p 9050:9050 \
  -p 9051:9051 \
  ghcr.io/andrew-stclair/tor-socks:latest
```

### Run with Read-only Filesystem (Recommended for Security)

```bash
docker run -d \
  --name tor-socks \
  -p 9050:9050 \
  -p 9051:9051 \
  --read-only \
  --tmpfs /tmp \
  --tmpfs /var/tmp \
  -v tor-data:/var/lib/tor \
  --security-opt no-new-privileges:true \
  --cap-drop ALL \
  ghcr.io/andrew-stclair/tor-socks:latest
```

### Test the SOCKS Proxy

```bash
# Using curl with the SOCKS5 proxy
curl --socks5-hostname localhost:9050 https://check.torproject.org/api/ip

# Using wget with the SOCKS5 proxy
wget -qO- --proxy=on --socks-server=localhost:9050 https://check.torproject.org/api/ip
```

## Usage as a Sidecar Container

### Docker Compose Example

See the included `docker-compose.yml` file for a complete example with read-only filesystem support.

```yaml
version: '3.8'

services:
  tor-proxy:
    image: ghcr.io/andrew-stclair/tor-socks:latest
    container_name: tor-socks
    restart: unless-stopped
    ports:
      - "9050:9050"  # SOCKS proxy port
      - "9051:9051"  # Control port
    # For readonly filesystem support with tmpfs mounts
    read_only: true
    tmpfs:
      - /tmp
      - /var/tmp
    volumes:
      - tor-data:/var/lib/tor
    # Security options for rootless operation
    security_opt:
      - no-new-privileges:true
    cap_drop:
      - ALL

  your-app:
    image: your-app:latest
    environment:
      - HTTP_PROXY=socks5h://tor-proxy:9050
      - HTTPS_PROXY=socks5h://tor-proxy:9050
    depends_on:
      - tor-proxy

volumes:
  tor-data:
```

### Kubernetes Sidecar Example

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-with-tor
spec:
  containers:
  - name: your-app
    image: your-app:latest
    env:
    - name: HTTP_PROXY
      value: "socks5h://localhost:9050"
    - name: HTTPS_PROXY
      value: "socks5h://localhost:9050"
  
  - name: tor-socks
    image: ghcr.io/andrew-stclair/tor-socks:latest
    ports:
    - containerPort: 9050
      name: socks
    - containerPort: 9051
      name: control
```

## Configuration

### Exposed Ports

- **9050**: SOCKS5 proxy port
- **9051**: Control port (for programmatic control of Tor)

### Environment Variables

This container uses the default Tor configuration and doesn't require environment variables. The configuration can be customized by mounting a custom `torrc` file.

### Custom Configuration

To use a custom `torrc` configuration:

```bash
docker run -d \
  --name tor-socks \
  -p 9050:9050 \
  -p 9051:9051 \
  -v /path/to/your/torrc:/etc/tor/torrc:ro \
  ghcr.io/andrew-stclair/tor-socks:latest
```

## Security Considerations

### Client-Only Configuration
- This container is configured as a **client-only** Tor proxy
- It does **NOT** function as a relay, exit node, or bridge
- The ExitPolicy is set to `reject *:*` to prevent acting as an exit node
- ORPort is disabled (set to 0)
- Suitable for use as a privacy-enhancing proxy for your applications

### Rootless Operation
- Container runs as the non-root `tor` user (UID/GID defined by Alpine's tor package)
- No privilege escalation required
- Compatible with rootless Docker and Podman

### Read-Only Filesystem Support
- Designed to work with `--read-only` flag
- Persistent data volume:
  - `/var/lib/tor` - Tor's data directory (state, keys, etc.) - defined as a volume
- Writable tmpfs mounts (specified at runtime):
  - `/tmp` - Temporary files (use `--tmpfs /tmp`)
  - `/var/tmp` - Temporary files (use `--tmpfs /var/tmp`)
- Recommended security hardening:
  ```bash
  --read-only \
  --tmpfs /tmp \
  --tmpfs /var/tmp \
  --security-opt no-new-privileges:true \
  --cap-drop ALL
  ```

### Network Exposure
- **SOCKS Port (9050)** and **Control Port (9051)** are bound to `0.0.0.0` by default to allow access from other containers (sidecar pattern)
- In production environments, consider:
  - Using Docker network isolation to restrict access
  - Binding to localhost (`127.0.0.1`) if only local access is needed
  - Adding authentication to the control port (HashedControlPassword or CookieAuthentication)
  - Not exposing ports to the host if only inter-container communication is required
- The control port allows programmatic control of Tor and should be protected in production

## Building from Source

```bash
# Clone the repository
git clone https://github.com/andrew-stclair/docker-tor-socks.git
cd docker-tor-socks

# Build the image
docker build -t tor-socks:local .

# Run the locally built image
docker run -d -p 9050:9050 -p 9051:9051 tor-socks:local
```

### Multi-Architecture Build

```bash
# Set up buildx
docker buildx create --use

# Build for multiple architectures
docker buildx build \
  --platform linux/amd64,linux/arm64,linux/arm/v7 \
  -t tor-socks:multi-arch \
  --load \
  .
```

## Supported Architectures

- linux/amd64 (x86_64)
- linux/arm64 (aarch64)
- linux/arm/v7 (armhf)

> **Note**: Additional architectures (386, ppc64le, s390x) are not currently supported due to Tor package availability in Alpine Linux repositories.

## License

This project is open source and available under the MIT License.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Acknowledgments

- Built on [Alpine Linux](https://alpinelinux.org/)
- Uses [Tor Project](https://www.torproject.org/) software
