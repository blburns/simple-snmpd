/*
 * include/simple_snmpd/snmp_server.hpp
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

#ifndef SIMPLE_SNMPD_SNMP_SERVER_HPP
#define SIMPLE_SNMPD_SNMP_SERVER_HPP

#include "snmp_config.hpp"
#include "snmp_connection.hpp"
#include "snmp_packet.hpp"
#include <memory>
#include <thread>
#include <vector>
#include <mutex>

namespace simple_snmpd {

class SNMPServer {
public:
    SNMPServer(const SNMPConfig& config);
    ~SNMPServer();

    // Server lifecycle
    bool initialize();
    bool start();
    void stop();
    bool is_running() const;

    // Configuration
    const SNMPConfig& get_config() const;

private:
    // Server threads
    void server_loop();
    void worker_thread();

    // Request processing
    void process_snmp_request(std::shared_ptr<SNMPConnection> connection, 
                             const SNMPPacket& request,
                             const struct sockaddr_in& client_addr);

    // PDU processing
    void process_get_request(const SNMPPacket& request, SNMPPacket& response);
    void process_get_next_request(const SNMPPacket& request, SNMPPacket& response);
    void process_get_bulk_request(const SNMPPacket& request, SNMPPacket& response);
    void process_set_request(const SNMPPacket& request, SNMPPacket& response);

    // Response handling
    void send_response(const SNMPPacket& response, const struct sockaddr_in& client_addr);

    // Server configuration
    SNMPConfig config_;
    int server_socket_;
    bool running_;

    // Threading
    std::thread server_thread_;
    std::vector<std::thread> worker_threads_;
    size_t thread_pool_size_;

    // Connection management
    std::vector<std::shared_ptr<SNMPConnection>> connections_;
    mutable std::mutex connections_mutex_;
};

} // namespace simple_snmpd

#endif // SIMPLE_SNMPD_SNMP_SERVER_HPP
