#pragma once

#include <atomic>
#include <chrono>
#include <cstdint>
#include <map>
#include <memory>
#include <mutex>
#include <string>
#include <thread>
#include <vector>

namespace simple_snmpd {

// Prometheus metric types
enum class PrometheusMetricType { COUNTER, GAUGE, HISTOGRAM, SUMMARY };

// Prometheus metric value
struct PrometheusMetricValue {
  double value;
  std::map<std::string, std::string> labels;
  std::chrono::system_clock::time_point timestamp;

  PrometheusMetricValue() : value(0.0) {}
  PrometheusMetricValue(double v) : value(v) {}
  PrometheusMetricValue(double v, const std::map<std::string, std::string> &l)
      : value(v), labels(l) {}
};

// Prometheus histogram bucket
struct PrometheusHistogramBucket {
  double upper_bound;
  uint64_t count;

  PrometheusHistogramBucket(double bound, uint64_t c)
      : upper_bound(bound), count(c) {}
};

// Prometheus metric
class PrometheusMetric {
public:
  PrometheusMetric(const std::string &name, const std::string &help,
                   PrometheusMetricType type,
                   const std::vector<std::string> &label_names = {});
  ~PrometheusMetric() = default;

  // Getters
  const std::string &get_name() const { return name_; }
  const std::string &get_help() const { return help_; }
  PrometheusMetricType get_type() const { return type_; }
  const std::vector<std::string> &get_label_names() const {
    return label_names_;
  }

  // Counter operations
  void increment(double value = 1.0,
                 const std::map<std::string, std::string> &labels = {});
  void set_counter_value(double value,
                         const std::map<std::string, std::string> &labels = {});

  // Gauge operations
  void set_gauge_value(double value,
                       const std::map<std::string, std::string> &labels = {});
  void add_gauge_value(double value,
                       const std::map<std::string, std::string> &labels = {});
  void
  subtract_gauge_value(double value,
                       const std::map<std::string, std::string> &labels = {});

  // Histogram operations
  void observe(double value,
               const std::map<std::string, std::string> &labels = {});
  void set_histogram_buckets(const std::vector<double> &buckets);

  // Summary operations
  void observe_summary(double value,
                       const std::map<std::string, std::string> &labels = {});

  // Get current values
  std::vector<PrometheusMetricValue> get_values() const;

  // Serialize to Prometheus format
  std::string serialize() const;

private:
  std::string name_;
  std::string help_;
  PrometheusMetricType type_;
  std::vector<std::string> label_names_;

  // Values storage
  mutable std::mutex mutex_;
  std::map<std::string, PrometheusMetricValue> values_;

  // Histogram buckets
  std::vector<double> histogram_buckets_;

  // Helper methods
  std::string
  serialize_labels(const std::map<std::string, std::string> &labels) const;
  std::string serialize_value(const PrometheusMetricValue &value) const;
  std::string get_metric_type_string() const;
};

// Prometheus metrics registry
class PrometheusRegistry {
public:
  static PrometheusRegistry &get_instance();

  // Register metrics
  void register_metric(std::shared_ptr<PrometheusMetric> metric);
  void unregister_metric(const std::string &name);

  // Get metrics
  std::shared_ptr<PrometheusMetric> get_metric(const std::string &name);
  std::vector<std::shared_ptr<PrometheusMetric>> get_all_metrics();

  // Serialize all metrics
  std::string serialize_all() const;

  // Clear all metrics
  void clear();

private:
  PrometheusRegistry() = default;
  ~PrometheusRegistry() = default;

  // Disable copy constructor and assignment operator
  PrometheusRegistry(const PrometheusRegistry &) = delete;
  PrometheusRegistry &operator=(const PrometheusRegistry &) = delete;

  mutable std::mutex mutex_;
  std::map<std::string, std::shared_ptr<PrometheusMetric>> metrics_;
};

// SNMP-specific metrics
class SNMPMetrics {
public:
  static SNMPMetrics &get_instance();

  // Initialize metrics
  void initialize();

  // SNMP request metrics
  void increment_requests_total(const std::string &version,
                                const std::string &pdu_type,
                                const std::string &result);
  void increment_requests_duration_seconds(double duration,
                                           const std::string &version);
  void increment_requests_size_bytes(size_t size, const std::string &version);

