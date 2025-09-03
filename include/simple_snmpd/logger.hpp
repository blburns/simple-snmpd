/*
 * include/simple_snmpd/logger.hpp
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

#ifndef SIMPLE_SNMPD_LOGGER_HPP
#define SIMPLE_SNMPD_LOGGER_HPP

#include <string>
#include <fstream>
#include <mutex>

namespace simple_snmpd {

enum class LogLevel {
    DEBUG = 0,
    INFO = 1,
    WARNING = 2,
    ERROR = 3,
    FATAL = 4
};

class Logger {
public:
    Logger();
    ~Logger();

    // Initialization
    void initialize(LogLevel level, const std::string& log_file_path = "");

    // Logging methods
    void log(LogLevel level, const std::string& message);

    // Configuration
    void set_level(LogLevel level);
    LogLevel get_level() const;
    bool is_initialized() const;

    // Singleton access
    static Logger& get_instance();

private:
    LogLevel level_;
    bool initialized_;
    std::ofstream log_file_;
    mutable std::mutex mutex_;
};

// Convenience macros
#define LOG_DEBUG(msg) Logger::get_instance().log(LogLevel::DEBUG, msg)
#define LOG_INFO(msg) Logger::get_instance().log(LogLevel::INFO, msg)
#define LOG_WARNING(msg) Logger::get_instance().log(LogLevel::WARNING, msg)
#define LOG_ERROR(msg) Logger::get_instance().log(LogLevel::ERROR, msg)
#define LOG_FATAL(msg) Logger::get_instance().log(LogLevel::FATAL, msg)

} // namespace simple_snmpd

#endif // SIMPLE_SNMPD_LOGGER_HPP
