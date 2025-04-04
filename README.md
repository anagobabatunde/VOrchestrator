<p align="center">
  <img src="assets/VOchestrator-logo.png" alt="VOrchestrator Logo" width="300">
</p>

# VOrchestrator

A lightweight, single-binary container orchestration tool built in Vlang.

## Overview

VOrchestrator is a simple tool that allows you to manage small-scale containerized workloads with a focus on:

- Speed and low resource usage (thanks to Vlang's performance)
- Single binary deployment
- Simple JSON configuration
- Basic container management capabilities
- Container health monitoring

Perfect for:
- Solo developers and small teams
- Homelab enthusiasts
- DevOps engineers experimenting with lightweight orchestration

## Performance

VOrchestrator is designed to be lightweight and efficient. Our benchmarks show impressive results:

| Operation | Duration (ms) | Memory (KB) | CPU Usage (%) |
|-----------|---------------|-------------|---------------|
| Application Startup | 60 | 1,728 | 0.30 |
| Container Startup (1) | 3,822 | 1,232 | 0.10 |
| Health Monitoring | 273 | 1,168 | 0.20 |
| Multiple Containers (3) | 5,558 | 1,136 | 0.10 |

**Key Metrics:**
- **Binary Size**: Only 226 KB (Target: <10 MB)
- **Memory Usage**: Maximum 1.7 MB (Target: <50 MB)
- **Startup Time**: Base application starts in just 60ms

These benchmarks were performed using the included testing tools in the `tests/benchmarks` directory.

## Installation

### Prerequisites

- [Docker](https://docs.docker.com/get-docker/) must be installed and running
- For building from source: [V Programming Language](https://vlang.io/)

### Using a Pre-built Binary

Download the latest release from the GitHub releases page (coming soon).

```bash
# Make executable
chmod +x vorchestrator

# Move to a directory in your PATH (optional)
sudo mv vorchestrator /usr/local/bin/
```

### Building from Source

```bash
# Clone repository
git clone https://github.com/yourusername/vorchestrator.git
cd vorchestrator

# Build the binary
v .

# Make a symlink (optional)
sudo ln -sf "$(pwd)/VOrchestrator" /usr/local/bin/vorchestrator
```

## Usage

VOrchestrator offers several commands for managing containers:

```bash
# Start containers defined in a config file
vorchestrator up [config-file-path]

# Stop containers defined in a config file
vorchestrator down [config-file-path]

# List running containers
vorchestrator ps

# Check health status of running containers
vorchestrator health

# Stop all running containers
vorchestrator stop-all
```

If no config file is specified, VOrchestrator looks for `vorc.json` in the current directory.

## Configuration

VOrchestrator uses a simple JSON configuration file to define container services.

### Example Configuration

```json
{
  "services": {
    "web": {
      "image": "nginx:latest",
      "ports": ["8080:80"],
      "environment": {
        "DEBUG": "true"
      }
    },
    "api": {
      "image": "httpd:latest",
      "ports": ["8081:80"],
      "environment": {
        "API_KEY": "demo-key"
      }
    },
    "db": {
      "image": "postgres:14",
      "ports": ["5433:5432"],
      "environment": {
        "POSTGRES_PASSWORD": "example",
        "POSTGRES_USER": "postgres",
        "POSTGRES_DB": "app"
      }
    }
  }
}
```

### Configuration Options

Each service in the configuration can include:

- `image`: Docker image to use (required)
- `ports`: Array of port mappings in the format "host:container"
- `environment`: Key-value pairs of environment variables

## Examples

### Basic Three-Tier Application

Save as `vorc.json`:

```json
{
  "services": {
    "web": {
      "image": "nginx:latest",
      "ports": ["8080:80"]
    },
    "api": {
      "image": "node:alpine",
      "ports": ["3000:3000"],
      "environment": {
        "DB_HOST": "db",
        "NODE_ENV": "development"
      }
    },
    "db": {
      "image": "mongo:latest",
      "ports": ["27017:27017"],
      "environment": {
        "MONGO_INITDB_ROOT_USERNAME": "admin",
        "MONGO_INITDB_ROOT_PASSWORD": "password"
      }
    }
  }
}
```

Run with:

```bash
vorchestrator up
```

### Stopping Specific Containers

To stop specific containers:

```bash
vorchestrator down web db
```

### Monitoring Container Health

VOrchestrator includes built-in health monitoring for containers:

```bash
vorchestrator health
```

This will display the health status of all running containers managed by VOrchestrator, indicating whether each container is healthy, unhealthy, or still starting up.

## Testing

VOrchestrator includes comprehensive testing capabilities:

- **Integration Tests**: Test the full functionality with multiple containers
- **Error Case Testing**: Verify proper handling of configuration errors
- **Performance Benchmarks**: Measure and verify system requirements

To run the tests:

```bash
cd tests
v run run_tests.v
```

To run benchmarks:

```bash
cd tests/benchmarks
v run benchmark.v
```

## Current Limitations

- No auto-scaling or service discovery
- No support for container networks (relies on Docker's default networking)
- CLI only (no GUI)
- No support for non-Docker runtimes

## Future Roadmap

VOrchestrator is under active development. Our future plans include:

- Additional health check customization options
- Service discovery
- Persistent volumes management
- Improved container networking options
- Support for additional container runtimes

For a detailed development roadmap with version targets and feature descriptions, see our [ROADMAP.md](ROADMAP.md) file.

## License

MIT License - See the LICENSE file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Open a Pull Request
