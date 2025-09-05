cmake_minimum_required(VERSION 3.16)
# Get system architecture for package naming
execute_process(COMMAND uname -m OUTPUT_VARIABLE SYSTEM_ARCH OUTPUT_STRIP_TRAILING_WHITESPACE)
message(STATUS "System architecture: ${SYSTEM_ARCH}")

project(simple-snmpd-${SYSTEM_ARCH} VERSION 0.1.0 LANGUAGES CXX)

# Set C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Platform detection
if(APPLE)
    set(CMAKE_OSX_DEPLOYMENT_TARGET "12.0" CACHE STRING "Minimum macOS deployment version" FORCE)
    # Allow command line override of architectures
    if(NOT DEFINED CMAKE_OSX_ARCHITECTURES)
        set(CMAKE_OSX_ARCHITECTURES "x86_64" CACHE STRING "Build architectures for macOS" FORCE)
    endif()
    set(PLATFORM_MACOS TRUE)
    message(STATUS "Building for macOS (Monterey 12.0+) with architectures: ${CMAKE_OSX_ARCHITECTURES}")
elseif(UNIX AND NOT APPLE)
    set(PLATFORM_LINUX TRUE)
    message(STATUS "Building for Linux")
elseif(WIN32)
    set(PLATFORM_WINDOWS TRUE)
    message(STATUS "Building for Windows")

    # Windows-specific settings
    set(CMAKE_WINDOWS_EXPORT_ALL_SYMBOLS ON)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /utf-8")

    # Set Windows SDK version if available
    if(DEFINED ENV{WINDOWS_SDK_VERSION})
        set(CMAKE_SYSTEM_VERSION $ENV{WINDOWS_SDK_VERSION})
    endif()
endif()

# Build options
option(BUILD_SHARED_LIBS "Build shared libraries" ON)
option(BUILD_TESTS "Build tests" ON)
option(BUILD_EXAMPLES "Build examples" OFF)
option(ENABLE_LOGGING "Enable logging" ON)
option(ENABLE_IPV6 "Enable IPv6 support" ON)
option(USE_SYSTEM_LIBS "Use system libraries instead of Homebrew" OFF)

# Set output directories
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)

# Find required packages
find_package(PkgConfig REQUIRED)
find_package(OpenSSL REQUIRED)

# Platform-specific library handling
if(PLATFORM_MACOS)
    # macOS specific libraries
    find_library(SECURITY_FRAMEWORK Security)
    find_library(CORE_FOUNDATION_FRAMEWORK CoreFoundation)
    find_library(SYSTEM_CONFIGURATION_FRAMEWORK SystemConfiguration)

    # macOS doesn't need separate socket or rt libraries
    set(PLATFORM_LIBRARIES
        ${SECURITY_FRAMEWORK}
        ${CORE_FOUNDATION_FRAMEWORK}
        ${SYSTEM_CONFIGURATION_FRAMEWORK}
    )
elseif(PLATFORM_LINUX)
    # Linux specific libraries
    find_library(RT_LIBRARY rt)
    set(PLATFORM_LIBRARIES ${RT_LIBRARY})
elseif(PLATFORM_WINDOWS)
    # Windows specific libraries
    set(PLATFORM_LIBRARIES ws2_32 iphlpapi)
endif()

# Include directories
include_directories(${CMAKE_SOURCE_DIR}/include)

# Source files
set(SOURCES
    src/main.cpp
    src/core/snmp_server.cpp
    src/core/snmp_connection.cpp
    src/core/snmp_packet.cpp
    src/core/snmp_config.cpp
    src/core/snmp_mib.cpp
    src/core/snmp_security.cpp
    src/core/snmp_v3_usm.cpp
    src/core/snmp_v3_vacm.cpp
    src/core/snmp_v3_packet.cpp
    src/core/thread_pool.cpp
    src/core/memory_pool.cpp
    src/core/prometheus_metrics.cpp
    src/core/health_check.cpp
    src/core/logger.cpp
    src/core/error_handler.cpp
)

# Core library source files (without main.cpp)
set(CORE_SOURCES
    src/core/snmp_server.cpp
    src/core/snmp_connection.cpp
    src/core/snmp_packet.cpp
    src/core/snmp_config.cpp
    src/core/snmp_mib.cpp
    src/core/snmp_security.cpp
    src/core/snmp_v3_usm.cpp
    src/core/snmp_v3_vacm.cpp
    src/core/snmp_v3_packet.cpp
    src/core/thread_pool.cpp
    src/core/memory_pool.cpp
    src/core/prometheus_metrics.cpp
    src/core/health_check.cpp
    src/core/logger.cpp
    src/core/platform.cpp
    src/core/error_handler.cpp
)

# Header files
set(HEADERS
    include/simple_snmpd/snmp_server.hpp
    include/simple_snmpd/snmp_connection.hpp
    include/simple_snmpd/snmp_packet.hpp
    include/simple_snmpd/snmp_config.hpp
    include/simple_snmpd/snmp_mib.hpp
    include/simple_snmpd/snmp_security.hpp
    include/simple_snmpd/snmp_v3_usm.hpp
    include/simple_snmpd/snmp_v3_vacm.hpp
    include/simple_snmpd/snmp_v3_packet.hpp
    include/simple_snmpd/thread_pool.hpp
    include/simple_snmpd/memory_pool.hpp
    include/simple_snmpd/prometheus_metrics.hpp
    include/simple_snmpd/health_check.hpp
    include/simple_snmpd/logger.hpp
    include/simple_snmpd/platform.hpp
    include/simple_snmpd/error_handler.hpp
)

