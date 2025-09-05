#pragma once

#include <chrono>
#include <cstdint>
#include <map>
#include <memory>
#include <mutex>
#include <string>
#include <vector>

namespace simple_snmpd {

// SNMP v3 Security Levels
enum class SNMPv3SecurityLevel : uint8_t {
  NO_AUTH_NO_PRIV = 1, // noAuthNoPriv
  AUTH_NO_PRIV = 2,    // authNoPriv
  AUTH_PRIV = 3        // authPriv
};

// SNMP v3 Authentication Protocols
enum class SNMPv3AuthProtocol : uint8_t {
  NONE = 0,
  MD5 = 1,
  SHA1 = 2,
  SHA224 = 3,
  SHA256 = 4,
  SHA384 = 5,
  SHA512 = 6
};

// SNMP v3 Privacy Protocols
enum class SNMPv3PrivProtocol : uint8_t {
  NONE = 0,
  DES = 1,
  AES128 = 2,
  AES192 = 3,
  AES256 = 4
};

// SNMP v3 User Security Model
struct SNMPv3User {
  std::string username;
  SNMPv3SecurityLevel security_level;
  SNMPv3AuthProtocol auth_protocol;
  SNMPv3PrivProtocol priv_protocol;
  std::string auth_key;
  std::string priv_key;
  std::string auth_password;
  std::string priv_password;
  std::chrono::system_clock::time_point created_at;
  std::chrono::system_clock::time_point last_used;
  bool enabled;

  SNMPv3User()
      : security_level(SNMPv3SecurityLevel::NO_AUTH_NO_PRIV),
        auth_protocol(SNMPv3AuthProtocol::NONE),
        priv_protocol(SNMPv3PrivProtocol::NONE), enabled(true),
        created_at(std::chrono::system_clock::now()),
        last_used(std::chrono::system_clock::now()) {}
};

// SNMP v3 Engine ID
class SNMPv3EngineID {
public:
  SNMPv3EngineID();
  SNMPv3EngineID(const std::vector<uint8_t> &engine_id);
  SNMPv3EngineID(const std::string &engine_id_hex);

  const std::vector<uint8_t> &get_bytes() const { return engine_id_; }
  std::string get_hex() const;
  std::string get_dotted() const;

  bool is_valid() const { return !engine_id_.empty(); }
  size_t size() const { return engine_id_.size(); }

  bool operator==(const SNMPv3EngineID &other) const;
  bool operator!=(const SNMPv3EngineID &other) const;

private:
  std::vector<uint8_t> engine_id_;
  void generate_default();
};

// SNMP v3 Security Parameters
struct SNMPv3SecurityParameters {
  SNMPv3EngineID engine_id;
  std::string username;
  uint32_t engine_boots;
  uint32_t engine_time;
  std::vector<uint8_t> auth_key;
  std::vector<uint8_t> priv_key;
  std::vector<uint8_t> auth_params;
  std::vector<uint8_t> priv_params;
  SNMPv3SecurityLevel security_level;
  SNMPv3AuthProtocol auth_protocol;
  SNMPv3PrivProtocol priv_protocol;

  SNMPv3SecurityParameters()
      : engine_boots(0), engine_time(0),
        security_level(SNMPv3SecurityLevel::NO_AUTH_NO_PRIV),
        auth_protocol(SNMPv3AuthProtocol::NONE),
        priv_protocol(SNMPv3PrivProtocol::NONE) {}
};

// SNMP v3 User-based Security Model Manager
class SNMPv3USMManager {
public:
  static SNMPv3USMManager &get_instance();

  // User management
  bool add_user(const SNMPv3User &user);
  bool remove_user(const std::string &username);
  bool update_user(const SNMPv3User &user);
  SNMPv3User *get_user(const std::string &username);
  std::vector<std::string> list_users() const;

  // Engine ID management
  void set_engine_id(const SNMPv3EngineID &engine_id);
  SNMPv3EngineID get_engine_id() const;
  void generate_engine_id();

  // Time management
  uint32_t get_engine_boots() const { return engine_boots_; }
  uint32_t get_engine_time() const;
  void update_engine_time();

