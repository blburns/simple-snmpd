/*
 * src/core/snmp_server.cpp
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

#include "simple_snmpd/snmp_server.hpp"
#include "simple_snmpd/error_handler.hpp"
#include "simple_snmpd/logger.hpp"
#include "simple_snmpd/platform.hpp"
#include "simple_snmpd/snmp_mib.hpp"
#include "simple_snmpd/snmp_security.hpp"
#include <algorithm>
#include <chrono>
#include <cstring>
#include <thread>

#ifdef _WIN32
#include <winsock2.h>
#include <ws2tcpip.h>
#pragma comment(lib, "ws2_32.lib")
#else
#include <arpa/inet.h>
#include <netinet/in.h>
#include <signal.h>
#include <sys/socket.h>
#include <unistd.h>
#endif

namespace simple_snmpd {

SNMPServer::SNMPServer(const SNMPConfig &config)
    : config_(config), server_socket_(-1), running_(false),
      thread_pool_size_(4) {
  // Initialize MIB manager
  MIBManager::get_instance().initialize_standard_mibs();

  // Initialize security manager
  SecurityManager::get_instance().initialize_defaults();
}

SNMPServer::~SNMPServer() { stop(); }

bool SNMPServer::initialize() {
  Logger::get_instance().log(LogLevel::INFO, "Initializing SNMP server...");

  // Initialize network subsystem
#ifdef _WIN32
  WSADATA wsa_data;
  if (WSAStartup(MAKEWORD(2, 2), &wsa_data) != 0) {
    Logger::get_instance().log(LogLevel::ERROR, "Failed to initialize Winsock");
    return false;
  }
#endif

  // Create server socket
  server_socket_ = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
  if (server_socket_ == -1) {
    Logger::get_instance().log(LogLevel::ERROR,
                               "Failed to create server socket");
    return false;
  }

  // Set socket options
  int reuse = 1;
  if (setsockopt(server_socket_, SOL_SOCKET, SO_REUSEADDR,
                 reinterpret_cast<const char *>(&reuse), sizeof(reuse)) < 0) {
    Logger::get_instance().log(LogLevel::ERROR, "Failed to set SO_REUSEADDR");
    close(server_socket_);
    return false;
  }

  // Bind socket
  struct sockaddr_in server_addr;
  memset(&server_addr, 0, sizeof(server_addr));
  server_addr.sin_family = AF_INET;
  server_addr.sin_addr.s_addr = INADDR_ANY;
  server_addr.sin_port = htons(config_.get_port());

  if (bind(server_socket_, reinterpret_cast<struct sockaddr *>(&server_addr),
           sizeof(server_addr)) < 0) {
    Logger::get_instance().log(LogLevel::ERROR,
                               "Failed to bind socket to port " +
                                   std::to_string(config_.get_port()));
    close(server_socket_);
    return false;
  }

  Logger::get_instance().log(LogLevel::INFO,
                             "SNMP server initialized successfully");
  return true;
}

bool SNMPServer::start() {
  if (running_) {
    Logger::get_instance().log(LogLevel::WARNING,
                               "SNMP server is already running");
    return true;
  }

  Logger::get_instance().log(LogLevel::INFO, "Starting SNMP server...");

  running_ = true;

  // Start worker threads
  for (size_t i = 0; i < thread_pool_size_; ++i) {
    worker_threads_.emplace_back(&SNMPServer::worker_thread, this);
  }

  // Start main server loop
  server_thread_ = std::thread(&SNMPServer::server_loop, this);

  Logger::get_instance().log(LogLevel::INFO,
                             "SNMP server started successfully");
  return true;
}

void SNMPServer::stop() {
  if (!running_) {
    return;
  }

  Logger::get_instance().log(LogLevel::INFO, "Stopping SNMP server...");

  running_ = false;

  // Close server socket to wake up accept
  if (server_socket_ != -1) {
    close(server_socket_);
    server_socket_ = -1;
  }

  // Wait for server thread
  if (server_thread_.joinable()) {
    server_thread_.join();
  }

  // Wait for worker threads
  for (auto &thread : worker_threads_) {
    if (thread.joinable()) {
      thread.join();
    }
  }
  worker_threads_.clear();

  // Close all connections
  std::lock_guard<std::mutex> lock(connections_mutex_);
  for (auto &connection : connections_) {
    connection->close();
  }
  connections_.clear();

  Logger::get_instance().log(LogLevel::INFO, "SNMP server stopped");
}

void SNMPServer::server_loop() {
  Logger::get_instance().log(LogLevel::INFO, "SNMP server main loop started");

  while (running_) {
    struct sockaddr_in client_addr;
    socklen_t client_addr_len = sizeof(client_addr);

    uint8_t buffer[4096];
    ssize_t bytes_received = recvfrom(
        server_socket_, reinterpret_cast<char *>(buffer), sizeof(buffer), 0,
        reinterpret_cast<struct sockaddr *>(&client_addr), &client_addr_len);

    if (bytes_received < 0) {
      if (running_) {
        Logger::get_instance().log(LogLevel::ERROR, "Failed to receive data");
      }
      continue;
    }

    if (bytes_received == 0) {
      continue;
    }

    // Create connection object
    std::string client_address = inet_ntoa(client_addr.sin_addr);
    uint16_t client_port = ntohs(client_addr.sin_port);

    auto connection =
        std::make_shared<SNMPConnection>(-1, client_address, client_port);

    // Parse SNMP packet
    SNMPPacket packet;
    if (!packet.parse(buffer, bytes_received)) {
      Logger::get_instance().log(LogLevel::ERROR,
                                 "Failed to parse SNMP packet from " +
                                     client_address);
      continue;
    }

    // Process the request
    process_snmp_request(connection, packet, client_addr);
  }

  Logger::get_instance().log(LogLevel::INFO, "SNMP server main loop ended");
}

void SNMPServer::worker_thread() {
  Logger::get_instance().log(LogLevel::DEBUG, "Worker thread started");

  while (running_) {
    // TODO: Implement worker thread logic for processing requests
    std::this_thread::sleep_for(std::chrono::milliseconds(100));
  }

  Logger::get_instance().log(LogLevel::DEBUG, "Worker thread ended");
}

void SNMPServer::process_snmp_request(
    std::shared_ptr<SNMPConnection> connection, const SNMPPacket &request,
    const struct sockaddr_in &client_addr) {
  Logger::get_instance().log(LogLevel::DEBUG,
                             "Processing SNMP request from " +
                                 connection->get_client_address());

  // Check rate limiting
  if (!SecurityManager::get_instance().check_rate_limit(
          connection->get_client_address())) {
    Logger::get_instance().log(LogLevel::WARNING,
                               "Rate limit exceeded for " +
                                   connection->get_client_address());
    return;
  }

  // Check IP access
  if (!SecurityManager::get_instance().is_ip_allowed(
          connection->get_client_address())) {
    Logger::get_instance().log(LogLevel::WARNING,
                               "Access denied for IP " +
                                   connection->get_client_address());
    return;
  }

  // Validate community string and access
  if (!SecurityManager::get_instance().is_access_allowed(
          request.get_community(), connection->get_client_address())) {
    Logger::get_instance().log(LogLevel::WARNING,
                               "Access denied for community " +
                                   request.get_community() + " from " +
                                   connection->get_client_address());
    return;
  }

  // Create response packet
  SNMPPacket response;
  response.set_version(request.get_version());
  response.set_community(request.get_community());
  response.set_request_id(request.get_request_id());

  // Process based on PDU type
  switch (request.get_pdu_type()) {
  case SNMP_PDU_GET_REQUEST:
    process_get_request(request, response);
    break;
  case SNMP_PDU_GET_NEXT_REQUEST:
    process_get_next_request(request, response);
    break;
  case SNMP_PDU_GET_BULK_REQUEST:
    // GET-BULK is only supported in SNMP v2c and v3
    if (request.get_version() == SNMP_VERSION_2C ||
        request.get_version() == SNMP_VERSION_3) {
      process_get_bulk_request(request, response);
    } else {
      Logger::get_instance().log(LogLevel::WARNING,
                                 "GET-BULK not supported in SNMP v1");
      response.set_error_status(SNMP_ERROR_NO_SUCH_NAME);
    }
    break;
  case SNMP_PDU_SET_REQUEST:
    process_set_request(request, response);
    break;
  case SNMP_PDU_TRAP:
    // Handle SNMP v1 traps
    if (request.get_version() == SNMP_VERSION_1) {
      process_trap_v1(request, response);
    } else {
      Logger::get_instance().log(LogLevel::WARNING,
                                 "SNMP v1 trap received with wrong version");
      response.set_error_status(SNMP_ERROR_NO_SUCH_NAME);
    }
    break;
  case SNMP_PDU_TRAP_V2:
    // Handle SNMP v2c traps
    if (request.get_version() == SNMP_VERSION_2C) {
      process_trap_v2(request, response);
    } else {
      Logger::get_instance().log(LogLevel::WARNING,
                                 "SNMP v2c trap received with wrong version");
      response.set_error_status(SNMP_ERROR_NO_SUCH_NAME);
    }
    break;
  default:
    Logger::get_instance().log(LogLevel::WARNING,
                               "Unsupported PDU type: " +
                                   std::to_string(request.get_pdu_type()));
    response.set_error_status(SNMP_ERROR_NO_SUCH_NAME);
    break;
  }

  // Send response
  send_response(response, client_addr);
}

void SNMPServer::process_get_request(const SNMPPacket &request,
                                     SNMPPacket &response) {
  response.set_pdu_type(SNMP_PDU_GET_RESPONSE);

  for (const auto &varbind : request.get_variable_bindings()) {
    SNMPPacket::VariableBinding response_varbind;
    response_varbind.oid = varbind.oid;

    // Look up value in MIB
    MIBValue mib_value;
    if (MIBManager::get_instance().get_value(varbind.oid, mib_value)) {
      response_varbind.value_type = static_cast<uint8_t>(mib_value.type);
      response_varbind.value = mib_value.data;
    } else {
      // No such object
      response_varbind.value_type = 0x05; // NULL
      response_varbind.value.clear();
      response.set_error_status(SNMP_ERROR_NO_SUCH_NAME);
      response.set_error_index(
          static_cast<uint8_t>(request.get_variable_bindings().size()));
    }

    response.add_variable_binding(response_varbind);
  }
}

void SNMPServer::process_get_next_request(const SNMPPacket &request,
                                          SNMPPacket &response) {
  response.set_pdu_type(SNMP_PDU_GET_RESPONSE);

  for (const auto &varbind : request.get_variable_bindings()) {
    SNMPPacket::VariableBinding response_varbind;

    // Find the next OID in lexicographic order
    std::vector<uint8_t> next_oid;
    if (MIBManager::get_instance().get_next_oid(varbind.oid, next_oid)) {
      response_varbind.oid = next_oid;

      // Get the value for the next OID
      MIBValue mib_value;
      if (MIBManager::get_instance().get_value(next_oid, mib_value)) {
        response_varbind.value_type = static_cast<uint8_t>(mib_value.type);
        response_varbind.value = mib_value.data;
      } else {
        // This shouldn't happen if get_next_oid worked correctly
        response_varbind.value_type = 0x05; // NULL
        response_varbind.value.clear();
      }
    } else {
      // No more objects - return endOfMibView
      response_varbind.oid = varbind.oid;
      response_varbind.value_type = 0x05; // NULL
      response_varbind.value.clear();
    }

    response.add_variable_binding(response_varbind);
  }
}

void SNMPServer::process_get_bulk_request(const SNMPPacket &request,
                                          SNMPPacket &response) {
  response.set_pdu_type(SNMP_PDU_GET_RESPONSE);

  // For simplicity, we'll process GET-BULK as multiple GET-NEXT operations
  // In a full implementation, we'd need to handle non-repeaters and
  // max-repetitions
  const auto &varbinds = request.get_variable_bindings();

  for (size_t i = 0; i < varbinds.size(); ++i) {
    const auto &varbind = varbinds[i];
    SNMPPacket::VariableBinding response_varbind;

    // Find the next OID in lexicographic order
    std::vector<uint8_t> next_oid;
    if (MIBManager::get_instance().get_next_oid(varbind.oid, next_oid)) {
      response_varbind.oid = next_oid;

      // Get the value for the next OID
      MIBValue mib_value;
      if (MIBManager::get_instance().get_value(next_oid, mib_value)) {
        response_varbind.value_type = static_cast<uint8_t>(mib_value.type);
        response_varbind.value = mib_value.data;
      } else {
        // This shouldn't happen if get_next_oid worked correctly
        response_varbind.value_type = 0x05; // NULL
        response_varbind.value.clear();
      }
    } else {
      // No more objects - return endOfMibView
      response_varbind.oid = varbind.oid;
      response_varbind.value_type = 0x05; // NULL
      response_varbind.value.clear();
    }

    response.add_variable_binding(response_varbind);
  }
}

void SNMPServer::process_set_request(const SNMPPacket &request,
                                     SNMPPacket &response) {
  response.set_pdu_type(SNMP_PDU_GET_RESPONSE);

  // Check if write access is allowed for this community
  if (!SecurityManager::get_instance().is_write_allowed(
          request.get_community())) {
    Logger::get_instance().log(LogLevel::WARNING,
                               "Write access denied for community: " +
                                   request.get_community());
    response.set_error_status(SNMP_ERROR_NO_ACCESS);
    return;
  }

  for (const auto &varbind : request.get_variable_bindings()) {
    SNMPPacket::VariableBinding response_varbind;
    response_varbind.oid = varbind.oid;

    // Check OID access
    std::string oid_str = OIDUtils::oid_to_string(varbind.oid);
    if (!SecurityManager::get_instance().is_oid_allowed(request.get_community(),
                                                        oid_str)) {
      response_varbind.value_type = 0x05; // NULL
      response_varbind.value.clear();
      response.set_error_status(SNMP_ERROR_NO_ACCESS);
      response.set_error_index(
          static_cast<uint8_t>(request.get_variable_bindings().size()));
      response.add_variable_binding(response_varbind);
      continue;
    }

    // Check if the object exists and is writable
    MIBValue mib_value;
    if (MIBManager::get_instance().get_value(varbind.oid, mib_value)) {
      // Object exists, check if it's writable
      if (MIBManager::get_instance().is_scalar(varbind.oid)) {
        // For now, we'll reject all SET operations as read-only
        response_varbind.value_type = 0x05; // NULL
        response_varbind.value.clear();
        response.set_error_status(SNMP_ERROR_READ_ONLY);
        response.set_error_index(
            static_cast<uint8_t>(request.get_variable_bindings().size()));
      } else {
        // Try to set the value
        MIBValue new_value(static_cast<SNMPDataType>(varbind.value_type),
                           varbind.value);
        if (MIBManager::get_instance().set_value(varbind.oid, new_value)) {
          // Success - return the new value
          response_varbind.value_type = varbind.value_type;
          response_varbind.value = varbind.value;
        } else {
          // Set failed
          response_varbind.value_type = 0x05; // NULL
          response_varbind.value.clear();
          response.set_error_status(SNMP_ERROR_WRONG_VALUE);
          response.set_error_index(
              static_cast<uint8_t>(request.get_variable_bindings().size()));
        }
      }
    } else {
      // No such object
      response_varbind.value_type = 0x05; // NULL
      response_varbind.value.clear();
      response.set_error_status(SNMP_ERROR_NO_SUCH_NAME);
      response.set_error_index(
          static_cast<uint8_t>(request.get_variable_bindings().size()));
    }

    response.add_variable_binding(response_varbind);
  }
}

void SNMPServer::process_trap_v1(const SNMPPacket &request,
                                 SNMPPacket &response) {
  // SNMP v1 traps don't generate responses, but we log them
  Logger::get_instance().log(
      LogLevel::INFO,
      "Received SNMP v1 trap from " + request.get_community() + " with " +
          std::to_string(request.get_variable_bindings().size()) +
          " variables");

  // Log trap details
  for (const auto &varbind : request.get_variable_bindings()) {
    std::string oid_str = OIDUtils::oid_to_string(varbind.oid);
    Logger::get_instance().log(
        LogLevel::DEBUG,
        "Trap variable: " + oid_str +
            " (type: " + std::to_string(varbind.value_type) +
            ", length: " + std::to_string(varbind.value.size()) + ")");
  }

  // SNMP v1 traps don't send responses
  return;
}

void SNMPServer::process_trap_v2(const SNMPPacket &request,
                                 SNMPPacket &response) {
  // SNMP v2c traps don't generate responses, but we log them
  Logger::get_instance().log(
      LogLevel::INFO,
      "Received SNMP v2c trap from " + request.get_community() + " with " +
          std::to_string(request.get_variable_bindings().size()) +
          " variables");

  // Log trap details
  for (const auto &varbind : request.get_variable_bindings()) {
    std::string oid_str = OIDUtils::oid_to_string(varbind.oid);
    Logger::get_instance().log(
        LogLevel::DEBUG,
        "Trap variable: " + oid_str +
            " (type: " + std::to_string(varbind.value_type) +
            ", length: " + std::to_string(varbind.value.size()) + ")");
  }

  // SNMP v2c traps don't send responses
  return;
}

void SNMPServer::send_response(const SNMPPacket &response,
                               const struct sockaddr_in &client_addr) {
  std::vector<uint8_t> buffer;
  if (!response.serialize(buffer)) {
    Logger::get_instance().log(LogLevel::ERROR, "Failed to serialize response");
    return;
  }

  ssize_t bytes_sent = sendto(
      server_socket_, reinterpret_cast<const char *>(buffer.data()),
      buffer.size(), 0, reinterpret_cast<const struct sockaddr *>(&client_addr),
      sizeof(client_addr));

  if (bytes_sent < 0) {
    Logger::get_instance().log(LogLevel::ERROR, "Failed to send response");
  } else if (static_cast<size_t>(bytes_sent) != buffer.size()) {
    Logger::get_instance().log(LogLevel::WARNING, "Partial send of response");
  }
}

bool SNMPServer::is_running() const { return running_; }

const SNMPConfig &SNMPServer::get_config() const { return config_; }

} // namespace simple_snmpd
