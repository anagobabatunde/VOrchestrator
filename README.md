# VOrchestrator

A lightweight, single-binary container orchestration tool built in Vlang.

## Overview

VOrchestrator is a simple tool that allows you to manage small-scale containerized workloads with a focus on:

- Speed and low resource usage (thanks to Vlang's performance)
- Single binary deployment
- Simple JSON configuration
- Basic container management capabilities

Perfect for:
- Solo developers and small teams
- Homelab enthusiasts
- DevOps engineers experimenting with lightweight orchestration

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

## Current Limitations

- No auto-scaling or service discovery
- No support for container networks (relies on Docker's default networking)
- CLI only (no GUI)
- No support for non-Docker runtimes

## Future Roadmap

- Health checks and self-healing capabilities
- Service discovery
- Persistent volumes management
- Improved container networking options
- Support for additional container runtimes

## License

MIT License - See the LICENSE file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Open a Pull Request
