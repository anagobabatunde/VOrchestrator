module main

import os
import time
import math
import term

// Benchmark tracks various performance metrics
struct BenchmarkResult {
	name            string
	duration_ms     int
	memory_kb       int
	binary_size_kb  int
	cpu_percentage  f64
}

fn main() {
	println(term.bold('VOrchestrator Performance Benchmark'))
	println('======================================')
	
	// Ensure VOrchestrator is built with optimizations
	println('\nBuilding VOrchestrator with optimizations...')
	build_result := os.system('cd .. && v -prod -o VOrchestrator main.v')
	if build_result != 0 {
		println('Failed to build VOrchestrator. Exiting benchmark.')
		exit(1)
	}
	
	// Measure binary size
	binary_size := measure_binary_size('../VOrchestrator')
	println('Binary size: ${binary_size / 1024} KB (${binary_size / (1024 * 1024)} MB)')
	
	// Kill any existing VOrchestrator processes
	os.system('pkill -f VOrchestrator || true')
	
	// Clean any existing containers
	os.system('../VOrchestrator stop-all')
	time.sleep(2 * time.second)
	
	// Run the benchmarks
	benchmarks := [
		benchmark_startup(),
		benchmark_container_startup(),
		benchmark_container_monitoring(),
		benchmark_multiple_containers()
	]
	
	// Print benchmark results table
	println('\nBenchmark Results')
	println('================')
	println('Operation                  | Duration (ms) | Memory (KB) | CPU Usage (%)')
	println('---------------------------|---------------|-------------|-------------')
	
	for b in benchmarks {
		name_padded := b.name + '                         '
		println('${name_padded[..25]} | ${b.duration_ms:13} | ${b.memory_kb:11} | ${b.cpu_percentage:13.2f}')
	}
	
	// Check against requirements
	println('\nRequirements Check')
	println('=================')
	println('Binary size: ${binary_size / 1024} KB - Target: <10,240 KB (10 MB) - ${if binary_size < 10240 * 1024 { term.green('PASSED') } else { term.red('FAILED') }}')
	
	// Get max memory usage
	max_memory := 0
	for b in benchmarks {
		if b.memory_kb > max_memory {
			max_memory = b.memory_kb
		}
	}
	
	println('Max memory usage: ${max_memory} KB - Target: <51,200 KB (50 MB) - ${if max_memory < 51200 { term.green('PASSED') } else { term.red('FAILED') }}')
	
	// Clean up
	os.system('../VOrchestrator stop-all')
}

// Measure base application startup time
fn benchmark_startup() BenchmarkResult {
	println('\nBenchmarking application startup...')
	
	// Run VOrchestrator help and measure time
	start := time.now()
	result := os.execute('../VOrchestrator')
	duration := time.now() - start
	
	// Measure memory usage
	memory := measure_memory('VOrchestrator')
	cpu := measure_cpu('VOrchestrator')
	
	duration_ms := int(math.ceil(duration / time.millisecond))
	println('  Startup time: ${duration_ms}ms')
	println('  Memory usage: ${memory}KB')
	println('  CPU usage: ${cpu}%')
	
	return BenchmarkResult{
		name: 'Application Startup',
		duration_ms: duration_ms,
		memory_kb: memory,
		binary_size_kb: 0,
		cpu_percentage: cpu
	}
}

// Benchmark container startup performance
fn benchmark_container_startup() BenchmarkResult {
	println('\nBenchmarking container startup (single container)...')
	
	// Clean up any existing containers
	os.system('../VOrchestrator stop-all')
	time.sleep(2 * time.second)
	
	// Create a minimal config for a single container
	os.system('mkdir -p temp')
	os.write_file('temp/single.json', '{"services":{"web":{"image":"nginx:latest","ports":["8080:80"],"env":{"DEBUG":"false"}}}}') or {
		println('Error creating config file: ${err}')
		return BenchmarkResult{name: 'Container Startup (Failed)', duration_ms: 0, memory_kb: 0, binary_size_kb: 0, cpu_percentage: 0}
	}
	
	// Run and measure startup time for a single container
	start := time.now()
	os.system('../VOrchestrator up --config=temp/single.json')
	duration := time.now() - start
	
	// Measure memory and CPU
	memory := measure_memory('VOrchestrator')
	cpu := measure_cpu('VOrchestrator')
	
	duration_ms := int(math.ceil(duration / time.millisecond))
	println('  Startup time: ${duration_ms}ms')
	println('  Memory usage: ${memory}KB')
	println('  CPU usage: ${cpu}%')
	
	// Clean up
	os.system('../VOrchestrator stop-all')
	
	return BenchmarkResult{
		name: 'Container Startup (1)',
		duration_ms: duration_ms,
		memory_kb: memory,
		binary_size_kb: 0,
		cpu_percentage: cpu
	}
}