# Create core library
add_library(simple-snmpd-core STATIC ${CORE_SOURCES} ${HEADERS})

# Link libraries for core library
target_link_libraries(simple-snmpd-core ${PLATFORM_LIBRARIES} OpenSSL::SSL OpenSSL::Crypto)

# Set properties for core library
set_target_properties(simple-snmpd-core PROPERTIES
    OUTPUT_NAME "simple-snmpd-core"
    LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib"
    ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib"
)

# Create executable
add_executable(simple-snmpd src/main.cpp)

# Link executable against core library
target_link_libraries(simple-snmpd simple-snmpd-core)

# Set properties
set_target_properties(simple-snmpd PROPERTIES
    OUTPUT_NAME "simple-snmpd"
    RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin"
)

# Install rules
install(TARGETS simple-snmpd
    RUNTIME DESTINATION bin
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib
)

# Install configuration files
install(DIRECTORY config/ DESTINATION etc/simple-snmpd
    FILES_MATCHING PATTERN "*.conf" PATTERN "*.example"
)

# Install documentation
install(DIRECTORY docs/ DESTINATION share/doc/simple-snmpd)

# Tests
if(BUILD_TESTS)
    enable_testing()
    
    # Test executables
    add_executable(test_snmp_packet src/tests/test_snmp_packet.cpp)
    target_link_libraries(test_snmp_packet simple-snmpd-core)
    
    add_executable(test_snmp_mib src/tests/test_snmp_mib.cpp)
    target_link_libraries(test_snmp_mib simple-snmpd-core)
    
    add_executable(test_snmp_security src/tests/test_snmp_security.cpp)
    target_link_libraries(test_snmp_security simple-snmpd-core)
    
    # Add tests to CTest
    add_test(NAME snmp_packet_tests COMMAND test_snmp_packet)
    add_test(NAME snmp_mib_tests COMMAND test_snmp_mib)
    add_test(NAME snmp_security_tests COMMAND test_snmp_security)
    
    # Set test properties
    set_tests_properties(snmp_packet_tests PROPERTIES TIMEOUT 30)
    set_tests_properties(snmp_mib_tests PROPERTIES TIMEOUT 30)
    set_tests_properties(snmp_security_tests PROPERTIES TIMEOUT 30)
endif()

# Examples
if(BUILD_EXAMPLES)
    add_subdirectory(src/examples)
endif()

# Package configuration
include(CMakePackageConfigHelpers)
write_basic_package_version_file(
    "${CMAKE_CURRENT_BINARY_DIR}/simple-snmpd-config-version.cmake"
    VERSION ${PROJECT_VERSION}
    COMPATIBILITY AnyNewerVersion
)

configure_file(
    "${CMAKE_CURRENT_SOURCE_DIR}/cmake/simple-snmpd-config.cmake.in"
    "${CMAKE_CURRENT_BINARY_DIR}/simple-snmpd-config.cmake"
    @ONLY
)

install(FILES
    "${CMAKE_CURRENT_BINARY_DIR}/simple-snmpd-config.cmake"
    "${CMAKE_CURRENT_BINARY_DIR}/simple-snmpd-config-version.cmake"
    DESTINATION lib/cmake/simple-snmpd
)

# CPack configuration for macOS packaging
if(PLATFORM_MACOS)
    set(CPACK_GENERATOR "DragNDrop;productbuild")
    set(CPACK_PACKAGE_NAME "simple-snmpd")
    set(CPACK_PACKAGE_VERSION "${PROJECT_VERSION}")
    set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "Simple SNMP Daemon for macOS")
    set(CPACK_PACKAGE_VENDOR "simple-snmpd")
    set(CPACK_PACKAGE_CONTACT "SimpleDaemons")
    set(CPACK_PACKAGE_FILE_NAME "simple-snmpd-${PROJECT_VERSION}-macOS-${SYSTEM_ARCH}")
    set(CPACK_DMG_VOLUME_NAME "simple-snmpd-${PROJECT_VERSION}-macOS-${SYSTEM_ARCH}")
    set(CPACK_DMG_FORMAT "UDZO")

    # PKG configuration
    set(CPACK_PRODUCTBUILD_PACKAGE_NAME "simple-snmpd-${PROJECT_VERSION}-macOS-${SYSTEM_ARCH}")
    set(CPACK_PRODUCTBUILD_PACKAGE_VERSION "${PROJECT_VERSION}")
    set(CPACK_PRODUCTBUILD_PACKAGE_DESCRIPTION "Simple SNMP Daemon for macOS - ${SYSTEM_ARCH}")
    set(CPACK_PRODUCTBUILD_PACKAGE_VENDOR "simple-snmpd")
    set(CPACK_PRODUCTBUILD_PACKAGE_CONTACT "SimpleDaemons")

    include(CPack)
endif()
