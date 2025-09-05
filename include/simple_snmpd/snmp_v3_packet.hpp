#pragma once

#include "simple_snmpd/logger.hpp"
#include "simple_snmpd/snmp_packet.hpp"
#include "simple_snmpd/snmp_v3_usm.hpp"
#include "simple_snmpd/snmp_v3_vacm.hpp"
#include <cstdint>
#include <mutex>
#include <string>
#include <vector>

namespace simple_snmpd {

// SNMP v3 Message Processing Model
enum class SNMPv3MessageProcessingModel : uint8_t { V3 = 3 };

// SNMP v3 Security Model
enum class SNMPv3SecurityModel : uint8_t { USM = 3 };

// SNMP v3 Message Flags
struct SNMPv3MessageFlags {
  bool reportable : 1;
  bool privacy : 1;
  bool authentication : 1;
  bool reserved : 5;

  SNMPv3MessageFlags()
      : reportable(false), privacy(false), authentication(false), reserved(0) {}

  uint8_t to_byte() const {
    return (reportable ? 0x80 : 0) | (privacy ? 0x40 : 0) |
           (authentication ? 0x20 : 0) | (reserved & 0x1F);
  }

  void from_byte(uint8_t flags) {
    reportable = (flags & 0x80) != 0;
    privacy = (flags & 0x40) != 0;
    authentication = (flags & 0x20) != 0;
    reserved = flags & 0x1F;
  }
};

// SNMP v3 Scoped PDU
struct SNMPv3ScopedPDU {
  std::vector<uint8_t> context_engine_id;
  std::string context_name;
  SNMPPacket pdu;

  SNMPv3ScopedPDU() = default;
};

// SNMP v3 Message
class SNMPv3Packet {
public:
  SNMPv3Packet();
  SNMPv3Packet(const std::vector<uint8_t> &data);
  ~SNMPv3Packet() = default;

  // Message header
  void set_message_id(uint32_t message_id) { message_id_ = message_id; }
  uint32_t get_message_id() const { return message_id_; }

  void set_max_size(uint32_t max_size) { max_size_ = max_size; }
  uint32_t get_max_size() const { return max_size_; }

  void set_message_flags(const SNMPv3MessageFlags &flags) {
    message_flags_ = flags;
  }
  SNMPv3MessageFlags get_message_flags() const { return message_flags_; }

  void set_security_model(SNMPv3SecurityModel model) {
    security_model_ = model;
  }
  SNMPv3SecurityModel get_security_model() const { return security_model_; }

  // Security parameters
  void set_security_parameters(const SNMPv3SecurityParameters &params) {
    security_params_ = params;
  }
  SNMPv3SecurityParameters get_security_parameters() const {
    return security_params_;
  }

  // Scoped PDU
  void set_scoped_pdu(const SNMPv3ScopedPDU &scoped_pdu) {
    scoped_pdu_ = scoped_pdu;
  }
  SNMPv3ScopedPDU get_scoped_pdu() const { return scoped_pdu_; }

  // Serialization
  std::vector<uint8_t> serialize() const;
  bool parse(const std::vector<uint8_t> &data);

  // Validation
  bool is_valid() const;
  std::string get_error_message() const { return error_message_; }

  // Security operations
  bool authenticate();
  bool encrypt();
  bool decrypt();

  // Access control
  bool check_access_control() const;

  // Utility
  std::string to_string() const;

private:
  // Message header
  uint32_t message_id_;
  uint32_t max_size_;
  SNMPv3MessageFlags message_flags_;
  SNMPv3SecurityModel security_model_;

  // Security parameters
  SNMPv3SecurityParameters security_params_;

  // Scoped PDU
  SNMPv3ScopedPDU scoped_pdu_;

  // Error handling
  std::string error_message_;

  // Internal methods
  bool parse_message_header(const std::vector<uint8_t> &data, size_t &offset);
  bool parse_security_parameters(const std::vector<uint8_t> &data,
                                 size_t &offset);
  bool parse_scoped_pdu(const std::vector<uint8_t> &data, size_t &offset);

  std::vector<uint8_t> serialize_message_header() const;
  std::vector<uint8_t> serialize_security_parameters() const;
  std::vector<uint8_t> serialize_scoped_pdu() const;

  bool validate_message_header() const;
  bool validate_security_parameters() const;
  bool validate_scoped_pdu() const;
};

// SNMP v3 Message Processor
class SNMPv3MessageProcessor {
public:
  static SNMPv3MessageProcessor &get_instance();

  // Message processing
  bool process_incoming_message(const std::vector<uint8_t> &data,
                                SNMPv3Packet &packet);
  bool process_outgoing_message(const SNMPv3Packet &packet,
                                std::vector<uint8_t> &data);

  // Security processing
  bool process_security_in(const std::vector<uint8_t> &data,
                           SNMPv3Packet &packet);
  bool process_security_out(const SNMPv3Packet &packet,
                            std::vector<uint8_t> &data);

  // Access control
  bool check_access_control(const SNMPv3Packet &packet) const;

  // Configuration
  void set_max_message_size(uint32_t size) { max_message_size_ = size; }
  uint32_t get_max_message_size() const { return max_message_size_; }

  // Statistics
  struct Statistics {
    uint64_t messages_processed;
    uint64_t messages_authenticated;
    uint64_t messages_encrypted;
    uint64_t messages_decrypted;
    uint64_t access_checks;
    uint64_t access_allowed;
    uint64_t access_denied;
    uint64_t parse_errors;
    uint64_t security_errors;

    Statistics()
        : messages_processed(0), messages_authenticated(0),
          messages_encrypted(0), messages_decrypted(0), access_checks(0),
          access_allowed(0), access_denied(0), parse_errors(0),
          security_errors(0) {}
  };

  Statistics get_statistics() const { return statistics_; }
  void reset_statistics();

private:
  SNMPv3MessageProcessor();
  ~SNMPv3MessageProcessor() = default;

  // Disable copy constructor and assignment operator
  SNMPv3MessageProcessor(const SNMPv3MessageProcessor &) = delete;
  SNMPv3MessageProcessor &operator=(const SNMPv3MessageProcessor &) = delete;

  // Member variables
  uint32_t max_message_size_;
  mutable std::mutex mutex_;
  mutable Statistics statistics_;
};

// Utility functions
std::string
message_processing_model_to_string(SNMPv3MessageProcessingModel model);
std::string security_model_to_string(SNMPv3SecurityModel model);
std::string message_flags_to_string(const SNMPv3MessageFlags &flags);

SNMPv3MessageProcessingModel
string_to_message_processing_model(const std::string &str);
SNMPv3SecurityModel string_to_security_model(const std::string &str);

} // namespace simple_snmpd
