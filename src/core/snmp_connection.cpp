/*
 * src/core/snmp_connection.cpp
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

#include "simple_snmpd/snmp_connection.hpp"
#include "simple_snmpd/error_handler.hpp"
#include "simple_snmpd/logger.hpp"
#include <chrono>
#include <cstring>

#ifdef _WIN32
#include <winsock2.h>
#include <ws2tcpip.h>
#pragma comment(lib, "ws2_32.lib")
#else
#include <arpa/inet.h>
#include <fcntl.h>
#include <netinet/in.h>
#include <sys/socket.h>
#include <unistd.h>
#endif

namespace simple_snmpd {

SNMPConnection::SNMPConnection(int socket_fd, const std::string &client_address,
                               uint16_t client_port)
    : socket_fd_(socket_fd), client_address_(client_address),
      client_port_(client_port), connected_(true),
      last_activity_(std::chrono::steady_clock::now()) {}

SNMPConnection::~SNMPConnection() { close(); }

bool SNMPConnection::send_response(const SNMPPacket &packet) {
  if (!connected_) {
    return false;
  }

  std::vector<uint8_t> buffer;
  if (!packet.serialize(buffer)) {
    Logger::get_instance().log(LogLevel::ERROR,
                               "Failed to serialize SNMP packet");
    return false;
  }

  ssize_t bytes_sent =
      send(socket_fd_, reinterpret_cast<const char *>(buffer.data()),
           buffer.size(), 0);

  if (bytes_sent < 0) {
    Logger::get_instance().log(LogLevel::ERROR, "Failed to send SNMP response");
    return false;
  }

  if (static_cast<size_t>(bytes_sent) != buffer.size()) {
    Logger::get_instance().log(LogLevel::WARNING,
                               "Partial send of SNMP response");
  }

  last_activity_ = std::chrono::steady_clock::now();
  return true;
}

bool SNMPConnection::receive_request(SNMPPacket &packet) {
  if (!connected_) {
    return false;
  }

  uint8_t buffer[4096];
  ssize_t bytes_received =
      recv(socket_fd_, reinterpret_cast<char *>(buffer), sizeof(buffer), 0);

  if (bytes_received < 0) {
    Logger::get_instance().log(LogLevel::ERROR,
                               "Failed to receive SNMP request");
    return false;
  }

  if (bytes_received == 0) {
    Logger::get_instance().log(LogLevel::INFO, "Client disconnected");
    connected_ = false;
    return false;
  }

  if (!packet.parse(buffer, bytes_received)) {
    Logger::get_instance().log(LogLevel::ERROR, "Failed to parse SNMP packet");
    return false;
  }

  last_activity_ = std::chrono::steady_clock::now();
  return true;
}

bool SNMPConnection::is_connected() const { return connected_; }

const std::string &SNMPConnection::get_client_address() const {
  return client_address_;
}

uint16_t SNMPConnection::get_client_port() const { return client_port_; }

std::chrono::steady_clock::time_point
SNMPConnection::get_last_activity() const {
  return last_activity_;
}

bool SNMPConnection::is_timeout(uint32_t timeout_seconds) const {
  auto now = std::chrono::steady_clock::now();
  auto elapsed =
      std::chrono::duration_cast<std::chrono::seconds>(now - last_activity_);
  return elapsed.count() >= timeout_seconds;
}

void SNMPConnection::close() {
  if (socket_fd_ != -1) {
#ifdef _WIN32
    closesocket(socket_fd_);
#else
    ::close(socket_fd_);
#endif
    socket_fd_ = -1;
  }
  connected_ = false;
}

int SNMPConnection::get_socket_fd() const { return socket_fd_; }

void SNMPConnection::set_non_blocking(bool non_blocking) {
  if (socket_fd_ == -1) {
    return;
  }

#ifdef _WIN32
  u_long mode = non_blocking ? 1 : 0;
  ioctlsocket(socket_fd_, FIONBIO, &mode);
#else
  int flags = fcntl(socket_fd_, F_GETFL, 0);
  if (flags != -1) {
    if (non_blocking) {
      flags |= O_NONBLOCK;
    } else {
      flags &= ~O_NONBLOCK;
    }
    fcntl(socket_fd_, F_SETFL, flags);
  }
#endif
}

bool SNMPConnection::set_timeout(uint32_t timeout_seconds) {
  if (socket_fd_ == -1) {
    return false;
  }

#ifdef _WIN32
  DWORD timeout = timeout_seconds * 1000;
  if (setsockopt(socket_fd_, SOL_SOCKET, SO_RCVTIMEO,
                 reinterpret_cast<const char *>(&timeout),
                 sizeof(timeout)) == SOCKET_ERROR) {
    return false;
  }
  if (setsockopt(socket_fd_, SOL_SOCKET, SO_SNDTIMEO,
                 reinterpret_cast<const char *>(&timeout),
                 sizeof(timeout)) == SOCKET_ERROR) {
    return false;
  }
#else
  struct timeval timeout;
  timeout.tv_sec = timeout_seconds;
  timeout.tv_usec = 0;

  if (setsockopt(socket_fd_, SOL_SOCKET, SO_RCVTIMEO, &timeout,
                 sizeof(timeout)) < 0) {
    return false;
  }
  if (setsockopt(socket_fd_, SOL_SOCKET, SO_SNDTIMEO, &timeout,
                 sizeof(timeout)) < 0) {
    return false;
  }
#endif

  return true;
}

} // namespace simple_snmpd
