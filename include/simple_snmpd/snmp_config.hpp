/*
 * include/simple_snmpd/snmp_config.hpp
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

#ifndef SIMPLE_SNMPD_SNMP_CONFIG_HPP
#define SIMPLE_SNMPD_SNMP_CONFIG_HPP

#include <cstdint>
#include <string>

namespace simple_snmpd {

class SNMPConfig {
public:
  SNMPConfig();
  ~SNMPConfig();

  // Configuration loading
  bool load(const std::string &config_file);

  // Getters
  uint16_t get_port() const;
  const std::string &get_community() const;
  uint32_t get_max_connections() const;
  uint32_t get_timeout_seconds() const;
  const std::string &get_log_level() const;
  bool is_ipv6_enabled() const;
  bool is_trap_enabled() const;
  uint16_t get_trap_port() const;

  // Setters
  void set_port(uint16_t port);
  void set_community(const std::string &community);
  void set_max_connections(uint32_t max_connections);
  void set_timeout_seconds(uint32_t timeout_seconds);
  void set_log_level(const std::string &log_level);
  void set_ipv6_enabled(bool enabled);
  void set_trap_enabled(bool enabled);
  void set_trap_port(uint16_t port);

private:
  bool parse_config_value(const std::string &key, const std::string &value);

  // Configuration parameters
  uint16_t port_;
  std::string community_;
  uint32_t max_connections_;
  uint32_t timeout_seconds_;
  std::string log_level_;
  bool enable_ipv6_;
  bool enable_trap_;
  uint16_t trap_port_;
};

} // namespace simple_snmpd

#endif // SIMPLE_SNMPD_SNMP_CONFIG_HPP
