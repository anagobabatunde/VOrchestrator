module config

import json
import os

// Service represents a single container service defined in the configuration
pub struct Service {
pub:
	name        string
	image       string
	ports       []string
	environment map[string]string
}

// Config represents the full application configuration
pub struct Config {
pub:
	services map[string]Service
}

// RawConfig is used for initial JSON parsing
struct RawConfig {
	services map[string]RawService
}

// RawService is used for initial JSON parsing
struct RawService {
	image       string
	ports       []string
	environment map[string]string
}

// load_config loads the configuration from a file path
pub fn load_config(path string) !Config {
	// Check if file exists
	if !os.exists(path) {
		return error('Config file not found: ${path}')
	}
	
	// Read file content
	content := os.read_file(path) or {
		return error('Failed to read config file: ${err}')
	}
	
	// Parse JSON
	raw_config := json.decode(RawConfig, content) or {
		return error('Failed to parse config file: ${err}')
	}
	
	// Convert to our Config structure
	mut services := map[string]Service{}
	
	for name, raw_service in raw_config.services {
		services[name] = Service{
			name: name
			image: raw_service.image
			ports: raw_service.ports
			environment: raw_service.environment
		}
	}
	
	config := Config{
		services: services
	}
	
	// Validate config
	if !config.validate() {
		return error('Invalid configuration')
	}
	
	return config
}

// validate checks if the configuration is valid
pub fn (c Config) validate() bool {
	if c.services.len == 0 {
		println('Error: No services defined in config')
		return false
	}
	
	for name, service in c.services {
		if service.image == '' {
			println('Error: Service "${name}" has no image specified')
			return false
		}
	}
	
	return true
}

// print_config prints the configuration for debugging
pub fn (c Config) print_config() {
	println('Configuration:')
	println('  Services: ${c.services.len}')
	
	for name, service in c.services {
		println('  - ${name}:')
		println('    Image: ${service.image}')
		println('    Ports: ${service.ports}')
		
		if service.environment.len > 0 {
			println('    Environment:')
			for key, value in service.environment {
				println('      ${key}: ${value}')
			}
		}
	}
}
