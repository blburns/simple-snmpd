/*
 * include/simple_snmpd/snmp_packet.hpp
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

#ifndef SIMPLE_SNMPD_SNMP_PACKET_HPP
#define SIMPLE_SNMPD_SNMP_PACKET_HPP

#include <vector>
#include <string>
#include <cstdint>

namespace simple_snmpd {

// SNMP version constants
constexpr uint8_t SNMP_VERSION_1 = 0;
constexpr uint8_t SNMP_VERSION_2C = 1;
constexpr uint8_t SNMP_VERSION_3 = 3;

// SNMP PDU type constants
constexpr uint8_t SNMP_PDU_GET_REQUEST = 0xA0;
constexpr uint8_t SNMP_PDU_GET_NEXT_REQUEST = 0xA1;
constexpr uint8_t SNMP_PDU_GET_RESPONSE = 0xA2;
constexpr uint8_t SNMP_PDU_SET_REQUEST = 0xA3;
constexpr uint8_t SNMP_PDU_TRAP = 0xA4;
constexpr uint8_t SNMP_PDU_GET_BULK_REQUEST = 0xA5;
constexpr uint8_t SNMP_PDU_INFORM_REQUEST = 0xA6;
constexpr uint8_t SNMP_PDU_TRAP_V2 = 0xA7;
constexpr uint8_t SNMP_PDU_REPORT = 0xA8;

// SNMP error status constants
constexpr uint8_t SNMP_ERROR_NO_ERROR = 0;
constexpr uint8_t SNMP_ERROR_TOO_BIG = 1;
constexpr uint8_t SNMP_ERROR_NO_SUCH_NAME = 2;
constexpr uint8_t SNMP_ERROR_BAD_VALUE = 3;
constexpr uint8_t SNMP_ERROR_READ_ONLY = 4;
constexpr uint8_t SNMP_ERROR_GEN_ERR = 5;
constexpr uint8_t SNMP_ERROR_NO_ACCESS = 6;
constexpr uint8_t SNMP_ERROR_WRONG_TYPE = 7;
constexpr uint8_t SNMP_ERROR_WRONG_LENGTH = 8;
constexpr uint8_t SNMP_ERROR_WRONG_ENCODING = 9;
constexpr uint8_t SNMP_ERROR_WRONG_VALUE = 10;
constexpr uint8_t SNMP_ERROR_NO_CREATION = 11;
constexpr uint8_t SNMP_ERROR_INCONSISTENT_VALUE = 12;
constexpr uint8_t SNMP_ERROR_RESOURCE_UNAVAILABLE = 13;
constexpr uint8_t SNMP_ERROR_COMMIT_FAILED = 14;
constexpr uint8_t SNMP_ERROR_UNDO_FAILED = 15;
constexpr uint8_t SNMP_ERROR_AUTHORIZATION_ERROR = 16;
constexpr uint8_t SNMP_ERROR_NOT_WRITABLE = 17;
constexpr uint8_t SNMP_ERROR_INCONSISTENT_NAME = 18;

class SNMPPacket {
public:
    struct VariableBinding {
        std::vector<uint8_t> oid;
        uint8_t value_type;
        std::vector<uint8_t> value;
    };

    SNMPPacket();
    ~SNMPPacket();

    // Packet parsing and serialization
    bool parse(const uint8_t* data, size_t length);
    bool serialize(std::vector<uint8_t>& buffer) const;

    // Getters
    uint8_t get_version() const;
    uint8_t get_pdu_type() const;
    const std::string& get_community() const;
    uint32_t get_request_id() const;
    uint8_t get_error_status() const;
    uint8_t get_error_index() const;
    const std::vector<VariableBinding>& get_variable_bindings() const;

    // Setters
    void set_version(uint8_t version);
    void set_pdu_type(uint8_t pdu_type);
    void set_community(const std::string& community);
    void set_request_id(uint32_t request_id);
    void set_error_status(uint8_t error_status);
    void set_error_index(uint8_t error_index);
    void add_variable_binding(const VariableBinding& varbind);
    void clear_variable_bindings();

private:
    // ASN.1 parsing helpers
    bool parse_length(const uint8_t* data, size_t length, size_t& offset, size_t& len);
    bool parse_pdu_fields(const uint8_t* data, size_t& offset, size_t length);
    bool parse_variable_bindings(const uint8_t* data, size_t& offset, size_t length);
    bool parse_variable_binding(const uint8_t* data, size_t& offset, size_t length, VariableBinding& varbind);

    // ASN.1 serialization helpers
    bool serialize_pdu_fields(std::vector<uint8_t>& buffer) const;
    bool serialize_variable_bindings(std::vector<uint8_t>& buffer) const;

    // Packet fields
    uint8_t version_;
    uint8_t pdu_type_;
    std::string community_;
    uint32_t request_id_;
    uint8_t error_status_;
    uint8_t error_index_;
    std::vector<VariableBinding> variable_bindings_;
};

} // namespace simple_snmpd

#endif // SIMPLE_SNMPD_SNMP_PACKET_HPP
