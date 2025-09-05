/*
 * include/simple_snmpd/snmp_mib.hpp
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

#ifndef SIMPLE_SNMPD_SNMP_MIB_HPP
#define SIMPLE_SNMPD_SNMP_MIB_HPP

#include <cstdint>
#include <functional>
#include <map>
#include <memory>
#include <string>
#include <vector>

namespace simple_snmpd {

// SNMP data types
enum class SNMPDataType {
  INTEGER = 0x02,
  OCTET_STRING = 0x04,
  NULL_TYPE = 0x05,
  OBJECT_IDENTIFIER = 0x06,
  COUNTER32 = 0x41,
  GAUGE32 = 0x42,
  TIME_TICKS = 0x43,
  COUNTER64 = 0x46
};

// MIB value structure
struct MIBValue {
  SNMPDataType type;
  std::vector<uint8_t> data;

  MIBValue() : type(SNMPDataType::NULL_TYPE) {}
  MIBValue(SNMPDataType t, const std::vector<uint8_t> &d) : type(t), data(d) {}
  MIBValue(SNMPDataType t, const std::string &str) : type(t) {
    data.assign(str.begin(), str.end());
  }
  MIBValue(SNMPDataType t, uint32_t val) : type(t) {
    data.push_back((val >> 24) & 0xFF);
    data.push_back((val >> 16) & 0xFF);
    data.push_back((val >> 8) & 0xFF);
    data.push_back(val & 0xFF);
  }
  MIBValue(SNMPDataType t, uint64_t val) : type(t) {
    for (int i = 7; i >= 0; i--) {
      data.push_back((val >> (i * 8)) & 0xFF);
    }
  }
};

// MIB entry structure
struct MIBEntry {
  std::vector<uint8_t> oid;
  std::string name;
  SNMPDataType type;
  bool read_only;
  std::function<MIBValue()> getter;
  std::function<bool(const MIBValue &)> setter;

  MIBEntry() : read_only(true) {}
  MIBEntry(const std::vector<uint8_t> &o, const std::string &n, SNMPDataType t,
           bool ro = true)
      : oid(o), name(n), type(t), read_only(ro) {}
};

// MIB table entry for tabular objects
struct MIBTableEntry {
  std::vector<uint8_t> oid;
  std::string name;
  SNMPDataType type;
  bool read_only;
  std::function<MIBValue(uint32_t)> getter;
  std::function<bool(uint32_t, const MIBValue &)> setter;

  MIBTableEntry() : read_only(true) {}
  MIBTableEntry(const std::vector<uint8_t> &o, const std::string &n,
                SNMPDataType t, bool ro = true)
      : oid(o), name(n), type(t), read_only(ro) {}
};

// MIB manager class
class MIBManager {
public:
  static MIBManager &get_instance();

  // MIB registration
  void register_scalar(const MIBEntry &entry);
  void register_table(const MIBTableEntry &entry, uint32_t max_index);

  // MIB lookup
  bool get_value(const std::vector<uint8_t> &oid, MIBValue &value) const;
  bool set_value(const std::vector<uint8_t> &oid, const MIBValue &value);
  bool get_next_oid(const std::vector<uint8_t> &oid,
                    std::vector<uint8_t> &next_oid) const;

  // MIB information
  bool is_scalar(const std::vector<uint8_t> &oid) const;
  bool is_table(const std::vector<uint8_t> &oid) const;
  uint32_t get_table_size(const std::vector<uint8_t> &table_oid) const;

  // Initialize standard MIBs
  void initialize_standard_mibs();

private:
  MIBManager() = default;
  ~MIBManager() = default;
  MIBManager(const MIBManager &) = delete;
  MIBManager &operator=(const MIBManager &) = delete;

  // MIB storage
  std::map<std::vector<uint8_t>, MIBEntry> scalar_entries_;
  std::map<std::vector<uint8_t>, MIBTableEntry> table_entries_;
  std::map<std::vector<uint8_t>, uint32_t> table_sizes_;

  // Helper functions
  bool oid_matches(const std::vector<uint8_t> &oid,
                   const std::vector<uint8_t> &pattern) const;
  bool oid_less_than(const std::vector<uint8_t> &oid1,
                     const std::vector<uint8_t> &oid2) const;
  void initialize_system_mib();
  void initialize_interface_mib();
  void initialize_snmp_mib();
};

// OID utility functions
class OIDUtils {
public:
  // Convert OID string to byte array
  static std::vector<uint8_t> string_to_oid(const std::string &oid_str);

  // Convert OID byte array to string
  static std::string oid_to_string(const std::vector<uint8_t> &oid);

  // Check if oid1 is a prefix of oid2
  static bool is_prefix(const std::vector<uint8_t> &oid1,
                        const std::vector<uint8_t> &oid2);

  // Get the next OID in lexicographic order
  static std::vector<uint8_t> get_next_oid(const std::vector<uint8_t> &oid);

  // Compare two OIDs
  static int compare_oids(const std::vector<uint8_t> &oid1,
                          const std::vector<uint8_t> &oid2);
};

} // namespace simple_snmpd

#endif // SIMPLE_SNMPD_SNMP_MIB_HPP
