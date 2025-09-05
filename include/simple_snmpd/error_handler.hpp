/*
 * include/simple_snmpd/error_handler.hpp
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

#ifndef SIMPLE_SNMPD_ERROR_HANDLER_HPP
#define SIMPLE_SNMPD_ERROR_HANDLER_HPP

#include <cstdint>
#include <string>

namespace simple_snmpd {

// Forward declaration to avoid redefinition
enum class LogLevel;

class ErrorHandler {
public:
  ErrorHandler();
  ~ErrorHandler();

  // Error handling methods
  void handle_error(const std::string &message, const std::string &file,
                    int line);
  void handle_warning(const std::string &message, const std::string &file,
                      int line);
  void handle_info(const std::string &message, const std::string &file,
                   int line);
  void handle_debug(const std::string &message, const std::string &file,
                    int line);

  // Counter management
  void reset_counters();
  uint32_t get_error_count() const;
  uint32_t get_warning_count() const;
  std::string get_summary() const;

  // Singleton access
  static ErrorHandler &get_instance();

private:
  uint32_t error_count_;
  uint32_t warning_count_;
};

// Convenience macros
#define HANDLE_ERROR(msg)                                                      \
  ErrorHandler::get_instance().handle_error(msg, __FILE__, __LINE__)
#define HANDLE_WARNING(msg)                                                    \
  ErrorHandler::get_instance().handle_warning(msg, __FILE__, __LINE__)
#define HANDLE_INFO(msg)                                                       \
  ErrorHandler::get_instance().handle_info(msg, __FILE__, __LINE__)
#define HANDLE_DEBUG(msg)                                                      \
  ErrorHandler::get_instance().handle_debug(msg, __FILE__, __LINE__)

} // namespace simple_snmpd

#endif // SIMPLE_SNMPD_ERROR_HANDLER_HPP
