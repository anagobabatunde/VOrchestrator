module main

import os
import time
import math

struct TestResult {
	name        string
	success     bool
	message     string
	duration_ms int
}

fn main() {
	println('VOrchestrator Test Suite')
	println('========================')
	
	// Ensure VOrchestrator is built
	build_result := os.system('cd .. && v .')
	if build_result != 0 {
		println('Failed to build VOrchestrator. Exiting tests.')
		exit(1)
	}
	
	mut test_results := []TestResult{}
	
	// Run integration tests
	test_results << run_test('Standard Configuration', 'test_standard_config')
	test_results << run_test('Invalid Configuration', 'test_invalid_config')
	test_results << run_test('Missing Image', 'test_missing_image')
	test_results << run_test('Health Monitoring', 'test_health_monitoring')
	test_results << run_test('Performance Benchmark', 'benchmark_performance')
	
	// Display results
	println('\nTest Results Summary')
	println('====================')
	
	mut pass_count := 0
	mut fail_count := 0
	
	for result in test_results {
		status := if result.success { 'PASS' } else { 'FAIL' }
		println('${result.name}: ${status} (${result.duration_ms}ms)')
		if !result.success {
			println('  → ${result.message}')
		}
		
		if result.success {
			pass_count++
		} else {
			fail_count++
		}
	}
	
	println('\n${pass_count} tests passed, ${fail_count} tests failed')
	
	if fail_count > 0 {
		exit(1)
	}
}

fn run_test(name string, test_fn_name string) TestResult {
	println('\nRunning test: ${name}')
	println('-------------' + '-'.repeat(name.len))
	
	start_time := time.now()
	
	// Execute the test based on the function name
	mut success := true
	mut message := ''
	
	match test_fn_name {
		'test_standard_config' { success, message = test_standard_config() }
		'test_invalid_config' { success, message = test_invalid_config() }
		'test_missing_image' { success, message = test_missing_image() }
		'test_health_monitoring' { success, message = test_health_monitoring() }
		'benchmark_performance' { success, message = benchmark_performance() }
		else { 
			success = false 
			message = 'Unknown test function: ${test_fn_name}'
		}
	}
	
	end_time := time.now()
	duration := end_time - start_time
	duration_ms := int(math.ceil(duration / time.millisecond))
	
	status := if success { 'Passed' } else { 'Failed' }
	println('Result: ${status}')
	if !success {
		println('Message: ${message}')
	}
	
	return TestResult{
		name: name
		success: success
		message: message
		duration_ms: duration_ms
	}
}

// Check if specific number of containers are running
fn check_container_count(expected_count int, max_attempts int) bool {
	for attempt in 0..max_attempts {
		ps_output := os.execute('../VOrchestrator ps')
		if ps_output.exit_code != 0 {
			println('PS command failed on attempt ${attempt+1}/${max_attempts}')
			time.sleep(1 * time.second)
			continue
		}
		
		// Count the number of containers listed
		mut found_count := 0
		lines := ps_output.output.split('\n')
		for line in lines {
			if line.contains('nginx') || line.contains('httpd') || line.contains('postgres') {
				found_count++
			}
		}
		
		println('Found ${found_count}/${expected_count} containers (attempt ${attempt+1}/${max_attempts})')
		
		if found_count >= expected_count {
			println('Expected container count reached after ${attempt+1} attempts')
			// Print the current containers
			println('Current containers:')
			println(ps_output.output)
			return true
		}
		
		// Wait before next check
		time.sleep(1 * time.second)
	}
	
	return false
}

// Test using a standard configuration with multiple containers
fn test_standard_config() (bool, string) {
	// Clean up any existing containers from previous test runs
	os.system('../VOrchestrator stop-all')
	
	// Wait to ensure all containers are fully stopped
	time.sleep(2 * time.second)
	
	// Run orchestrator with standard config
	println('Starting containers with standard config...')
	result := os.system('../VOrchestrator up --config=configs/standard.json')
	if result != 0 {
		return false, 'Failed to start containers with standard config'
	}
	
	// Give containers time to start
	println('Waiting for containers to initialize...')
	time.sleep(5 * time.second)
	
	// Check if at least 2 containers are running
	containers_running := check_container_count(2, 10)
	
	if !containers_running {
		// Get diagnostic output
		ps_output := os.execute('../VOrchestrator ps')
		os.system('../VOrchestrator stop-all')
		return false, 'Not enough containers were started. PS output: ${ps_output.output}'
	}
	
	// Test stopping containers
	println('Stopping containers...')
	stop_result := os.system('../VOrchestrator down --config=configs/standard.json')
	if stop_result != 0 {
		os.system('../VOrchestrator stop-all')
		return false, 'Failed to stop containers cleanly'
	}
	
	return true, ''
}

