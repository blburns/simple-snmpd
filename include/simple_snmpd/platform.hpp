/*
 * include/simple_snmpd/platform.hpp
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

#ifndef SIMPLE_SNMPD_PLATFORM_HPP
#define SIMPLE_SNMPD_PLATFORM_HPP

#include <cstdint>
#include <string>
#include <vector>

namespace simple_snmpd {

class Platform {
public:
  Platform();
  ~Platform();

  // System information
  std::string get_os_name() const;
  std::string get_os_version() const;
  std::string get_architecture() const;
  std::string get_hostname() const;

  // Network information
  std::vector<std::string> get_network_interfaces() const;

  // System resources
  uint64_t get_uptime_seconds() const;
  uint32_t get_cpu_count() const;
  uint64_t get_total_memory() const;
  uint64_t get_free_memory() const;

  // Singleton access
  static Platform &get_instance();

private:
  // Platform-specific implementations
#ifdef _WIN32
  std::string get_windows_version() const;
  std::string get_windows_architecture() const;
#else
  std::string get_unix_version() const;
  std::string get_unix_architecture() const;
#endif
};

} // namespace simple_snmpd

#endif // SIMPLE_SNMPD_PLATFORM_HPP