  // Key generation
  bool generate_auth_key(const std::string &username,
                         const std::string &password,
                         SNMPv3AuthProtocol protocol,
                         std::vector<uint8_t> &key);
  bool generate_priv_key(const std::string &username,
                         const std::string &password,
                         SNMPv3PrivProtocol protocol,
                         std::vector<uint8_t> &key);

  // Authentication
  bool authenticate_request(const SNMPv3SecurityParameters &params,
                            const std::vector<uint8_t> &message);
  bool generate_auth_params(const SNMPv3SecurityParameters &params,
                            const std::vector<uint8_t> &message,
                            std::vector<uint8_t> &auth_params);

  // Privacy
  bool encrypt_data(const SNMPv3SecurityParameters &params,
                    const std::vector<uint8_t> &data,
                    std::vector<uint8_t> &encrypted_data);
  bool decrypt_data(const SNMPv3SecurityParameters &params,
                    const std::vector<uint8_t> &encrypted_data,
                    std::vector<uint8_t> &data);

  // Security level validation
  bool validate_security_level(const std::string &username,
                               SNMPv3SecurityLevel required_level) const;

  // Configuration
  void set_max_users(size_t max_users) { max_users_ = max_users; }
  size_t get_max_users() const { return max_users_; }

  // Statistics
  struct Statistics {
    uint64_t total_requests;
    uint64_t auth_successes;
    uint64_t auth_failures;
    uint64_t priv_successes;
    uint64_t priv_failures;
    uint64_t invalid_users;
    uint64_t security_level_violations;

    Statistics()
        : total_requests(0), auth_successes(0), auth_failures(0),
          priv_successes(0), priv_failures(0), invalid_users(0),
          security_level_violations(0) {}
  };

  Statistics get_statistics() const { return statistics_; }
  void reset_statistics();

private:
  SNMPv3USMManager();
  ~SNMPv3USMManager() = default;

  // Disable copy constructor and assignment operator
  SNMPv3USMManager(const SNMPv3USMManager &) = delete;
  SNMPv3USMManager &operator=(const SNMPv3USMManager &) = delete;

  // Internal methods
  bool validate_user(const SNMPv3User &user) const;
  bool is_username_valid(const std::string &username) const;
  void update_user_last_used(const std::string &username);

  // Hash functions
  std::vector<uint8_t> md5_hash(const std::vector<uint8_t> &data) const;
  std::vector<uint8_t> sha1_hash(const std::vector<uint8_t> &data) const;
  std::vector<uint8_t> sha256_hash(const std::vector<uint8_t> &data) const;

  // Encryption/Decryption
  std::vector<uint8_t> des_encrypt(const std::vector<uint8_t> &key,
                                   const std::vector<uint8_t> &data) const;
  std::vector<uint8_t> des_decrypt(const std::vector<uint8_t> &key,
                                   const std::vector<uint8_t> &data) const;
  std::vector<uint8_t> aes_encrypt(const std::vector<uint8_t> &key,
                                   const std::vector<uint8_t> &data) const;
  std::vector<uint8_t> aes_decrypt(const std::vector<uint8_t> &key,
                                   const std::vector<uint8_t> &data) const;

  // Member variables
  std::map<std::string, SNMPv3User> users_;
  SNMPv3EngineID engine_id_;
  uint32_t engine_boots_;
  std::chrono::system_clock::time_point engine_start_time_;
  size_t max_users_;
  mutable std::mutex mutex_;
  mutable Statistics statistics_;
};

// Utility functions
std::string security_level_to_string(SNMPv3SecurityLevel level);
std::string auth_protocol_to_string(SNMPv3AuthProtocol protocol);
std::string priv_protocol_to_string(SNMPv3PrivProtocol protocol);

SNMPv3SecurityLevel string_to_security_level(const std::string &str);
SNMPv3AuthProtocol string_to_auth_protocol(const std::string &str);
SNMPv3PrivProtocol string_to_priv_protocol(const std::string &str);

} // namespace simple_snmpd
