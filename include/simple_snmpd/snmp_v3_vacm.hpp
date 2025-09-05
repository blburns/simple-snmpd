#pragma once

#include <string>
#include <vector>
#include <map>
#include <memory>
#include <cstdint>
#include <set>
#include <mutex>

namespace simple_snmpd {

// VACM Security Level
enum class VACMSecurityLevel : uint8_t {
    NO_AUTH_NO_PRIV = 1,    // noAuthNoPriv
    AUTH_NO_PRIV = 2,       // authNoPriv
    AUTH_PRIV = 3           // authPriv
};

// VACM Context Match Type
enum class VACMContextMatch : uint8_t {
    EXACT = 1,              // exact
    PREFIX = 2              // prefix
};

// VACM View Type
enum class VACMViewType : uint8_t {
    INCLUDED = 1,           // included
    EXCLUDED = 2            // excluded
};

// VACM Group
struct VACMGroup {
    std::string group_name;
    std::string security_model;
    VACMSecurityLevel security_level;
    std::set<std::string> contexts;
    
    VACMGroup() : security_level(VACMSecurityLevel::NO_AUTH_NO_PRIV) {}
};

// VACM Access Entry
struct VACMAccess {
    std::string group_name;
    std::string context_prefix;
    VACMContextMatch context_match;
    VACMSecurityLevel security_level;
    VACMSecurityLevel security_model;
    std::string read_view;
    std::string write_view;
    std::string notify_view;
    
    VACMAccess() 
        : context_match(VACMContextMatch::EXACT)
        , security_level(VACMSecurityLevel::NO_AUTH_NO_PRIV)
        , security_model(VACMSecurityLevel::NO_AUTH_NO_PRIV) {}
};

// VACM View Entry
struct VACMView {
    std::string view_name;
    std::string view_subtree;
    VACMViewType view_type;
    std::string view_mask;
    
    VACMView() : view_type(VACMViewType::INCLUDED) {}
};

// VACM Context
struct VACMContext {
    std::string context_name;
    std::string context_oid;
    std::string context_description;
    bool enabled;
    
    VACMContext() : enabled(true) {}
};

// VACM Manager
class VACMManager {
public:
    static VACMManager& get_instance();
    
    // Group management
    bool add_group(const VACMGroup& group);
    bool remove_group(const std::string& group_name);
    bool update_group(const VACMGroup& group);
    VACMGroup* get_group(const std::string& group_name);
    std::vector<std::string> list_groups() const;
    
    // Access management
    bool add_access(const VACMAccess& access);
    bool remove_access(const std::string& group_name, const std::string& context_prefix);
    bool update_access(const VACMAccess& access);
    VACMAccess* get_access(const std::string& group_name, const std::string& context_prefix);
    std::vector<VACMAccess> list_access_entries() const;
    
    // View management
    bool add_view(const VACMView& view);
    bool remove_view(const std::string& view_name);
    bool update_view(const VACMView& view);
    VACMView* get_view(const std::string& view_name);
    std::vector<std::string> list_views() const;
    
    // Context management
    bool add_context(const VACMContext& context);
    bool remove_context(const std::string& context_name);
    bool update_context(const VACMContext& context);
    VACMContext* get_context(const std::string& context_name);
    std::vector<std::string> list_contexts() const;
    
    // Access control
    bool is_read_allowed(const std::string& username, 
                        const std::string& context, 
                        const std::string& oid,
                        VACMSecurityLevel security_level) const;
    
    bool is_write_allowed(const std::string& username, 
                         const std::string& context, 
                         const std::string& oid,
                         VACMSecurityLevel security_level) const;
    
    bool is_notify_allowed(const std::string& username, 
                          const std::string& context, 
                          const std::string& oid,
                          VACMSecurityLevel security_level) const;
    
    // View checking
    bool is_oid_in_view(const std::string& view_name, const std::string& oid) const;
    
    // Configuration
    void set_default_read_view(const std::string& view_name) { default_read_view_ = view_name; }
    void set_default_write_view(const std::string& view_name) { default_write_view_ = view_name; }
    void set_default_notify_view(const std::string& view_name) { default_notify_view_ = view_name; }
    
    std::string get_default_read_view() const { return default_read_view_; }
    std::string get_default_write_view() const { return default_write_view_; }
    std::string get_default_notify_view() const { return default_notify_view_; }
    
    // Statistics
    struct Statistics {
        uint64_t total_checks;
        uint64_t read_allowed;
        uint64_t read_denied;
        uint64_t write_allowed;
        uint64_t write_denied;
        uint64_t notify_allowed;
        uint64_t notify_denied;
        uint64_t view_checks;
        uint64_t group_lookups;
        uint64_t access_lookups;
        
        Statistics() : total_checks(0), read_allowed(0), read_denied(0),
                      write_allowed(0), write_denied(0), notify_allowed(0),
                      notify_denied(0), view_checks(0), group_lookups(0),
                      access_lookups(0) {}
    };
    
    Statistics get_statistics() const { return statistics_; }
    void reset_statistics();
    
    // Initialize default VACM configuration
    void initialize_defaults();
    
private:
    VACMManager();
    ~VACMManager() = default;
    
    // Disable copy constructor and assignment operator
    VACMManager(const VACMManager&) = delete;
    VACMManager& operator=(const VACMManager&) = delete;
    
    // Internal methods
    bool validate_group(const VACMGroup& group) const;
    bool validate_access(const VACMAccess& access) const;
    bool validate_view(const VACMView& view) const;
    bool validate_context(const VACMContext& context) const;
    
    VACMGroup* find_group_for_user(const std::string& username, 
                                  VACMSecurityLevel security_level) const;
    VACMAccess* find_access_for_group(const std::string& group_name, 
                                     const std::string& context) const;
    
    bool oid_matches_subtree(const std::string& oid, const std::string& subtree) const;
    bool oid_matches_mask(const std::string& oid, const std::string& subtree, 
                         const std::string& mask) const;
    
    // Member variables
    std::map<std::string, VACMGroup> groups_;
    std::map<std::pair<std::string, std::string>, VACMAccess> access_entries_;
    std::map<std::string, VACMView> views_;
    std::map<std::string, VACMContext> contexts_;
    
    std::string default_read_view_;
    std::string default_write_view_;
    std::string default_notify_view_;
    
    mutable std::mutex mutex_;
    mutable Statistics statistics_;
};

// Utility functions
std::string vacm_security_level_to_string(VACMSecurityLevel level);
std::string vacm_context_match_to_string(VACMContextMatch match);
std::string vacm_view_type_to_string(VACMViewType type);

VACMSecurityLevel string_to_vacm_security_level(const std::string& str);
VACMContextMatch string_to_vacm_context_match(const std::string& str);
VACMViewType string_to_vacm_view_type(const std::string& str);

} // namespace simple_snmpd