// Benchmark health monitoring performance
fn benchmark_container_monitoring() BenchmarkResult {
	println('\nBenchmarking container health monitoring...')
	
	// Clean up any existing containers
	os.system('../VOrchestrator stop-all')
	time.sleep(2 * time.second)
	
	// Start a container for monitoring
	os.system('../VOrchestrator up --config=temp/single.json')
	time.sleep(5 * time.second) // Wait for container to initialize
	
	// Measure health check performance
	start := time.now()
	os.system('../VOrchestrator health')
	duration := time.now() - start
	
	// Measure memory and CPU
	memory := measure_memory('VOrchestrator')
	cpu := measure_cpu('VOrchestrator')
	
	duration_ms := int(math.ceil(duration / time.millisecond))
	println('  Health check time: ${duration_ms}ms')
	println('  Memory usage: ${memory}KB')
	println('  CPU usage: ${cpu}%')
	
	// Clean up
	os.system('../VOrchestrator stop-all')
	
	return BenchmarkResult{
		name: 'Health Monitoring',
		duration_ms: duration_ms,
		memory_kb: memory,
		binary_size_kb: 0,
		cpu_percentage: cpu
	}
}

// Benchmark with multiple containers
fn benchmark_multiple_containers() BenchmarkResult {
	println('\nBenchmarking multiple container management...')
	
	// Clean up any existing containers
	os.system('../VOrchestrator stop-all')
	time.sleep(2 * time.second)
	
	// Create a config for multiple containers
	os.write_file('temp/multi.json', '{"services":{"web":{"image":"nginx:latest","ports":["8080:80"],"env":{"DEBUG":"false"}},"api":{"image":"httpd:latest","ports":["8081:80"],"env":{"DEBUG":"false"}},"db":{"image":"postgres:14","ports":["5432:5432"],"env":{"POSTGRES_PASSWORD":"benchmark","POSTGRES_USER":"benchmark"}}}}') or {
		println('Error creating config file: ${err}')
		return BenchmarkResult{name: 'Multiple Containers (Failed)', duration_ms: 0, memory_kb: 0, binary_size_kb: 0, cpu_percentage: 0}
	}
	
	// Run and measure startup time for multiple containers
	start := time.now()
	os.system('../VOrchestrator up --config=temp/multi.json')
	duration := time.now() - start
	
	// Measure memory and CPU
	memory := measure_memory('VOrchestrator')
	cpu := measure_cpu('VOrchestrator')
	
	duration_ms := int(math.ceil(duration / time.millisecond))
	println('  Multi-container startup time: ${duration_ms}ms')
	println('  Memory usage: ${memory}KB')
	println('  CPU usage: ${cpu}%')
	
	// Clean up
	os.system('../VOrchestrator stop-all')
	os.system('rm -rf temp')
	
	return BenchmarkResult{
		name: 'Multiple Containers (3)',
		duration_ms: duration_ms,
		memory_kb: memory,
		binary_size_kb: 0,
		cpu_percentage: cpu
	}
}

// Helper function to measure memory usage
fn measure_memory(process_name string) int {
	memory_output := os.execute('ps -eo rss,comm | grep ${process_name} | grep -v grep')
	
	if memory_output.exit_code == 0 && memory_output.output.trim_space() != '' {
		parts := memory_output.output.trim_space().split(' ')
		for part in parts {
			if part.trim_space() != '' {
				mem_val := part.trim_space().int()
				if mem_val > 0 {
					return mem_val
				}
			}
		}
	}
	
	// If we failed to get memory, try another approach with ps aux
	memory_output2 := os.execute('ps aux | grep ${process_name} | grep -v grep')
	if memory_output2.exit_code == 0 && memory_output2.output.trim_space() != '' {
		lines := memory_output2.output.trim_space().split('\n')
		if lines.len > 0 {
			fields := lines[0].split(' ').filter(it.trim_space() != '')
			if fields.len > 5 {
				// Memory percentage is usually in field 3 or 4
				for i := 3; i < 6 && i < fields.len; i++ {
					mem_val := fields[i].f64()
					if mem_val > 0 {
						// Convert percentage to KB (rough estimate based on total system memory)
						system_memory := os.execute('sysctl -n hw.memsize')
						if system_memory.exit_code == 0 {
							total_kb := system_memory.output.trim_space().u64() / 1024
							return int(total_kb * mem_val / 100)
						}
					}
				}
			}
		}
	}
	
	return 0
}

// Helper function to measure CPU usage
fn measure_cpu(process_name string) f64 {
	cpu_output := os.execute('ps -eo %cpu,comm | grep ${process_name} | grep -v grep')
	
	if cpu_output.exit_code == 0 && cpu_output.output.trim_space() != '' {
		parts := cpu_output.output.trim_space().split(' ')
		for part in parts {
			if part.trim_space() != '' {
				cpu_val := part.trim_space().f64()
				if cpu_val > 0 {
					return cpu_val
				}
			}
		}
	}
	
	return 0
}

// Helper function to measure binary size
fn measure_binary_size(binary_path string) i64 {
	if os.exists(binary_path) {
		file_info := os.stat(binary_path) or {
			println('Error getting file info: ${err}')
			return 0
		}
		
		return file_info.size
	}
	
	return 0
}
