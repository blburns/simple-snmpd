/*
 * src/core/platform.cpp
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

#include "simple_snmpd/platform.hpp"
#include <string>
#include <vector>

#ifdef _WIN32
#include <windows.h>
#include <iphlpapi.h>
#pragma comment(lib, "iphlpapi.lib")
#else
#include <unistd.h>
#include <sys/utsname.h>
#include <ifaddrs.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#endif

namespace simple_snmpd {

Platform::Platform() {
}

Platform::~Platform() {
}

std::string Platform::get_os_name() const {
#ifdef _WIN32
    return "Windows";
#elif __APPLE__
    return "macOS";
#elif __linux__
    return "Linux";
#elif __FreeBSD__
    return "FreeBSD";
#elif __OpenBSD__
    return "OpenBSD";
#elif __NetBSD__
    return "NetBSD";
#else
    return "Unknown";
#endif
}

std::string Platform::get_os_version() const {
#ifdef _WIN32
    OSVERSIONINFOEX osvi;
    ZeroMemory(&osvi, sizeof(OSVERSIONINFOEX));
    osvi.dwOSVersionInfoSize = sizeof(OSVERSIONINFOEX);
    
    if (GetVersionEx((OSVERSIONINFO*)&osvi)) {
        return std::to_string(osvi.dwMajorVersion) + "." + 
               std::to_string(osvi.dwMinorVersion) + "." + 
               std::to_string(osvi.dwBuildNumber);
    }
    return "Unknown";
#else
    struct utsname uts;
    if (uname(&uts) == 0) {
        return std::string(uts.release);
    }
    return "Unknown";
#endif
}

std::string Platform::get_architecture() const {
#ifdef _WIN32
    SYSTEM_INFO si;
    GetSystemInfo(&si);
    
    switch (si.wProcessorArchitecture) {
        case PROCESSOR_ARCHITECTURE_AMD64:
            return "x86_64";
        case PROCESSOR_ARCHITECTURE_ARM:
            return "ARM";
        case PROCESSOR_ARCHITECTURE_ARM64:
            return "ARM64";
        case PROCESSOR_ARCHITECTURE_IA64:
            return "IA64";
        case PROCESSOR_ARCHITECTURE_INTEL:
            return "x86";
        default:
            return "Unknown";
    }
#else
    struct utsname uts;
    if (uname(&uts) == 0) {
        return std::string(uts.machine);
    }
    return "Unknown";
#endif
}

std::string Platform::get_hostname() const {
#ifdef _WIN32
    char hostname[256];
    DWORD size = sizeof(hostname);
    if (GetComputerNameA(hostname, &size)) {
        return std::string(hostname);
    }
    return "Unknown";
#else
    char hostname[256];
    if (gethostname(hostname, sizeof(hostname)) == 0) {
        return std::string(hostname);
    }
    return "Unknown";
#endif
}

std::vector<std::string> Platform::get_network_interfaces() const {
    std::vector<std::string> interfaces;
    
#ifdef _WIN32
    // Windows implementation
    ULONG buffer_size = 0;
    GetAdaptersAddresses(AF_UNSPEC, 0, nullptr, nullptr, &buffer_size);
    
    if (buffer_size > 0) {
        std::vector<BYTE> buffer(buffer_size);
        PIP_ADAPTER_ADDRESSES adapters = reinterpret_cast<PIP_ADAPTER_ADDRESSES>(buffer.data());
        
        if (GetAdaptersAddresses(AF_UNSPEC, 0, nullptr, adapters, &buffer_size) == ERROR_SUCCESS) {
            for (PIP_ADAPTER_ADDRESSES adapter = adapters; adapter != nullptr; adapter = adapter->Next) {
                if (adapter->OperStatus == IfOperStatusUp) {
                    interfaces.push_back(std::string(adapter->FriendlyName));
                }
            }
        }
    }
#else
    // Unix implementation
    struct ifaddrs* ifaddr;
    if (getifaddrs(&ifaddr) == 0) {
        for (struct ifaddrs* ifa = ifaddr; ifa != nullptr; ifa = ifa->ifa_next) {
            if (ifa->ifa_addr != nullptr && ifa->ifa_addr->sa_family == AF_INET) {
                interfaces.push_back(std::string(ifa->ifa_name));
            }
        }
        freeifaddrs(ifaddr);
    }
#endif
    
    return interfaces;
}

uint64_t Platform::get_uptime_seconds() const {
#ifdef _WIN32
    return GetTickCount64() / 1000;
#else
    struct sysinfo info;
    if (sysinfo(&info) == 0) {
        return info.uptime;
    }
    return 0;
#endif
}

uint32_t Platform::get_cpu_count() const {
#ifdef _WIN32
    SYSTEM_INFO si;
    GetSystemInfo(&si);
    return si.dwNumberOfProcessors;
#else
    return sysconf(_SC_NPROCESSORS_ONLN);
#endif
}

uint64_t Platform::get_total_memory() const {
#ifdef _WIN32
    MEMORYSTATUSEX mem_status;
    mem_status.dwLength = sizeof(mem_status);
    if (GlobalMemoryStatusEx(&mem_status)) {
        return mem_status.ullTotalPhys;
    }
    return 0;
#else
    long pages = sysconf(_SC_PHYS_PAGES);
    long page_size = sysconf(_SC_PAGE_SIZE);
    if (pages > 0 && page_size > 0) {
        return static_cast<uint64_t>(pages) * static_cast<uint64_t>(page_size);
    }
    return 0;
#endif
}

uint64_t Platform::get_free_memory() const {
#ifdef _WIN32
    MEMORYSTATUSEX mem_status;
    mem_status.dwLength = sizeof(mem_status);
    if (GlobalMemoryStatusEx(&mem_status)) {
        return mem_status.ullAvailPhys;
    }
    return 0;
#else
    long pages = sysconf(_SC_AVPHYS_PAGES);
    long page_size = sysconf(_SC_PAGE_SIZE);
    if (pages > 0 && page_size > 0) {
        return static_cast<uint64_t>(pages) * static_cast<uint64_t>(page_size);
    }
    return 0;
#endif
}

// Global platform instance
Platform& Platform::get_instance() {
    static Platform instance;
    return instance;
}

} // namespace simple_snmpd
