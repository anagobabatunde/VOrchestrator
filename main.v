module main

import src.cli
import src.docker

fn main() {
	// Print welcome message
	println('VOrchestrator - A lightweight container orchestration tool')
	println('Version: 0.1.0')
	
	// Check if Docker is available
	if !docker.check_docker_available() {
		println('Error: Docker is not available on this system.')
		println('Please install Docker before using VOrchestrator.')
		exit(1)
	}
	
	// Parse and execute commands
	cli.parse_and_execute() or {
		println('Error: ${err}')
		exit(1)
	}
}
