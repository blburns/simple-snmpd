/*
 * src/core/logger.cpp
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

#include "simple_snmpd/logger.hpp"
#include <iostream>
#include <fstream>
#include <sstream>
#include <iomanip>
#include <chrono>
#include <mutex>

namespace simple_snmpd {

Logger::Logger() : level_(LogLevel::INFO), initialized_(false) {
}

Logger::~Logger() {
    if (log_file_.is_open()) {
        log_file_.close();
    }
}

void Logger::initialize(LogLevel level, const std::string& log_file_path) {
    std::lock_guard<std::mutex> lock(mutex_);

    level_ = level;
    initialized_ = true;

    if (!log_file_path.empty()) {
        log_file_.open(log_file_path, std::ios::app);
        if (!log_file_.is_open()) {
            std::cerr << "Warning: Could not open log file: " << log_file_path << std::endl;
        }
    }
}

void Logger::log(LogLevel level, const std::string& message) {
    if (!initialized_ || level < level_) {
        return;
    }

    std::lock_guard<std::mutex> lock(mutex_);

    // Get current time
    auto now = std::chrono::system_clock::now();
    auto time_t = std::chrono::system_clock::to_time_t(now);
    auto ms = std::chrono::duration_cast<std::chrono::milliseconds>(
        now.time_since_epoch()) % 1000;

    // Format timestamp
    std::ostringstream timestamp;
    timestamp << std::put_time(std::localtime(&time_t), "%Y-%m-%d %H:%M:%S");
    timestamp << "." << std::setfill('0') << std::setw(3) << ms.count();

    // Format log level
    std::string level_str;
    switch (level) {
        case LogLevel::DEBUG:
            level_str = "DEBUG";
            break;
        case LogLevel::INFO:
            level_str = "INFO ";
            break;
        case LogLevel::WARNING:
            level_str = "WARN ";
            break;
        case LogLevel::ERROR:
            level_str = "ERROR";
            break;
        case LogLevel::FATAL:
            level_str = "FATAL";
            break;
    }

    // Format log message
    std::ostringstream log_entry;
    log_entry << "[" << timestamp.str() << "] [" << level_str << "] " << message;

    std::string formatted_message = log_entry.str();

    // Output to console
    if (level >= LogLevel::WARNING) {
        std::cerr << formatted_message << std::endl;
    } else {
        std::cout << formatted_message << std::endl;
    }

    // Output to log file if open
    if (log_file_.is_open()) {
        log_file_ << formatted_message << std::endl;
        log_file_.flush();
    }
}

void Logger::set_level(LogLevel level) {
    std::lock_guard<std::mutex> lock(mutex_);
    level_ = level;
}

LogLevel Logger::get_level() const {
    std::lock_guard<std::mutex> lock(mutex_);
    return level_;
}

bool Logger::is_initialized() const {
    return initialized_;
}

// Global logger instance
Logger& Logger::get_instance() {
    static Logger instance;
    return instance;
}

} // namespace simple_snmpd
