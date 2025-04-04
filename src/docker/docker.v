module docker

import os
import time

// Container represents a Docker container
pub struct Container {
pub:
	id          string
	name        string
	image       string
	status      string
	created_at  string
	ports       []string
	health      string   // Added health status field
}

// ContainerHealth represents the health status of a container
pub enum ContainerHealth {
	healthy
	unhealthy
	starting
	unknown
}

// cleanup_existing_container removes a container with the same name if it exists
fn cleanup_existing_container(name string) ! {
	// Check if container exists
	result := os.execute('docker ps -a --filter "name=^/${name}$" --format "{{.Names}}"')
	
	if result.exit_code != 0 {
		return error('Failed to check for existing container: ${result.output}')
	}
	
	// If container exists, remove it
	if result.output.trim_space() != '' {
		println('Container ${name} already exists, removing it...')
		
		rm_result := os.execute('docker rm -f ${name}')
		
		if rm_result.exit_code != 0 {
			return error('Failed to remove existing container: ${rm_result.output}')
		}
		
		println('Removed existing container: ${name}')
	}
}

// start_container starts a Docker container based on the provided parameters
pub fn start_container(image string, name string, ports []string, env map[string]string) !string {
	// First, clean up any existing container with the same name
	cleanup_existing_container(name) or {
		println('Warning: Failed to clean up existing container: ${err}')
		// Continue despite cleanup failure
	}
	
	// Build docker run command
	mut cmd := 'docker run -d --name ${name}'
	
	// Add health check (for supported images)
	cmd += ' --health-cmd="curl --fail http://localhost || exit 1" --health-interval=5s --health-retries=3'
	
	// Add ports
	for port in ports {
		cmd += ' -p ${port}'
	}
	
	// Add environment variables
	for key, value in env {
		cmd += ' -e ${key}=${value}'
	}
	
	// Add the image name
	cmd += ' ${image}'
	
	// Execute the command
	result := os.execute(cmd)
	
	if result.exit_code != 0 {
		return error('Docker run failed: ${result.output}')
	}
	
	// Return the container ID from the output (strip newline)
	container_id := result.output.trim_space()
	
	// Wait a bit and check the initial status
	time.sleep(1 * time.second)
	check_container_health(container_id) or {}
	
	return container_id
}

// stop_container stops a Docker container by its ID or name
pub fn stop_container(id_or_name string) ! {
	// First try to stop gracefully
	stop_result := os.execute('docker stop ${id_or_name}')
	
	if stop_result.exit_code != 0 {
		// If stop fails, try to force remove
		rm_result := os.execute('docker rm -f ${id_or_name}')
		
		if rm_result.exit_code != 0 {
			return error('Failed to stop container: ${stop_result.output}, Failed to remove: ${rm_result.output}')
		}
		
		println('Container ${id_or_name} was force removed')
		return
	}
	
	println('Container ${id_or_name} stopped successfully')
}

// list_containers returns a list of running containers
pub fn list_containers() ![]Container {
	// Execute docker ps to get running containers with health status
	result := os.execute('docker ps --format "{{.ID}}|{{.Names}}|{{.Image}}|{{.Status}}|{{.Ports}}|{{.Health}}"')
	
	if result.exit_code != 0 {
		return error('Failed to list containers: ${result.output}')
	}
	
	mut containers := []Container{}
	
	// If output is empty, return empty list
	if result.output.trim_space() == '' {
		return containers
	}
	
	// Parse the output into containers
	lines := result.output.split('\n')
	for line in lines {
		if line.trim_space() == '' {
			continue
		}
		
		parts := line.split('|')
		if parts.len < 5 {
			continue // Skip malformed lines
		}
		
		// Parse ports from the format string
		port_str := parts[4]
		mut ports := []string{}
		
		if port_str.trim_space() != '' {
			port_parts := port_str.split(', ')
			for p in port_parts {
				ports << p
			}
		}
		
		// Extract health status (may be empty if health checks not configured)
		mut health := 'N/A'
		if parts.len > 5 {
			health = parts[5]
		}
		
		containers << Container{
			id: parts[0]
			name: parts[1]
			image: parts[2]
			status: parts[3]
			ports: ports
			health: health
		}
	}
	
	return containers
}

// check_container_health checks the health status of a container
pub fn check_container_health(id_or_name string) !ContainerHealth {
	// Get container health status
	result := os.execute('docker inspect --format="{{.State.Health.Status}}" ${id_or_name}')
	
	if result.exit_code != 0 {
		// Check if container is running at all
		is_running_result := os.execute('docker inspect --format="{{.State.Running}}" ${id_or_name}')
		
		if is_running_result.exit_code != 0 || is_running_result.output.trim_space() != 'true' {
			return ContainerHealth.unhealthy
		}
		
		// Container is running but doesn't have health checks
		return ContainerHealth.unknown
	}
	
	health_status := result.output.trim_space()
	
	match health_status {
		'healthy' { return ContainerHealth.healthy }
		'unhealthy' { return ContainerHealth.unhealthy }
		'starting' { return ContainerHealth.starting }
		else { return ContainerHealth.unknown }
	}
}

// get_containers_health returns a map of container names to health status
pub fn get_containers_health() !map[string]ContainerHealth {
	// Get running containers
	containers := list_containers()!
	
	mut health_map := map[string]ContainerHealth{}
	
	// Check health for each container
	for container in containers {
		health := check_container_health(container.id) or {
			health_map[container.name] = ContainerHealth.unknown
			continue
		}
		
		health_map[container.name] = health
	}
	
	return health_map
}

// stop_all_containers stops all running containers
pub fn stop_all_containers() ! {
	// Get all container IDs
	result := os.execute('docker ps -q')
	
	if result.exit_code != 0 {
		return error('Failed to get running containers: ${result.output}')
	}
	
	// If no containers are running, return
	if result.output.trim_space() == '' {
		println('No containers running')
		return
	}
	
	// Create a list of container IDs from the output
	container_ids := result.output.trim_space().split('\n')
	
	// If there are containers, stop them
	if container_ids.len > 0 {
		// Join IDs with space for the stop command
		ids_str := container_ids.join(' ')
		
		// Stop all containers
		stop_result := os.execute('docker stop ${ids_str}')
		
		if stop_result.exit_code != 0 {
			return error('Failed to stop containers: ${stop_result.output}')
		}
		
		println('Stopped ${container_ids.len} containers')
	}
}

// check_docker_available verifies if Docker is available on the system
pub fn check_docker_available() bool {
	result := os.execute('docker --version')
	return result.exit_code == 0
}
