# VOrchestrator v0.1.0 Release Notes

We're excited to announce the first release of VOrchestrator, a lightweight container orchestration tool built in Vlang!

## Installation

### Prerequisites

- [Docker](https://docs.docker.com/get-docker/) must be installed and running
- For building from source: [V Programming Language](https://vlang.io/)

### Building from Source

```bash
# Clone repository
git clone https://github.com/anagobabatunde/VOrchestrator.git
cd VOrchestrator

# Build the binary
v .

# Make a symlink (optional)
sudo ln -sf "$(pwd)/VOrchestrator" /usr/local/bin/vorchestrator
```

## Key Features

- **Lightweight Footprint**: Only 226 KB binary size and 1.7 MB memory usage
- **Fast Performance**: Application starts in 60ms
- **Container Management**: Start, stop, and monitor containers with simple commands
- **JSON Configuration**: Define multi-container setups with a simple JSON format
- **Health Monitoring**: Check container health status with dedicated commands

## Usage Examples

```bash
# Start containers defined in vorc.json
vorchestrator up

# List running containers
vorchestrator ps

# Check container health
vorchestrator health

# Stop all running containers
vorchestrator stop-all
```

## What's Next?

Check out our [ROADMAP.md](ROADMAP.md) file to see what's planned for future releases!

## Feedback and Contributions

We welcome your feedback and contributions! Please open issues or pull requests on GitHub.

## Known Limitations

- CLI only (no GUI)
- No support for container networks (relies on Docker's default networking)
- No support for non-Docker runtimes

For more details, see the full [CHANGELOG.md](CHANGELOG.md) and [README.md](README.md).
