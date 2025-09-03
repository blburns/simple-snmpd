/*
 * src/core/error_handler.cpp
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

#include "simple_snmpd/error_handler.hpp"
#include "simple_snmpd/logger.hpp"
#include <iostream>
#include <sstream>
#include <iomanip>

namespace simple_snmpd {

ErrorHandler::ErrorHandler() : error_count_(0), warning_count_(0) {
}

ErrorHandler::~ErrorHandler() {
}

void ErrorHandler::handle_error(const std::string& message, const std::string& file, int line) {
    error_count_++;

    std::ostringstream oss;
    oss << "ERROR [" << std::setfill('0') << std::setw(6) << error_count_ << "] ";
    oss << "(" << file << ":" << line << ") " << message;

    std::string error_msg = oss.str();

    // Log the error
    Logger::get_instance().log(LogLevel::ERROR, error_msg);

    // Print to stderr if in debug mode
    if (Logger::get_instance().get_level() <= LogLevel::DEBUG) {
        std::cerr << error_msg << std::endl;
    }
}

void ErrorHandler::handle_warning(const std::string& message, const std::string& file, int line) {
    warning_count_++;

    std::ostringstream oss;
    oss << "WARNING [" << std::setfill('0') << std::setw(6) << warning_count_ << "] ";
    oss << "(" << file << ":" << line << ") " << message;

    std::string warning_msg = oss.str();

    // Log the warning
    Logger::get_instance().log(LogLevel::WARNING, warning_msg);

    // Print to stderr if in debug mode
    if (Logger::get_instance().get_level() <= LogLevel::DEBUG) {
        std::cerr << warning_msg << std::endl;
    }
}

void ErrorHandler::handle_info(const std::string& message, const std::string& file, int line) {
    std::ostringstream oss;
    oss << "INFO (" << file << ":" << line << ") " << message;

    std::string info_msg = oss.str();

    // Log the info
    Logger::get_instance().log(LogLevel::INFO, info_msg);
}

void ErrorHandler::handle_debug(const std::string& message, const std::string& file, int line) {
    std::ostringstream oss;
    oss << "DEBUG (" << file << ":" << line << ") " << message;

    std::string debug_msg = oss.str();

    // Log the debug message
    Logger::get_instance().log(LogLevel::DEBUG, debug_msg);
}

void ErrorHandler::reset_counters() {
    error_count_ = 0;
    warning_count_ = 0;
}

uint32_t ErrorHandler::get_error_count() const {
    return error_count_;
}

uint32_t ErrorHandler::get_warning_count() const {
    return warning_count_;
}

std::string ErrorHandler::get_summary() const {
    std::ostringstream oss;
    oss << "Error Summary: " << error_count_ << " errors, " << warning_count_ << " warnings";
    return oss.str();
}

// Global error handler instance
ErrorHandler& ErrorHandler::get_instance() {
    static ErrorHandler instance;
    return instance;
}

} // namespace simple_snmpd
