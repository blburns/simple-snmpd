/*
 * include/simple_snmpd/snmp_security.hpp
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

#ifndef SIMPLE_SNMPD_SNMP_SECURITY_HPP
#define SIMPLE_SNMPD_SNMP_SECURITY_HPP

#include <string>
#include <vector>
#include <set>
#include <map>
#include <chrono>
#include <mutex>

namespace simple_snmpd {

// Access control entry
struct AccessControlEntry {
    std::string community;
    std::string source_ip;
    std::string subnet_mask;
    bool read_only;
    std::set<std::string> allowed_oids;
    
    AccessControlEntry() : read_only(true) {}
    AccessControlEntry(const std::string& comm, const std::string& ip, bool ro = true)
        : community(comm), source_ip(ip), read_only(ro) {}
};

// Rate limiting entry
struct RateLimitEntry {
    std::chrono::steady_clock::time_point last_request;
    uint32_t request_count;
    uint32_t max_requests;
    std::chrono::seconds window_duration;
    
    RateLimitEntry() : request_count(0), max_requests(100), window_duration(std::chrono::seconds(60)) {}
    RateLimitEntry(uint32_t max_req, std::chrono::seconds window)
        : request_count(0), max_requests(max_req), window_duration(window) {}
};

// Security manager class
class SecurityManager {
public:
    static SecurityManager& get_instance();
    
    // Access control
    bool is_access_allowed(const std::string& community, const std::string& source_ip) const;
    bool is_oid_allowed(const std::string& community, const std::string& oid) const;
    bool is_write_allowed(const std::string& community) const;
    
    // Rate limiting
    bool check_rate_limit(const std::string& source_ip);
    void reset_rate_limit(const std::string& source_ip);
    
    // Configuration
    void add_access_control_entry(const AccessControlEntry& entry);
    void remove_access_control_entry(const std::string& community, const std::string& source_ip);
    void set_rate_limit(const std::string& source_ip, uint32_t max_requests, std::chrono::seconds window);
    void set_default_rate_limit(uint32_t max_requests, std::chrono::seconds window);
    
    // IP filtering
    void add_allowed_ip(const std::string& ip);
    void add_denied_ip(const std::string& ip);
    void add_allowed_subnet(const std::string& subnet);
    void add_denied_subnet(const std::string& subnet);
    bool is_ip_allowed(const std::string& ip) const;
    
    // Community string validation
    void add_valid_community(const std::string& community, bool read_only = true);
    void remove_community(const std::string& community);
    bool is_community_valid(const std::string& community) const;
    
    // Initialize default security settings
    void initialize_defaults();
    
private:
    SecurityManager() = default;
    ~SecurityManager() = default;
    SecurityManager(const SecurityManager&) = delete;
    SecurityManager& operator=(const SecurityManager&) = delete;
    
    // Access control storage
    std::vector<AccessControlEntry> access_control_entries_;
    mutable std::mutex access_control_mutex_;
    
    // Rate limiting storage
    std::map<std::string, RateLimitEntry> rate_limits_;
    mutable std::mutex rate_limit_mutex_;
    
    // IP filtering
    std::set<std::string> allowed_ips_;
    std::set<std::string> denied_ips_;
    std::set<std::string> allowed_subnets_;
    std::set<std::string> denied_subnets_;
    mutable std::mutex ip_filter_mutex_;
    
    // Community strings
    std::map<std::string, bool> valid_communities_; // community -> read_only
    mutable std::mutex community_mutex_;
    
    // Default rate limiting
    uint32_t default_max_requests_;
    std::chrono::seconds default_window_duration_;
    
    // Helper functions
    bool is_ip_in_subnet(const std::string& ip, const std::string& subnet) const;
    bool is_ip_in_list(const std::string& ip, const std::set<std::string>& ip_list) const;
    bool is_ip_in_subnet_list(const std::string& ip, const std::set<std::string>& subnet_list) const;
};

} // namespace simple_snmpd

#endif // SIMPLE_SNMPD_SNMP_SECURITY_HPP
