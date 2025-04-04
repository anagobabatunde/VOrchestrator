module cli

import os
import src.config
import src.docker

// Default config file path
const default_config_path = 'vorc.json'

// CommandHandler is a function type for handling CLI commands
pub type CommandHandler = fn ([]string) !

// Command represents a CLI command
pub struct Command {
pub:
	name        string
	description string
	handler     CommandHandler = unsafe { nil }
}

// register_commands sets up all the application commands
pub fn register_commands() map[string]Command {
	mut commands := map[string]Command{}
	
	commands['up'] = Command{
		name: 'up',
		description: 'Start containers from config file',
		handler: up_command
	}
	
	commands['down'] = Command{
		name: 'down',
		description: 'Stop containers',
		handler: down_command
	}
	
	commands['ps'] = Command{
		name: 'ps',
		description: 'List running containers',
		handler: ps_command
	}
	
	commands['stop-all'] = Command{
		name: 'stop-all',
		description: 'Stop all running containers',
		handler: stop_all_command
	}
	
	commands['health'] = Command{
		name: 'health',
		description: 'Check health status of running containers',
		handler: health_command
	}
	
	return commands
}

// Parse parses command line arguments and executes the appropriate command
pub fn parse_and_execute() ! {
	if os.args.len <= 1 {
		print_usage()
		return
	}
	
	commands := register_commands()
	command_name := os.args[1]
	
	if command_name in commands {
		command := commands[command_name]
		command.handler(os.args[2..]) or {
			println('Error executing command: ${err}')
			return err
		}
	} else {
		println('Unknown command: ${command_name}')
		print_usage()
	}
}

// print_usage prints the usage instructions
pub fn print_usage() {
	println('Usage:')
	commands := register_commands()
	for name, cmd in commands {
		// Format the command with padding
		padded_name := name + '          ' // Add padding
		println('  vorchestrator ${padded_name[..10]} - ${cmd.description}')
	}
}

// Command handlers
fn up_command(args []string) ! {
	// First, make sure we clean up any conflicting containers
	println('Checking for existing containers...')
	
	// Determine config file path
	mut config_path := cli.default_config_path
	
	// If user specified a config path, use it
	if args.len > 0 {
		config_path = args[0]
	}
	
	println('Loading configuration from ${config_path}...')
	
	// Load config file
	cfg := config.load_config(config_path) or {
		return error('Failed to load config: ${err}')
	}
	
	// Print the loaded config for debugging
	cfg.print_config()
	
	// Start each service defined in the config
	mut success_count := 0
	mut failure_count := 0
	
	for name, service in cfg.services {
		println('Starting service: ${name}')
		
		// Start container using docker module
		container_id := docker.start_container(
			service.image, 
			name, 
			service.ports, 
			service.environment
		) or {
			println('Error starting container for service ${name}: ${err}')
			failure_count++
			continue
		}
		
		println('Started container ${container_id} for service ${name}')
		success_count++
	}
	
	println('Services started: ${success_count} success, ${failure_count} failed')
}

fn down_command(args []string) ! {
	// If no args provided, stop all containers
	if args.len == 0 {
		println('No specific services specified - stopping all containers')
		return stop_all_command(args)
	}
	
	// Determine config file path
	mut config_path := cli.default_config_path
	
	// If user specified a config path, use it
	if args.len > 0 && os.exists(args[0]) {
		config_path = args[0]
		println('Loading configuration from ${config_path}...')
		
		// Load config file
		cfg := config.load_config(config_path) or {
			return error('Failed to load config: ${err}')
		}
		
		// Stop each service defined in the config
		mut success_count := 0
		mut failure_count := 0
		
		for name, _ in cfg.services {
			println('Stopping service: ${name}')
			
			// Stop container using docker module
			docker.stop_container(name) or {
				println('Error stopping container for service ${name}: ${err}')
				failure_count++
				continue
			}
			
			println('Stopped container for service ${name}')
			success_count++
		}
		
		println('Services stopped: ${success_count} success, ${failure_count} failed')
		return
	}
	
	// Otherwise, treat arguments as container names to stop
	mut success_count := 0
	mut failure_count := 0
	
	for name in args {
		println('Stopping container: ${name}')
		
		// Stop container using docker module
		docker.stop_container(name) or {
			println('Error stopping container: ${err}')
			failure_count++
			continue
		}
		
		println('Stopped container: ${name}')
		success_count++
	}
	
	println('Containers stopped: ${success_count} success, ${failure_count} failed')
}

fn stop_all_command(args []string) ! {
	println('Stopping all running containers...')
	
	docker.stop_all_containers() or {
		return error('Failed to stop containers: ${err}')
	}
	
	println('All containers stopped successfully')
}

fn ps_command(args []string) ! {
	println('Listing containers...')
	
	// List containers using docker module
	containers := docker.list_containers() or {
		return error('Failed to list containers: ${err}')
	}
	
	if containers.len == 0 {
		println('No containers running.')
		return
	}
	
	println('Running containers:')
	println('ID\t\tNAME\t\tIMAGE\t\tSTATUS\t\tHEALTH')
	
	for container in containers {
		println('${container.id}\t${container.name}\t${container.image}\t${container.status}\t${container.health}')
	}
}

fn health_command(args []string) ! {
	println('Checking container health...')
	
	// Get health status for all containers
	health_map := docker.get_containers_health() or {
		return error('Failed to check container health: ${err}')
	}
	
	if health_map.len == 0 {
		println('No containers running.')
		return
	}
	
	println('Container health status:')
	println('NAME\t\tHEALTH STATUS')
	
	for name, health in health_map {
		status_str := match health {
			.healthy { 'HEALTHY' }
			.unhealthy { 'UNHEALTHY' }
			.starting { 'STARTING' }
			.unknown { 'UNKNOWN/NOT SUPPORTED' }
		}
		
		println('${name}\t\t${status_str}')
	}
	
	// Check for unhealthy containers
	mut unhealthy_count := 0
	for _, health in health_map {
		if health == .unhealthy {
			unhealthy_count++
		}
	}
	
	if unhealthy_count > 0 {
		println('\nWARNING: ${unhealthy_count} container(s) are unhealthy!')
	} else {
		println('\nAll containers are healthy or starting.')
	}
}