  // SNMP error metrics
  void increment_errors_total(const std::string &error_type,
                              const std::string &version);

  // SNMP security metrics
  void increment_auth_failures_total(const std::string &version);
  void increment_priv_failures_total(const std::string &version);
  void increment_access_denied_total(const std::string &version);

  // SNMP MIB metrics
  void increment_mib_queries_total(const std::string &mib_name,
                                   const std::string &oid);
  void increment_mib_updates_total(const std::string &mib_name,
                                   const std::string &oid);

  // System metrics
  void set_memory_usage_bytes(size_t bytes);
  void set_cpu_usage_percent(double percent);
  void set_thread_count(uint32_t count);
  void set_queue_size(uint32_t size);

  // Network metrics
  void increment_bytes_received_total(size_t bytes);
  void increment_bytes_sent_total(size_t bytes);
  void increment_connections_total();
  void increment_disconnections_total();

  // Get metrics registry
  PrometheusRegistry &get_registry() { return registry_; }

private:
  SNMPMetrics() : registry_(PrometheusRegistry::get_instance()) {}
  ~SNMPMetrics() = default;

  // Disable copy constructor and assignment operator
  SNMPMetrics(const SNMPMetrics &) = delete;
  SNMPMetrics &operator=(const SNMPMetrics &) = delete;

  PrometheusRegistry &registry_;

  // Metric pointers
  std::shared_ptr<PrometheusMetric> requests_total_;
  std::shared_ptr<PrometheusMetric> requests_duration_seconds_;
  std::shared_ptr<PrometheusMetric> requests_size_bytes_;
  std::shared_ptr<PrometheusMetric> errors_total_;
  std::shared_ptr<PrometheusMetric> auth_failures_total_;
  std::shared_ptr<PrometheusMetric> priv_failures_total_;
  std::shared_ptr<PrometheusMetric> access_denied_total_;
  std::shared_ptr<PrometheusMetric> mib_queries_total_;
  std::shared_ptr<PrometheusMetric> mib_updates_total_;
  std::shared_ptr<PrometheusMetric> memory_usage_bytes_;
  std::shared_ptr<PrometheusMetric> cpu_usage_percent_;
  std::shared_ptr<PrometheusMetric> thread_count_;
  std::shared_ptr<PrometheusMetric> queue_size_;
  std::shared_ptr<PrometheusMetric> bytes_received_total_;
  std::shared_ptr<PrometheusMetric> bytes_sent_total_;
  std::shared_ptr<PrometheusMetric> connections_total_;
  std::shared_ptr<PrometheusMetric> disconnections_total_;
};

// Prometheus HTTP server
class PrometheusHTTPServer {
public:
  PrometheusHTTPServer(uint16_t port = 9090);
  ~PrometheusHTTPServer();

  // Start/stop server
  bool start();
  void stop();
  bool is_running() const { return running_; }

  // Configuration
  void set_port(uint16_t port) { port_ = port; }
  uint16_t get_port() const { return port_; }

  void set_metrics_path(const std::string &path) { metrics_path_ = path; }
  const std::string &get_metrics_path() const { return metrics_path_; }

  // Statistics
  struct Statistics {
    uint64_t total_requests;
    uint64_t successful_requests;
    uint64_t failed_requests;
    std::chrono::milliseconds total_response_time;
    std::chrono::milliseconds average_response_time;

    Statistics()
        : total_requests(0), successful_requests(0), failed_requests(0),
          total_response_time(0), average_response_time(0) {}
  };

  Statistics get_statistics() const { return statistics_; }
  void reset_statistics();

private:
  uint16_t port_;
  std::string metrics_path_;
  std::atomic<bool> running_;
  std::thread server_thread_;

  mutable std::mutex stats_mutex_;
  Statistics statistics_;

  // Server loop
  void server_loop();

  // Handle HTTP request
  std::string handle_request(const std::string &method,
                             const std::string &path);

  // Update statistics
  void update_statistics(bool success, std::chrono::milliseconds response_time);
};

// Utility functions
std::string prometheus_metric_type_to_string(PrometheusMetricType type);
std::string escape_prometheus_string(const std::string &str);
std::string
format_prometheus_timestamp(std::chrono::system_clock::time_point timestamp);

} // namespace simple_snmpd
