/*
 * include/simple_snmpd/snmp_connection.hpp
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

#ifndef SIMPLE_SNMPD_SNMP_CONNECTION_HPP
#define SIMPLE_SNMPD_SNMP_CONNECTION_HPP

#include "snmp_packet.hpp"
#include <chrono>
#include <cstdint>
#include <string>

namespace simple_snmpd {

class SNMPConnection {
public:
  SNMPConnection(int socket_fd, const std::string &client_address,
                 uint16_t client_port);
  ~SNMPConnection();

  // Connection management
  bool send_response(const SNMPPacket &packet);
  bool receive_request(SNMPPacket &packet);
  void close();

  // Connection information
  bool is_connected() const;
  const std::string &get_client_address() const;
  uint16_t get_client_port() const;
  std::chrono::steady_clock::time_point get_last_activity() const;
  bool is_timeout(uint32_t timeout_seconds) const;

  // Socket configuration
  int get_socket_fd() const;
  void set_non_blocking(bool non_blocking);
  bool set_timeout(uint32_t timeout_seconds);

private:
  int socket_fd_;
  std::string client_address_;
  uint16_t client_port_;
  bool connected_;
  std::chrono::steady_clock::time_point last_activity_;
};

} // namespace simple_snmpd

#endif // SIMPLE_SNMPD_SNMP_CONNECTION_HPP
