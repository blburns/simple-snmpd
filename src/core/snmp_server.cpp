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
#include "simple_snmpd/logger.hpp"
#include "simple_snmpd/error_handler.hpp"
#include "simple_snmpd/platform.hpp"
#include <thread>
#include <chrono>
#include <algorithm>
#include <cstring>

#ifdef _WIN32
#include <winsock2.h>
#include <ws2tcpip.h>
#pragma comment(lib, "ws2_32.lib")
#else
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <signal.h>
#endif

namespace simple_snmpd {

SNMPServer::SNMPServer(const SNMPConfig& config)
    : config_(config)
    , server_socket_(-1)
    , running_(false)
    , thread_pool_size_(4) {
}

SNMPServer::~SNMPServer() {
    stop();
}

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
        Logger::get_instance().log(LogLevel::ERROR, "Failed to create server socket");
        return false;
    }

    // Set socket options
    int reuse = 1;
    if (setsockopt(server_socket_, SOL_SOCKET, SO_REUSEADDR,
                   reinterpret_cast<const char*>(&reuse), sizeof(reuse)) < 0) {
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

    if (bind(server_socket_, reinterpret_cast<struct sockaddr*>(&server_addr),
             sizeof(server_addr)) < 0) {
        Logger::get_instance().log(LogLevel::ERROR, "Failed to bind socket to port " +
                                  std::to_string(config_.get_port()));
        close(server_socket_);
        return false;
    }

    Logger::get_instance().log(LogLevel::INFO, "SNMP server initialized successfully");
    return true;
}

bool SNMPServer::start() {
    if (running_) {
        Logger::get_instance().log(LogLevel::WARNING, "SNMP server is already running");
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

    Logger::get_instance().log(LogLevel::INFO, "SNMP server started successfully");
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
    for (auto& thread : worker_threads_) {
        if (thread.joinable()) {
            thread.join();
        }
    }
    worker_threads_.clear();

    // Close all connections
    std::lock_guard<std::mutex> lock(connections_mutex_);
    for (auto& connection : connections_) {
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
        ssize_t bytes_received = recvfrom(server_socket_, reinterpret_cast<char*>(buffer),
                                         sizeof(buffer), 0,
                                         reinterpret_cast<struct sockaddr*>(&client_addr),
                                         &client_addr_len);

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

        auto connection = std::make_shared<SNMPConnection>(-1, client_address, client_port);

        // Parse SNMP packet
        SNMPPacket packet;
        if (!packet.parse(buffer, bytes_received)) {
            Logger::get_instance().log(LogLevel::ERROR, "Failed to parse SNMP packet from " +
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

void SNMPServer::process_snmp_request(std::shared_ptr<SNMPConnection> connection,
                                     const SNMPPacket& request,
                                     const struct sockaddr_in& client_addr) {
    Logger::get_instance().log(LogLevel::DEBUG, "Processing SNMP request from " +
                              connection->get_client_address());

    // Validate community string
    if (request.get_community() != config_.get_community()) {
        Logger::get_instance().log(LogLevel::WARNING, "Invalid community string from " +
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
            process_get_bulk_request(request, response);
            break;
        case SNMP_PDU_SET_REQUEST:
            process_set_request(request, response);
            break;
        default:
            Logger::get_instance().log(LogLevel::WARNING, "Unsupported PDU type: " +
                                      std::to_string(request.get_pdu_type()));
            response.set_error_status(SNMP_ERROR_NO_SUCH_NAME);
            break;
    }

    // Send response
    send_response(response, client_addr);
}

void SNMPServer::process_get_request(const SNMPPacket& request, SNMPPacket& response) {
    response.set_pdu_type(SNMP_PDU_GET_RESPONSE);

    for (const auto& varbind : request.get_variable_bindings()) {
        SNMPPacket::VariableBinding response_varbind;
        response_varbind.oid = varbind.oid;

        // TODO: Implement actual SNMP MIB lookup
        // For now, return a simple response
        if (varbind.oid == std::vector<uint8_t>{0x2b, 0x06, 0x01, 0x02, 0x01, 0x01, 0x01, 0x00}) {
            // sysDescr.0
            std::string sys_descr = "Simple SNMP Daemon v0.1.0";
            response_varbind.value_type = 0x04; // OCTET STRING
            response_varbind.value.assign(sys_descr.begin(), sys_descr.end());
        } else {
            // No such object
            response_varbind.value_type = 0x05; // NULL
            response_varbind.value.clear();
        }

        response.add_variable_binding(response_varbind);
    }
}

void SNMPServer::process_get_next_request(const SNMPPacket& request, SNMPPacket& response) {
    response.set_pdu_type(SNMP_PDU_GET_RESPONSE);

    // TODO: Implement GET-NEXT request processing
    Logger::get_instance().log(LogLevel::DEBUG, "GET-NEXT request not implemented yet");

    for (const auto& varbind : request.get_variable_bindings()) {
        SNMPPacket::VariableBinding response_varbind;
        response_varbind.oid = varbind.oid;
        response_varbind.value_type = 0x05; // NULL
        response_varbind.value.clear();
        response.add_variable_binding(response_varbind);
    }
}

void SNMPServer::process_get_bulk_request(const SNMPPacket& request, SNMPPacket& response) {
    response.set_pdu_type(SNMP_PDU_GET_RESPONSE);

    // TODO: Implement GET-BULK request processing
    Logger::get_instance().log(LogLevel::DEBUG, "GET-BULK request not implemented yet");

    for (const auto& varbind : request.get_variable_bindings()) {
        SNMPPacket::VariableBinding response_varbind;
        response_varbind.oid = varbind.oid;
        response_varbind.value_type = 0x05; // NULL
        response_varbind.value.clear();
        response.add_variable_binding(response_varbind);
    }
}

void SNMPServer::process_set_request(const SNMPPacket& request, SNMPPacket& response) {
    response.set_pdu_type(SNMP_PDU_GET_RESPONSE);

    // TODO: Implement SET request processing
    Logger::get_instance().log(LogLevel::DEBUG, "SET request not implemented yet");

    for (const auto& varbind : request.get_variable_bindings()) {
        SNMPPacket::VariableBinding response_varbind;
        response_varbind.oid = varbind.oid;
        response_varbind.value_type = 0x05; // NULL
        response_varbind.value.clear();
        response.add_variable_binding(response_varbind);
    }
}

void SNMPServer::send_response(const SNMPPacket& response, const struct sockaddr_in& client_addr) {
    std::vector<uint8_t> buffer;
    if (!response.serialize(buffer)) {
        Logger::get_instance().log(LogLevel::ERROR, "Failed to serialize response");
        return;
    }

    ssize_t bytes_sent = sendto(server_socket_, reinterpret_cast<const char*>(buffer.data()),
                               buffer.size(), 0,
                               reinterpret_cast<const struct sockaddr*>(&client_addr),
                               sizeof(client_addr));

    if (bytes_sent < 0) {
        Logger::get_instance().log(LogLevel::ERROR, "Failed to send response");
    } else if (static_cast<size_t>(bytes_sent) != buffer.size()) {
        Logger::get_instance().log(LogLevel::WARNING, "Partial send of response");
    }
}

bool SNMPServer::is_running() const {
    return running_;
}

const SNMPConfig& SNMPServer::get_config() const {
    return config_;
}

} // namespace simple_snmpd
