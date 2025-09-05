#pragma once

#include <vector>
#include <memory>
#include <mutex>
#include <atomic>
#include <cstdint>
#include <cstddef>
#include <array>

namespace simple_snmpd {

// Memory pool for efficient allocation of fixed-size blocks
template<size_t BlockSize, size_t PoolSize>
class MemoryPool {
public:
    MemoryPool();
    ~MemoryPool();
    
    // Allocate a block
    void* allocate();
    
    // Deallocate a block
    void deallocate(void* ptr);
    
    // Get pool statistics
    struct Statistics {
        size_t total_blocks;
        size_t allocated_blocks;
        size_t free_blocks;
        size_t allocation_count;
        size_t deallocation_count;
        size_t peak_allocated_blocks;
        
        Statistics() : total_blocks(PoolSize), allocated_blocks(0), free_blocks(PoolSize),
                      allocation_count(0), deallocation_count(0), peak_allocated_blocks(0) {}
    };
    
    Statistics get_statistics() const;
    void reset_statistics();
    
    // Check if pool is full
    bool is_full() const;
    
    // Check if pool is empty
    bool is_empty() const;
    
    // Get memory usage percentage
    double get_usage_percentage() const;

private:
    // Block structure
    struct Block {
        alignas(std::max_align_t) char data[BlockSize];
        Block* next;
    };
    
    // Pool storage
    std::array<Block, PoolSize> blocks_;
    
    // Free list
    Block* free_list_;
    
    // Statistics
    mutable std::mutex mutex_;
    mutable Statistics statistics_;
    
    // Initialize the pool
    void initialize_pool();
};

// Variable-size memory pool
class VariableMemoryPool {
public:
    explicit VariableMemoryPool(size_t initial_size = 1024 * 1024); // 1MB default
    ~VariableMemoryPool();
    
    // Allocate memory
    void* allocate(size_t size);
    
    // Deallocate memory (no-op for this implementation)
    void deallocate(void* ptr);
    
    // Get pool statistics
    struct Statistics {
        size_t total_allocated;
        size_t current_usage;
        size_t peak_usage;
        size_t allocation_count;
        size_t deallocation_count;
        size_t pool_size;
        
        Statistics() : total_allocated(0), current_usage(0), peak_usage(0),
                      allocation_count(0), deallocation_count(0), pool_size(0) {}
    };
    
    Statistics get_statistics() const;
    void reset_statistics();
    
    // Reset the pool
    void reset();
    
    // Get memory usage percentage
    double get_usage_percentage() const;

private:
    // Pool storage
    std::vector<uint8_t> pool_;
    size_t current_offset_;
    size_t pool_size_;
    
    // Statistics
    mutable std::mutex mutex_;
    mutable Statistics statistics_;
    
    // Expand pool if needed
    void expand_pool(size_t required_size);
};

// SNMP-specific memory pools
class SNMPMemoryPool {
public:
    static SNMPMemoryPool& get_instance();
    
    // Allocate SNMP packet buffer
    void* allocate_packet_buffer(size_t size);
    
    // Deallocate SNMP packet buffer
    void deallocate_packet_buffer(void* ptr);
    
    // Allocate OID buffer
    void* allocate_oid_buffer(size_t size);
    
    // Deallocate OID buffer
    void deallocate_oid_buffer(void* ptr);
    
    // Allocate variable binding
    void* allocate_variable_binding();
    
    // Deallocate variable binding
    void deallocate_variable_binding(void* ptr);
    
    // Get statistics
    struct Statistics {
        VariableMemoryPool::Statistics packet_buffer_stats;
        VariableMemoryPool::Statistics oid_buffer_stats;
        MemoryPool<64, 1000>::Statistics variable_binding_stats; // 64 bytes per varbind
        
        Statistics() = default;
    };
    
    Statistics get_statistics() const;
    void reset_statistics();
    
    // Configuration
    void set_packet_buffer_size(size_t size);
    void set_oid_buffer_size(size_t size);
    void set_variable_binding_pool_size(size_t size);

private:
    SNMPMemoryPool();
    ~SNMPMemoryPool() = default;
    
    // Disable copy constructor and assignment operator
    SNMPMemoryPool(const SNMPMemoryPool&) = delete;
    SNMPMemoryPool& operator=(const SNMPMemoryPool&) = delete;
    
    // Memory pools
    std::unique_ptr<VariableMemoryPool> packet_buffer_pool_;
    std::unique_ptr<VariableMemoryPool> oid_buffer_pool_;
    std::unique_ptr<MemoryPool<64, 1000>> variable_binding_pool_;
    
    // Configuration
    size_t packet_buffer_size_;
    size_t oid_buffer_size_;
    size_t variable_binding_pool_size_;
};

// Utility functions
std::string memory_pool_statistics_to_string(const SNMPMemoryPool::Statistics& stats);
std::string variable_memory_pool_statistics_to_string(const VariableMemoryPool::Statistics& stats);

} // namespace simple_snmpd
