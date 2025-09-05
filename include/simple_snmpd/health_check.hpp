#pragma once

#include <atomic>
#include <chrono>
#include <cstdint>
#include <functional>
#include <map>
#include <memory>
#include <mutex>
#include <string>
#include <thread>
#include <vector>

namespace simple_snmpd {

// Health check status
enum class HealthStatus { HEALTHY, UNHEALTHY, DEGRADED, UNKNOWN };

// Health check result
struct HealthCheckResult {
  HealthStatus status;
  std::string message;
  std::map<std::string, std::string> details;
  std::chrono::system_clock::time_point timestamp;
  std::chrono::milliseconds duration;

  HealthCheckResult() : status(HealthStatus::UNKNOWN), duration(0) {}
  HealthCheckResult(HealthStatus s, const std::string &msg)
      : status(s), message(msg), timestamp(std::chrono::system_clock::now()),
        duration(0) {}
};

// Health check function type
using HealthCheckFunction = std::function<HealthCheckResult()>;

// Individual health check
class HealthCheck {
public:
  HealthCheck(
      const std::string &name, const std::string &description,
      HealthCheckFunction check_func,
      std::chrono::milliseconds interval = std::chrono::milliseconds(5000));
  ~HealthCheck() = default;

  // Getters
  const std::string &get_name() const { return name_; }
  const std::string &get_description() const { return description_; }
  HealthStatus get_status() const { return last_result_.status; }
  const HealthCheckResult &get_last_result() const { return last_result_; }
  std::chrono::milliseconds get_interval() const { return interval_; }
  bool is_enabled() const { return enabled_; }

  // Setters
  void set_enabled(bool enabled) { enabled_ = enabled; }
  void set_interval(std::chrono::milliseconds interval) {
    interval_ = interval;
  }

  // Run health check
  HealthCheckResult run_check();

  // Check if it's time to run
  bool should_run() const;

private:
  std::string name_;
  std::string description_;
  HealthCheckFunction check_func_;
  std::chrono::milliseconds interval_;
  std::chrono::system_clock::time_point last_run_;
  HealthCheckResult last_result_;
  std::atomic<bool> enabled_;
  mutable std::mutex mutex_;
};

// Health check manager
class HealthCheckManager {
public:
  static HealthCheckManager &get_instance();

  // Register health checks
  void register_health_check(std::shared_ptr<HealthCheck> health_check);
  void unregister_health_check(const std::string &name);

  // Run all health checks
  std::map<std::string, HealthCheckResult> run_all_checks();

  // Run specific health check
  HealthCheckResult run_check(const std::string &name);

  // Get health check
  std::shared_ptr<HealthCheck> get_health_check(const std::string &name);

  // Get all health checks
  std::vector<std::shared_ptr<HealthCheck>> get_all_health_checks();

  // Get overall health status
  HealthStatus get_overall_status();

  // Start/stop background monitoring
  void start_monitoring();
  void stop_monitoring();
  bool is_monitoring() const { return monitoring_; }

  // Configuration
  void set_monitoring_interval(std::chrono::milliseconds interval) {
    monitoring_interval_ = interval;
  }
  std::chrono::milliseconds get_monitoring_interval() const {
    return monitoring_interval_;
  }

  // Statistics
  struct Statistics {
    uint64_t total_checks_run;
    uint64_t successful_checks;
    uint64_t failed_checks;
    uint64_t degraded_checks;
    std::chrono::milliseconds total_check_time;
    std::chrono::milliseconds average_check_time;
    std::chrono::milliseconds max_check_time;
    std::chrono::milliseconds min_check_time;

    Statistics()
        : total_checks_run(0), successful_checks(0), failed_checks(0),
          degraded_checks(0), total_check_time(0), average_check_time(0),
          max_check_time(0), min_check_time(0) {}
  };

  Statistics get_statistics() const { return statistics_; }
  void reset_statistics();

private:
  HealthCheckManager();
  ~HealthCheckManager() = default;

  // Disable copy constructor and assignment operator
  HealthCheckManager(const HealthCheckManager &) = delete;
  HealthCheckManager &operator=(const HealthCheckManager &) = delete;

  // Member variables
  std::map<std::string, std::shared_ptr<HealthCheck>> health_checks_;
  std::atomic<bool> monitoring_;
  std::thread monitoring_thread_;
  std::chrono::milliseconds monitoring_interval_;

  mutable std::mutex mutex_;
  mutable Statistics statistics_;

  // Background monitoring loop
  void monitoring_loop();

  // Update statistics
  void update_statistics(const HealthCheckResult &result,
                         std::chrono::milliseconds duration);
};

// SNMP-specific health checks
class SNMPHealthChecks {
public:
  static SNMPHealthChecks &get_instance();

  // Initialize all SNMP health checks
  void initialize();

  // Individual health check functions
  HealthCheckResult check_snmp_server();
  HealthCheckResult check_mib_manager();
  HealthCheckResult check_security_manager();
  HealthCheckResult check_thread_pool();
  HealthCheckResult check_memory_pool();
  HealthCheckResult check_network_connectivity();
  HealthCheckResult check_disk_space();
  HealthCheckResult check_system_resources();

  // Get health check manager
  HealthCheckManager &get_manager() { return manager_; }

private:
  SNMPHealthChecks() : manager_(HealthCheckManager::get_instance()) {}
  ~SNMPHealthChecks() = default;

  // Disable copy constructor and assignment operator
  SNMPHealthChecks(const SNMPHealthChecks &) = delete;
  SNMPHealthChecks &operator=(const SNMPHealthChecks &) = delete;

  HealthCheckManager &manager_;
};

// Health check HTTP server
class HealthCheckHTTPServer {
public:
  HealthCheckHTTPServer(uint16_t port = 8080);
  ~HealthCheckHTTPServer();

  // Start/stop server
  bool start();
  void stop();
  bool is_running() const { return running_; }

  // Configuration
  void set_port(uint16_t port) { port_ = port; }
  uint16_t get_port() const { return port_; }

  void set_health_path(const std::string &path) { health_path_ = path; }
  const std::string &get_health_path() const { return health_path_; }

  void set_ready_path(const std::string &path) { ready_path_ = path; }
  const std::string &get_ready_path() const { return ready_path_; }

private:
  uint16_t port_;
  std::string health_path_;
  std::string ready_path_;
  std::atomic<bool> running_;
  std::thread server_thread_;

  // Server loop
  void server_loop();

  // Handle HTTP request
  std::string handle_request(const std::string &method,
                             const std::string &path);

  // Generate health response
  std::string generate_health_response();
  std::string generate_ready_response();
};

// Utility functions
std::string health_status_to_string(HealthStatus status);
std::string health_status_to_http_status(HealthStatus status);
std::string
generate_health_json(const std::map<std::string, HealthCheckResult> &results);

} // namespace simple_snmpd
