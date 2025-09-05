#pragma once

#include <vector>
#include <queue>
#include <memory>
#include <thread>
#include <mutex>
#include <condition_variable>
#include <future>
#include <functional>
#include <stdexcept>
#include <atomic>
#include <cstdint>

namespace simple_snmpd {

// Thread pool for handling SNMP requests concurrently
class ThreadPool {
public:
    explicit ThreadPool(size_t num_threads = std::thread::hardware_concurrency());
    ~ThreadPool();

    // Add task to the pool
    template<class F, class... Args>
    auto enqueue(F&& f, Args&&... args) 
        -> std::future<typename std::invoke_result<F, Args...>::type>;

    // Get current number of threads
    size_t get_thread_count() const { return workers_.size(); }
    
    // Get number of pending tasks
    size_t get_pending_tasks() const;
    
    // Get number of active threads
    size_t get_active_threads() const { return active_threads_.load(); }
    
    // Check if pool is running
    bool is_running() const { return !stop_; }
    
    // Shutdown the pool
    void shutdown();
    
    // Wait for all tasks to complete
    void wait_for_all();
    
    // Statistics
    struct Statistics {
        uint64_t total_tasks_processed;
        uint64_t total_tasks_enqueued;
        uint64_t max_queue_size;
        uint64_t current_queue_size;
        uint64_t max_active_threads;
        uint64_t current_active_threads;
        std::chrono::milliseconds total_processing_time;
        std::chrono::milliseconds average_processing_time;
        
        Statistics() : total_tasks_processed(0), total_tasks_enqueued(0),
                      max_queue_size(0), current_queue_size(0),
                      max_active_threads(0), current_active_threads(0),
                      total_processing_time(0), average_processing_time(0) {}
    };
    
    Statistics get_statistics() const;
    void reset_statistics();

private:
    // Worker threads
    std::vector<std::thread> workers_;
    
    // Task queue
    std::queue<std::function<void()>> tasks_;
    
    // Synchronization
    mutable std::mutex queue_mutex_;
    std::condition_variable condition_;
    std::atomic<bool> stop_;
    
    // Statistics
    mutable std::mutex stats_mutex_;
    mutable Statistics statistics_;
    std::atomic<uint64_t> active_threads_;
    std::atomic<uint64_t> pending_tasks_;
    
    // Worker function
    void worker_loop();
    
    // Update statistics
    void update_statistics(std::chrono::milliseconds processing_time);
};

// SNMP Request Handler
class SNMPRequestHandler {
public:
    struct Request {
        std::vector<uint8_t> data;
        std::string client_ip;
        uint16_t client_port;
        std::chrono::system_clock::time_point timestamp;
        uint64_t request_id;
        
        Request() : client_port(0), request_id(0) {}
    };
    
    struct Response {
        std::vector<uint8_t> data;
        std::string client_ip;
        uint16_t client_port;
        std::chrono::system_clock::time_point timestamp;
        uint64_t request_id;
        bool success;
        std::string error_message;
        
        Response() : client_port(0), request_id(0), success(false) {}
    };
    
    // Process SNMP request
    virtual Response process_request(const Request& request) = 0;
    
    virtual ~SNMPRequestHandler() = default;
};

// SNMP Thread Pool Manager
class SNMPThreadPoolManager {
public:
    static SNMPThreadPoolManager& get_instance();
    
    // Initialize thread pool
    void initialize(size_t num_threads = std::thread::hardware_concurrency());
    
    // Shutdown thread pool
    void shutdown();
    
    // Set request handler
    void set_request_handler(std::shared_ptr<SNMPRequestHandler> handler);
    
    // Process request asynchronously
    std::future<SNMPRequestHandler::Response> process_request_async(
        const SNMPRequestHandler::Request& request);
    
    // Process request synchronously
    SNMPRequestHandler::Response process_request_sync(
        const SNMPRequestHandler::Request& request);
    
    // Get thread pool statistics
    ThreadPool::Statistics get_thread_pool_statistics() const;
    
    // Get request handler statistics
    struct RequestHandlerStatistics {
        uint64_t total_requests;
        uint64_t successful_requests;
        uint64_t failed_requests;
        uint64_t v1_requests;
        uint64_t v2c_requests;
        uint64_t v3_requests;
        std::chrono::milliseconds total_processing_time;
        std::chrono::milliseconds average_processing_time;
        std::chrono::milliseconds max_processing_time;
        std::chrono::milliseconds min_processing_time;
        
        RequestHandlerStatistics() : total_requests(0), successful_requests(0),
                                   failed_requests(0), v1_requests(0), v2c_requests(0),
                                   v3_requests(0), total_processing_time(0),
                                   average_processing_time(0), max_processing_time(0),
                                   min_processing_time(0) {}
    };
    
    RequestHandlerStatistics get_request_handler_statistics() const;
    void reset_statistics();
    
    // Configuration
    void set_max_queue_size(size_t max_size) { max_queue_size_ = max_size; }
    size_t get_max_queue_size() const { return max_queue_size_; }
    
    void set_request_timeout(std::chrono::milliseconds timeout) { request_timeout_ = timeout; }
    std::chrono::milliseconds get_request_timeout() const { return request_timeout_; }
    
    // Check if pool is running
    bool is_running() const;

private:
    SNMPThreadPoolManager();
    ~SNMPThreadPoolManager() = default;
    
    // Disable copy constructor and assignment operator
    SNMPThreadPoolManager(const SNMPThreadPoolManager&) = delete;
    SNMPThreadPoolManager& operator=(const SNMPThreadPoolManager&) = delete;
    
    // Member variables
    std::unique_ptr<ThreadPool> thread_pool_;
    std::shared_ptr<SNMPRequestHandler> request_handler_;
    size_t max_queue_size_;
    std::chrono::milliseconds request_timeout_;
    
    mutable std::mutex stats_mutex_;
    mutable RequestHandlerStatistics statistics_;
    std::atomic<uint64_t> request_counter_;
};

// Utility functions
std::string thread_pool_statistics_to_string(const ThreadPool::Statistics& stats);
std::string request_handler_statistics_to_string(const SNMPThreadPoolManager::RequestHandlerStatistics& stats);

} // namespace simple_snmpd
