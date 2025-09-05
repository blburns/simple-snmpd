/*
 * src/core/snmp_packet.cpp
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

#include "simple_snmpd/snmp_packet.hpp"
#include "simple_snmpd/logger.hpp"
#include <algorithm>
#include <cstring>

namespace simple_snmpd {

SNMPPacket::SNMPPacket()
    : version_(SNMP_VERSION_2C), pdu_type_(SNMP_PDU_GET_REQUEST),
      request_id_(0), error_status_(0), error_index_(0) {}

SNMPPacket::~SNMPPacket() {}

bool SNMPPacket::parse(const uint8_t *data, size_t length) {
  if (!data || length == 0) {
    return false;
  }

  size_t offset = 0;

  // Parse ASN.1 sequence header
  if (offset >= length || data[offset] != 0x30) { // SEQUENCE
    Logger::get_instance().log(LogLevel::ERROR,
                               "Invalid SNMP packet: missing sequence header");
    return false;
  }
  offset++;

  // Parse length
  size_t packet_length = 0;
  if (!parse_length(data, length, offset, packet_length)) {
    Logger::get_instance().log(LogLevel::ERROR,
                               "Invalid SNMP packet: invalid length");
    return false;
  }

  if (packet_length != length - offset) {
    Logger::get_instance().log(LogLevel::ERROR,
                               "Invalid SNMP packet: length mismatch");
    return false;
  }

  // Parse version
  if (offset >= length || data[offset] != 0x02) { // INTEGER
    Logger::get_instance().log(LogLevel::ERROR,
                               "Invalid SNMP packet: missing version");
    return false;
  }
  offset++;

  size_t version_length = 0;
  if (!parse_length(data, length, offset, version_length)) {
    return false;
  }

  if (offset + version_length > length) {
    return false;
  }

  if (version_length == 1) {
    version_ = data[offset];
  } else {
    Logger::get_instance().log(LogLevel::ERROR,
                               "Invalid SNMP packet: invalid version length");
    return false;
  }
  offset += version_length;

  // Parse community string
  if (offset >= length || data[offset] != 0x04) { // OCTET STRING
    Logger::get_instance().log(LogLevel::ERROR,
                               "Invalid SNMP packet: missing community");
    return false;
  }
  offset++;

  size_t community_length = 0;
  if (!parse_length(data, length, offset, community_length)) {
    return false;
  }

  if (offset + community_length > length) {
    return false;
  }

  community_.assign(reinterpret_cast<const char *>(data + offset),
                    community_length);
  offset += community_length;

  // Parse PDU
  if (offset >= length) {
    Logger::get_instance().log(LogLevel::ERROR,
                               "Invalid SNMP packet: missing PDU");
    return false;
  }

  pdu_type_ = data[offset];
  offset++;

  size_t pdu_length = 0;
  if (!parse_length(data, length, offset, pdu_length)) {
    return false;
  }

  if (offset + pdu_length > length) {
    return false;
  }

  // Parse PDU fields based on type
  if (!parse_pdu_fields(data, offset, pdu_length)) {
    return false;
  }

  return true;
}

bool SNMPPacket::serialize(std::vector<uint8_t> &buffer) const {
  buffer.clear();

  // Start with sequence header
  buffer.push_back(0x30); // SEQUENCE

  // Calculate total length (will be filled later)
  size_t length_pos = buffer.size();
  buffer.push_back(0x00); // Placeholder for length

  // Version
  buffer.push_back(0x02); // INTEGER
  buffer.push_back(0x01); // Length
  buffer.push_back(static_cast<uint8_t>(version_));

  // Community string
  buffer.push_back(0x04); // OCTET STRING
  buffer.push_back(static_cast<uint8_t>(community_.length()));
  buffer.insert(buffer.end(), community_.begin(), community_.end());

  // PDU type
  buffer.push_back(static_cast<uint8_t>(pdu_type_));

  // PDU length (will be filled later)
  size_t pdu_length_pos = buffer.size();
  buffer.push_back(0x00); // Placeholder for PDU length

  // Serialize PDU fields
  if (!serialize_pdu_fields(buffer)) {
    return false;
  }

  // Fill in PDU length
  size_t pdu_length = buffer.size() - pdu_length_pos - 1;
  buffer[pdu_length_pos] = static_cast<uint8_t>(pdu_length);

  // Fill in total length
  size_t total_length = buffer.size() - length_pos - 1;
  buffer[length_pos] = static_cast<uint8_t>(total_length);

  return true;
}

bool SNMPPacket::parse_length(const uint8_t *data, size_t length,
                              size_t &offset, size_t &len) {
  if (offset >= length) {
    return false;
  }

  uint8_t first_byte = data[offset++];

  if ((first_byte & 0x80) == 0) {
    // Short form
    len = first_byte;
  } else {
    // Long form
    size_t length_bytes = first_byte & 0x7F;
    if (length_bytes == 0 || length_bytes > 4) {
      return false;
    }

    len = 0;
    for (size_t i = 0; i < length_bytes; i++) {
      if (offset >= length) {
        return false;
      }
      len = (len << 8) | data[offset++];
    }
  }

  return true;
}

bool SNMPPacket::parse_pdu_fields(const uint8_t *data, size_t &offset,
                                  size_t length) {
  size_t start_offset = offset;

  // Request ID
  if (offset >= start_offset + length || data[offset] != 0x02) { // INTEGER
    return false;
  }
  offset++;

  size_t request_id_length = 0;
  if (!parse_length(data, start_offset + length, offset, request_id_length)) {
    return false;
  }

  if (offset + request_id_length > start_offset + length) {
    return false;
  }

  request_id_ = 0;
  for (size_t i = 0; i < request_id_length; i++) {
    request_id_ = (request_id_ << 8) | data[offset++];
  }

  // Error status
  if (offset >= start_offset + length || data[offset] != 0x02) { // INTEGER
    return false;
  }
  offset++;

  size_t error_status_length = 0;
  if (!parse_length(data, start_offset + length, offset, error_status_length)) {
    return false;
  }

  if (offset + error_status_length > start_offset + length) {
    return false;
  }

  error_status_ = 0;
  for (size_t i = 0; i < error_status_length; i++) {
    error_status_ = (error_status_ << 8) | data[offset++];
  }

  // Error index
  if (offset >= start_offset + length || data[offset] != 0x02) { // INTEGER
    return false;
  }
  offset++;

  size_t error_index_length = 0;
  if (!parse_length(data, start_offset + length, offset, error_index_length)) {
    return false;
  }

  if (offset + error_index_length > start_offset + length) {
    return false;
  }

  error_index_ = 0;
  for (size_t i = 0; i < error_index_length; i++) {
    error_index_ = (error_index_ << 8) | data[offset++];
  }

  // Variable bindings
  if (offset >= start_offset + length || data[offset] != 0x30) { // SEQUENCE
    return false;
  }
  offset++;

  size_t varbinds_length = 0;
  if (!parse_length(data, start_offset + length, offset, varbinds_length)) {
    return false;
  }

  if (offset + varbinds_length > start_offset + length) {
    return false;
  }

  return parse_variable_bindings(data, offset, varbinds_length);
}

bool SNMPPacket::parse_variable_bindings(const uint8_t *data, size_t &offset,
                                         size_t length) {
  size_t start_offset = offset;
  variable_bindings_.clear();

  while (offset < start_offset + length) {
    if (offset >= start_offset + length || data[offset] != 0x30) { // SEQUENCE
      return false;
    }
    offset++;

    size_t varbind_length = 0;
    if (!parse_length(data, start_offset + length, offset, varbind_length)) {
      return false;
    }

    if (offset + varbind_length > start_offset + length) {
      return false;
    }

    VariableBinding varbind;
    if (!parse_variable_binding(data, offset, varbind_length, varbind)) {
      return false;
    }

    variable_bindings_.push_back(varbind);
  }

  return true;
}

bool SNMPPacket::parse_variable_binding(const uint8_t *data, size_t &offset,
                                        size_t length,
                                        VariableBinding &varbind) {
  size_t start_offset = offset;

  // OID
  if (offset >= start_offset + length ||
      data[offset] != 0x06) { // OBJECT IDENTIFIER
    return false;
  }
  offset++;

  size_t oid_length = 0;
  if (!parse_length(data, start_offset + length, offset, oid_length)) {
    return false;
  }

  if (offset + oid_length > start_offset + length) {
    return false;
  }

  varbind.oid.assign(data + offset, data + offset + oid_length);
  offset += oid_length;

  // Value
  if (offset >= start_offset + length) {
    return false;
  }

  uint8_t value_type = data[offset++];
  size_t value_length = 0;
  if (!parse_length(data, start_offset + length, offset, value_length)) {
    return false;
  }

  if (offset + value_length > start_offset + length) {
    return false;
  }

  varbind.value_type = value_type;
  varbind.value.assign(data + offset, data + offset + value_length);
  offset += value_length;

  return true;
}

bool SNMPPacket::serialize_pdu_fields(std::vector<uint8_t> &buffer) const {
  // Request ID
  buffer.push_back(0x02); // INTEGER
  buffer.push_back(0x04); // Length (4 bytes)
  buffer.push_back((request_id_ >> 24) & 0xFF);
  buffer.push_back((request_id_ >> 16) & 0xFF);
  buffer.push_back((request_id_ >> 8) & 0xFF);
  buffer.push_back(request_id_ & 0xFF);

  // Error status
  buffer.push_back(0x02); // INTEGER
  buffer.push_back(0x01); // Length (1 byte)
  buffer.push_back(static_cast<uint8_t>(error_status_));

  // Error index
  buffer.push_back(0x02); // INTEGER
  buffer.push_back(0x01); // Length (1 byte)
  buffer.push_back(static_cast<uint8_t>(error_index_));

  // Variable bindings
  buffer.push_back(0x30); // SEQUENCE

  // Calculate varbinds length
  size_t varbinds_length_pos = buffer.size();
  buffer.push_back(0x00); // Placeholder for varbinds length

  if (!serialize_variable_bindings(buffer)) {
    return false;
  }

  // Fill in varbinds length
  size_t varbinds_length = buffer.size() - varbinds_length_pos - 1;
  buffer[varbinds_length_pos] = static_cast<uint8_t>(varbinds_length);

  return true;
}

bool SNMPPacket::serialize_variable_bindings(
    std::vector<uint8_t> &buffer) const {
  for (const auto &varbind : variable_bindings_) {
    buffer.push_back(0x30); // SEQUENCE

    // Calculate varbind length
    size_t varbind_length_pos = buffer.size();
    buffer.push_back(0x00); // Placeholder for varbind length

    // OID
    buffer.push_back(0x06); // OBJECT IDENTIFIER
    buffer.push_back(static_cast<uint8_t>(varbind.oid.size()));
    buffer.insert(buffer.end(), varbind.oid.begin(), varbind.oid.end());

    // Value
    buffer.push_back(varbind.value_type);
    buffer.push_back(static_cast<uint8_t>(varbind.value.size()));
    buffer.insert(buffer.end(), varbind.value.begin(), varbind.value.end());

    // Fill in varbind length
    size_t varbind_length = buffer.size() - varbind_length_pos - 1;
    buffer[varbind_length_pos] = static_cast<uint8_t>(varbind_length);
  }

  return true;
}

// Getters and setters
uint8_t SNMPPacket::get_version() const { return version_; }

uint8_t SNMPPacket::get_pdu_type() const { return pdu_type_; }

const std::string &SNMPPacket::get_community() const { return community_; }

uint32_t SNMPPacket::get_request_id() const { return request_id_; }

uint8_t SNMPPacket::get_error_status() const { return error_status_; }

uint8_t SNMPPacket::get_error_index() const { return error_index_; }

const std::vector<SNMPPacket::VariableBinding> &
SNMPPacket::get_variable_bindings() const {
  return variable_bindings_;
}

void SNMPPacket::set_version(uint8_t version) { version_ = version; }

void SNMPPacket::set_pdu_type(uint8_t pdu_type) { pdu_type_ = pdu_type; }

void SNMPPacket::set_community(const std::string &community) {
  community_ = community;
}

void SNMPPacket::set_request_id(uint32_t request_id) {
  request_id_ = request_id;
}

void SNMPPacket::set_error_status(uint8_t error_status) {
  error_status_ = error_status;
}

void SNMPPacket::set_error_index(uint8_t error_index) {
  error_index_ = error_index;
}

void SNMPPacket::add_variable_binding(const VariableBinding &varbind) {
  variable_bindings_.push_back(varbind);
}

void SNMPPacket::clear_variable_bindings() { variable_bindings_.clear(); }

} // namespace simple_snmpd
