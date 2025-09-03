/*
 * src/main.cpp
 *
 * Copyright 2024 SimpleDaemons
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include <iostream>
#include <string>
#include <memory>
#include <csignal>
#include <atomic>

#include "simple_snmpd/snmp_server.hpp"
#include "simple_snmpd/snmp_config.hpp"
#include "simple_snmpd/logger.hpp"
#include "simple_snmpd/error_handler.hpp"

// Global variables for signal handling
std::atomic<bool> g_running{true};
std::unique_ptr<simple_snmpd::SNMPServer> g_server;

// Signal handler
void signal_handler(int signal) {
    switch (signal) {
        case SIGINT:
        case SIGTERM:
            std::cout << "\nReceived signal " << signal << ", shutting down gracefully...\n";
            g_running = false;
            if (g_server) {
                g_server->stop();
            }
            break;
        case SIGHUP:
            std::cout << "Received SIGHUP, reloading configuration...\n";
            // TODO: Implement configuration reload
            break;
        default:
            break;
    }
}

// Setup signal handlers
void setup_signal_handlers() {
    std::signal(SIGINT, signal_handler);
    std::signal(SIGTERM, signal_handler);
    std::signal(SIGHUP, signal_handler);

    // Ignore SIGPIPE
    std::signal(SIGPIPE, SIG_IGN);
}

// Print usage information
void print_usage(const char* program_name) {
    std::cout << "Usage: " << program_name << " [OPTIONS]\n";
    std::cout << "Options:\n";
    std::cout << "  -c, --config FILE    Configuration file path\n";
    std::cout << "  -d, --daemon         Run as daemon\n";
    std::cout << "  -f, --foreground     Run in foreground (default)\n";
    std::cout << "  -t, --test-config    Test configuration and exit\n";
    std::cout << "  -v, --verbose        Verbose output\n";
    std::cout << "  -h, --help           Show this help message\n";
    std::cout << "  -V, --version        Show version information\n";
}

// Print version information
void print_version() {
    std::cout << "simple-snmpd version 0.1.0\n";
    std::cout << "Copyright 2024 SimpleDaemons\n";
    std::cout << "Licensed under the Apache License, Version 2.0\n";
}

int main(int argc, char* argv[]) {
    std::string config_file = "/etc/simple-snmpd/simple-snmpd.conf";
    bool daemon_mode = false;
    bool test_config = false;
    bool verbose = false;

    // Parse command line arguments
    for (int i = 1; i < argc; ++i) {
        std::string arg = argv[i];

        if (arg == "-c" || arg == "--config") {
            if (i + 1 < argc) {
                config_file = argv[++i];
            } else {
                std::cerr << "Error: --config requires a file path\n";
                return 1;
            }
        } else if (arg == "-d" || arg == "--daemon") {
            daemon_mode = true;
        } else if (arg == "-f" || arg == "--foreground") {
            daemon_mode = false;
        } else if (arg == "-t" || arg == "--test-config") {
            test_config = true;
        } else if (arg == "-v" || arg == "--verbose") {
            verbose = true;
        } else if (arg == "-h" || arg == "--help") {
            print_usage(argv[0]);
            return 0;
        } else if (arg == "-V" || arg == "--version") {
            print_version();
            return 0;
        } else {
            std::cerr << "Error: Unknown option " << arg << "\n";
            print_usage(argv[0]);
            return 1;
        }
    }

    try {
        // Initialize logger
        simple_snmpd::Logger::get_instance().initialize(verbose ? simple_snmpd::LogLevel::DEBUG : simple_snmpd::LogLevel::INFO);

        // Load configuration
        simple_snmpd::SNMPConfig config;
        if (!config.load(config_file)) {
            std::cerr << "Error: Failed to load configuration from " << config_file << "\n";
            return 1;
        }

        if (test_config) {
            std::cout << "Configuration test passed\n";
            return 0;
        }

        // Setup signal handlers
        setup_signal_handlers();

        // Create and configure SNMP server
        g_server = std::make_unique<simple_snmpd::SNMPServer>(config);

        if (!g_server->initialize()) {
            std::cerr << "Error: Failed to initialize SNMP server\n";
            return 1;
        }

        // Start the server
        if (!g_server->start()) {
            std::cerr << "Error: Failed to start SNMP server\n";
            return 1;
        }

        std::cout << "Simple SNMP Daemon started successfully\n";
        std::cout << "Listening on port " << config.get_port() << "\n";

        // Main loop
        while (g_running) {
            // TODO: Implement main server loop
            std::this_thread::sleep_for(std::chrono::milliseconds(100));
        }

        // Stop the server
        g_server->stop();
        std::cout << "Simple SNMP Daemon stopped\n";

    } catch (const std::exception& e) {
        std::cerr << "Error: " << e.what() << "\n";
        return 1;
    }

    return 0;
}
