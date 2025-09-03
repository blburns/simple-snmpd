/*
 * src/core/snmp_config.cpp
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

#include "simple_snmpd/snmp_config.hpp"
#include "simple_snmpd/logger.hpp"
#include <fstream>
#include <sstream>
#include <algorithm>

namespace simple_snmpd {

SNMPConfig::SNMPConfig() 
    : port_(161)
    , community_("public")
    , max_connections_(100)
    , timeout_seconds_(30)
    , log_level_("info")
    , enable_ipv6_(true)
    , enable_trap_(false)
    , trap_port_(162) {
}

SNMPConfig::~SNMPConfig() {
}

bool SNMPConfig::load(const std::string& config_file) {
    std::ifstream file(config_file);
    if (!file.is_open()) {
        Logger::get_instance().log(LogLevel::ERROR, "Failed to open config file: " + config_file);
        return false;
    }
    
    std::string line;
    int line_number = 0;
    
    while (std::getline(file, line)) {
        line_number++;
        
        // Remove comments and whitespace
        size_t comment_pos = line.find('#');
        if (comment_pos != std::string::npos) {
            line = line.substr(0, comment_pos);
        }
        
        // Trim whitespace
        line.erase(0, line.find_first_not_of(" \t\r\n"));
        line.erase(line.find_last_not_of(" \t\r\n") + 1);
        
        // Skip empty lines
        if (line.empty()) {
            continue;
        }
        
        // Parse key=value pairs
        size_t equal_pos = line.find('=');
        if (equal_pos == std::string::npos) {
            Logger::get_instance().log(LogLevel::WARNING, 
                "Invalid config line " + std::to_string(line_number) + ": " + line);
            continue;
        }
        
        std::string key = line.substr(0, equal_pos);
        std::string value = line.substr(equal_pos + 1);
        
        // Trim key and value
        key.erase(0, key.find_first_not_of(" \t"));
        key.erase(key.find_last_not_of(" \t") + 1);
        value.erase(0, value.find_first_not_of(" \t"));
        value.erase(value.find_last_not_of(" \t") + 1);
        
        // Parse configuration values
        if (!parse_config_value(key, value)) {
            Logger::get_instance().log(LogLevel::WARNING, 
                "Invalid config value at line " + std::to_string(line_number) + 
                ": " + key + "=" + value);
        }
    }
    
    file.close();
    Logger::get_instance().log(LogLevel::INFO, "Configuration loaded from: " + config_file);
    return true;
}

bool SNMPConfig::parse_config_value(const std::string& key, const std::string& value) {
    if (key == "port") {
        try {
            port_ = std::stoi(value);
            if (port_ < 1 || port_ > 65535) {
                Logger::get_instance().log(LogLevel::ERROR, "Invalid port number: " + value);
                return false;
            }
        } catch (const std::exception&) {
            Logger::get_instance().log(LogLevel::ERROR, "Invalid port value: " + value);
            return false;
        }
    } else if (key == "community") {
        community_ = value;
    } else if (key == "max_connections") {
        try {
            max_connections_ = std::stoi(value);
            if (max_connections_ < 1) {
                Logger::get_instance().log(LogLevel::ERROR, "Invalid max_connections: " + value);
                return false;
            }
        } catch (const std::exception&) {
            Logger::get_instance().log(LogLevel::ERROR, "Invalid max_connections value: " + value);
            return false;
        }
    } else if (key == "timeout_seconds") {
        try {
            timeout_seconds_ = std::stoi(value);
            if (timeout_seconds_ < 1) {
                Logger::get_instance().log(LogLevel::ERROR, "Invalid timeout_seconds: " + value);
                return false;
            }
        } catch (const std::exception&) {
            Logger::get_instance().log(LogLevel::ERROR, "Invalid timeout_seconds value: " + value);
            return false;
        }
    } else if (key == "log_level") {
        std::string level = value;
        std::transform(level.begin(), level.end(), level.begin(), ::tolower);
        if (level == "debug" || level == "info" || level == "warning" || 
            level == "error" || level == "fatal") {
            log_level_ = level;
        } else {
            Logger::get_instance().log(LogLevel::ERROR, "Invalid log_level: " + value);
            return false;
        }
    } else if (key == "enable_ipv6") {
        std::string val = value;
        std::transform(val.begin(), val.end(), val.begin(), ::tolower);
        enable_ipv6_ = (val == "true" || val == "1" || val == "yes");
    } else if (key == "enable_trap") {
        std::string val = value;
        std::transform(val.begin(), val.end(), val.begin(), ::tolower);
        enable_trap_ = (val == "true" || val == "1" || val == "yes");
    } else if (key == "trap_port") {
        try {
            trap_port_ = std::stoi(value);
            if (trap_port_ < 1 || trap_port_ > 65535) {
                Logger::get_instance().log(LogLevel::ERROR, "Invalid trap_port: " + value);
                return false;
            }
        } catch (const std::exception&) {
            Logger::get_instance().log(LogLevel::ERROR, "Invalid trap_port value: " + value);
            return false;
        }
    } else {
        Logger::get_instance().log(LogLevel::WARNING, "Unknown config key: " + key);
        return false;
    }
    
    return true;
}

uint16_t SNMPConfig::get_port() const {
    return port_;
}

const std::string& SNMPConfig::get_community() const {
    return community_;
}

uint32_t SNMPConfig::get_max_connections() const {
    return max_connections_;
}

uint32_t SNMPConfig::get_timeout_seconds() const {
    return timeout_seconds_;
}

const std::string& SNMPConfig::get_log_level() const {
    return log_level_;
}

bool SNMPConfig::is_ipv6_enabled() const {
    return enable_ipv6_;
}

bool SNMPConfig::is_trap_enabled() const {
    return enable_trap_;
}

uint16_t SNMPConfig::get_trap_port() const {
    return trap_port_;
}

void SNMPConfig::set_port(uint16_t port) {
    port_ = port;
}

void SNMPConfig::set_community(const std::string& community) {
    community_ = community;
}

void SNMPConfig::set_max_connections(uint32_t max_connections) {
    max_connections_ = max_connections;
}

void SNMPConfig::set_timeout_seconds(uint32_t timeout_seconds) {
    timeout_seconds_ = timeout_seconds;
}

void SNMPConfig::set_log_level(const std::string& log_level) {
    log_level_ = log_level;
}

void SNMPConfig::set_ipv6_enabled(bool enabled) {
    enable_ipv6_ = enabled;
}

void SNMPConfig::set_trap_enabled(bool enabled) {
    enable_trap_ = enabled;
}

void SNMPConfig::set_trap_port(uint16_t port) {
    trap_port_ = port;
}

} // namespace simple_snmpd