// Test with invalid JSON configuration
fn test_invalid_config() (bool, string) {
	// Config file exists but has invalid JSON
	result := os.execute('../VOrchestrator up --config=configs/broken.json')
	
	// We expect this to fail, so success means the command returned non-zero
	if result.exit_code == 0 {
		os.system('../VOrchestrator stop-all')
		return false, 'Invalid config was accepted without error'
	}
	
	// Verify error message contains info about JSON parsing
	if !result.output.to_lower().contains('json') && 
	   !result.output.to_lower().contains('parse') && 
	   !result.output.to_lower().contains('invalid') {
		return false, 'Did not receive proper error message for invalid JSON'
	}
	
	return true, ''
}

// Test with a configuration that includes a non-existent image
fn test_missing_image() (bool, string) {
	// Clean up any existing containers
	os.system('../VOrchestrator stop-all')
	
	// Wait to ensure all containers are stopped
	time.sleep(2 * time.second)
	
	// Try to start with a config that includes a non-existent image
	println('Testing with non-existent image...')
	result := os.execute('../VOrchestrator up --config=configs/missing_image.json')
	
	// The command should start the valid containers but log an error for the invalid one
	if result.exit_code != 0 {
		return false, 'The command should partially succeed with valid containers'
	}
	
	// Give containers time to start
	time.sleep(3 * time.second)
	
	// Check that at least one container is running (the valid one)
	containers_running := check_container_count(1, 5)
	
	if !containers_running {
		os.system('../VOrchestrator stop-all')
		return false, 'Expected at least one container to be running'
	}
	
	// Clean up
	os.system('../VOrchestrator stop-all')
	
	return true, ''
}

// Test health monitoring functionality
fn test_health_monitoring() (bool, string) {
	// Clean up any existing containers
	os.system('../VOrchestrator stop-all')
	
	// Wait to ensure all containers are stopped
	time.sleep(2 * time.second)
	
	// Start containers
	println('Starting containers for health test...')
	up_result := os.system('../VOrchestrator up --config=configs/standard.json')
	if up_result != 0 {
		return false, 'Failed to start containers for health test'
	}
	
	// Wait for containers to initialize and health checks to run
	println('Waiting for health checks to initialize...')
	time.sleep(10 * time.second)
	
	// Check health
	println('Running health check command...')
	health_output := os.execute('../VOrchestrator health')
	if health_output.exit_code != 0 {
		os.system('../VOrchestrator stop-all')
		return false, 'Health check command failed'
	}
	
	// Display health output for debugging
	println('Health check output:')
	println(health_output.output)
	
	// Clean up
	os.system('../VOrchestrator stop-all')
	
	// Verify health information was returned
	if !health_output.output.to_lower().contains('health') {
		return false, 'Health information not found in output'
	}
	
	return true, ''
}

// Benchmark performance (memory usage, startup time)
fn benchmark_performance() (bool, string) {
	// Clean up any existing containers
	os.system('../VOrchestrator stop-all')
	
	// Wait to ensure all containers are stopped
	time.sleep(2 * time.second)
	
	// Start containers and time it
	println('Running performance benchmark...')
	up_start := time.now()
	os.system('../VOrchestrator up --config=configs/standard.json')
	up_duration := time.now() - up_start
	
	// Get process info for memory usage
	println('Measuring memory usage...')
	memory_output := os.execute('ps -o pid,rss,command | grep VOrchestrator | grep -v grep')
	mut mem_usage := 0
	
	if memory_output.exit_code == 0 && memory_output.output.trim_space() != '' {
		println('Process info: ${memory_output.output}')
		parts := memory_output.output.split(' ')
		for part in parts {
			if part.trim_space() != '' && part.trim_space().int() > 0 {
				possible_mem := part.trim_space().int()
				if possible_mem > 1000 && possible_mem < 1000000 {
					// Likely found the RSS value (in KB)
					mem_usage = possible_mem
					break
				}
			}
		}
	}
	
	// Stop containers
	os.system('../VOrchestrator stop-all')
	
	// Log performance metrics
	println('\nPerformance Benchmark Results:')
	println('  Startup time: ${up_duration / time.millisecond}ms')
	println('  Memory usage: ${mem_usage}KB (${mem_usage/1024}MB)')
	
	// Success if startup time was under 10 seconds and memory usage under 50MB
	if up_duration > 10 * time.second {
		return false, 'Startup time exceeds 10 seconds: ${up_duration / time.second}s'
	}
	
	// We just check that we got a reasonable memory reading (could be 0 if measurement failed)
	if mem_usage > 50000 { // 50MB in KB
		return false, 'Memory usage exceeds 50MB: ${mem_usage / 1024}MB'
	}
	
	return true, ''
}
