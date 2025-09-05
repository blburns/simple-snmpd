/*
 * Simple SNMP Daemon Windows Service Wrapper
 * Copyright 2024 SimpleDaemons
 * Licensed under Apache 2.0
 */

#include <windows.h>
#include <winsvc.h>
#include <iostream>
#include <string>
#include <thread>
#include <chrono>
#include <filesystem>

// Service configuration
#define SERVICE_NAME L"SimpleSnmpd"
#define SERVICE_DISPLAY_NAME L"Simple SNMP Daemon"
#define SERVICE_DESCRIPTION L"Provides SNMP monitoring services for network devices"

// Global variables
SERVICE_STATUS g_ServiceStatus;
SERVICE_STATUS_HANDLE g_StatusHandle;
HANDLE g_ServiceStopEvent = INVALID_HANDLE_VALUE;
PROCESS_INFORMATION g_ProcessInfo = {0};

// Forward declarations
void WINAPI ServiceMain(DWORD argc, LPTSTR* argv);
void WINAPI ServiceCtrlHandler(DWORD ctrl);
DWORD WINAPI ServiceWorkerThread(LPVOID lpParam);
bool StartSNMPDaemon();
void StopSNMPDaemon();
void LogEvent(const std::wstring& message, WORD eventType = EVENTLOG_INFORMATION_TYPE);

// Service entry point
int wmain(int argc, wchar_t* argv[]) {
    // Check if running as service or console
    if (argc > 1 && wcscmp(argv[1], L"--console") == 0) {
        // Console mode
        std::wcout << L"Simple SNMP Daemon - Console Mode" << std::endl;
        std::wcout << L"Press Ctrl+C to stop..." << std::endl;

        if (StartSNMPDaemon()) {
            // Wait for Ctrl+C
            SetConsoleCtrlHandler([](DWORD ctrlType) -> BOOL {
                if (ctrlType == CTRL_C_EVENT) {
                    StopSNMPDaemon();
                    return TRUE;
                }
                return FALSE;
            }, TRUE);

            // Wait for process to exit
            WaitForSingleObject(g_ProcessInfo.hProcess, INFINITE);
        }

        return 0;
    }

    // Service mode
    SERVICE_TABLE_ENTRY serviceTable[] = {
        { SERVICE_NAME, ServiceMain },
        { NULL, NULL }
    };

    if (!StartServiceCtrlDispatcher(serviceTable)) {
        LogEvent(L"StartServiceCtrlDispatcher failed: " + std::to_wstring(GetLastError()), EVENTLOG_ERROR_TYPE);
        return 1;
    }

    return 0;
}

// Service main function
void WINAPI ServiceMain(DWORD argc, LPTSTR* argv) {
    g_StatusHandle = RegisterServiceCtrlHandler(SERVICE_NAME, ServiceCtrlHandler);
    if (!g_StatusHandle) {
        LogEvent(L"RegisterServiceCtrlHandler failed: " + std::to_wstring(GetLastError()), EVENTLOG_ERROR_TYPE);
        return;
    }

    // Initialize service status
    g_ServiceStatus.dwServiceType = SERVICE_WIN32_OWN_PROCESS;
    g_ServiceStatus.dwServiceSpecificExitCode = 0;

    // Report initial status
    g_ServiceStatus.dwCurrentState = SERVICE_START_PENDING;
    g_ServiceStatus.dwWin32ExitCode = 0;
    g_ServiceStatus.dwCheckPoint = 0;
    g_ServiceStatus.dwWaitHint = 3000;
    SetServiceStatus(g_StatusHandle, &g_ServiceStatus);

    // Create stop event
    g_ServiceStopEvent = CreateEvent(NULL, TRUE, FALSE, NULL);
    if (g_ServiceStopEvent == NULL) {
        LogEvent(L"CreateEvent failed: " + std::to_wstring(GetLastError()), EVENTLOG_ERROR_TYPE);
        g_ServiceStatus.dwCurrentState = SERVICE_STOPPED;
        g_ServiceStatus.dwWin32ExitCode = GetLastError();
        SetServiceStatus(g_StatusHandle, &g_ServiceStatus);
        return;
    }

    // Start worker thread
    HANDLE hThread = CreateThread(NULL, 0, ServiceWorkerThread, NULL, 0, NULL);
    if (hThread == NULL) {
        LogEvent(L"CreateThread failed: " + std::to_wstring(GetLastError()), EVENTLOG_ERROR_TYPE);
        CloseHandle(g_ServiceStopEvent);
        g_ServiceStatus.dwCurrentState = SERVICE_STOPPED;
        g_ServiceStatus.dwWin32ExitCode = GetLastError();
        SetServiceStatus(g_StatusHandle, &g_ServiceStatus);
        return;
    }

    // Report running status
    g_ServiceStatus.dwCurrentState = SERVICE_RUNNING;
    g_ServiceStatus.dwCheckPoint = 0;
    g_ServiceStatus.dwWaitHint = 0;
    SetServiceStatus(g_StatusHandle, &g_ServiceStatus);

    LogEvent(L"Simple SNMP Daemon service started successfully");

    // Wait for stop event
    WaitForSingleObject(g_ServiceStopEvent, INFINITE);

    // Cleanup
    CloseHandle(hThread);
    CloseHandle(g_ServiceStopEvent);

    // Report stopped status
    g_ServiceStatus.dwCurrentState = SERVICE_STOPPED;
    g_ServiceStatus.dwWin32ExitCode = 0;
    SetServiceStatus(g_StatusHandle, &g_ServiceStatus);

    LogEvent(L"Simple SNMP Daemon service stopped");
}

// Service control handler
void WINAPI ServiceCtrlHandler(DWORD ctrl) {
    switch (ctrl) {
        case SERVICE_CONTROL_STOP:
            LogEvent(L"Service stop requested");
            g_ServiceStatus.dwCurrentState = SERVICE_STOP_PENDING;
            g_ServiceStatus.dwCheckPoint = 0;
            g_ServiceStatus.dwWaitHint = 5000;
            SetServiceStatus(g_StatusHandle, &g_ServiceStatus);

            StopSNMPDaemon();
            SetEvent(g_ServiceStopEvent);
            break;

        case SERVICE_CONTROL_PAUSE:
            LogEvent(L"Service pause requested");
            g_ServiceStatus.dwCurrentState = SERVICE_PAUSED;
            SetServiceStatus(g_StatusHandle, &g_ServiceStatus);
            break;

        case SERVICE_CONTROL_CONTINUE:
            LogEvent(L"Service continue requested");
            g_ServiceStatus.dwCurrentState = SERVICE_RUNNING;
            SetServiceStatus(g_StatusHandle, &g_ServiceStatus);
            break;

        case SERVICE_CONTROL_INTERROGATE:
            SetServiceStatus(g_StatusHandle, &g_ServiceStatus);
            break;

        case SERVICE_CONTROL_SHUTDOWN:
            LogEvent(L"System shutdown - stopping service");
            g_ServiceStatus.dwCurrentState = SERVICE_STOP_PENDING;
            SetServiceStatus(g_StatusHandle, &g_ServiceStatus);
            StopSNMPDaemon();
            SetEvent(g_ServiceStopEvent);
            break;

        default:
            break;
    }
}

// Service worker thread
DWORD WINAPI ServiceWorkerThread(LPVOID lpParam) {
    // Start SNMP daemon
    if (!StartSNMPDaemon()) {
        LogEvent(L"Failed to start SNMP daemon", EVENTLOG_ERROR_TYPE);
        g_ServiceStatus.dwCurrentState = SERVICE_STOPPED;
        g_ServiceStatus.dwWin32ExitCode = 1;
        SetServiceStatus(g_StatusHandle, &g_ServiceStatus);
        return 1;
    }

    // Monitor the daemon process
    while (WaitForSingleObject(g_ServiceStopEvent, 1000) == WAIT_TIMEOUT) {
        if (g_ProcessInfo.hProcess && WaitForSingleObject(g_ProcessInfo.hProcess, 0) == WAIT_OBJECT_0) {
            LogEvent(L"SNMP daemon process exited unexpectedly", EVENTLOG_ERROR_TYPE);
            break;
        }
    }

    return 0;
}

// Start SNMP daemon process
bool StartSNMPDaemon() {
    // Get the path to the SNMP daemon executable
    wchar_t exePath[MAX_PATH];
    GetModuleFileName(NULL, exePath, MAX_PATH);

    // Replace service wrapper with actual daemon
    std::wstring daemonPath = exePath;
    size_t pos = daemonPath.find(L"-service.exe");
    if (pos != std::wstring::npos) {
        daemonPath.replace(pos, 12, L".exe");
    } else {
        daemonPath = L"simple-snmpd.exe";
    }

    // Check if daemon exists
    if (!std::filesystem::exists(daemonPath)) {
        LogEvent(L"SNMP daemon executable not found: " + daemonPath, EVENTLOG_ERROR_TYPE);
        return false;
    }

    // Prepare command line
    std::wstring cmdLine = L"\"" + daemonPath + L"\" --service";

    // Create process
    STARTUPINFO startupInfo = {0};
    startupInfo.cb = sizeof(startupInfo);

    if (!CreateProcess(
        daemonPath.c_str(),
        &cmdLine[0],
        NULL,
        NULL,
        FALSE,
        CREATE_NO_WINDOW,
        NULL,
        NULL,
        &startupInfo,
        &g_ProcessInfo
    )) {
        LogEvent(L"Failed to create SNMP daemon process: " + std::to_wstring(GetLastError()), EVENTLOG_ERROR_TYPE);
        return false;
    }

    LogEvent(L"SNMP daemon process started with PID: " + std::to_wstring(g_ProcessInfo.dwProcessId));
    return true;
}

// Stop SNMP daemon process
void StopSNMPDaemon() {
    if (g_ProcessInfo.hProcess) {
        LogEvent(L"Stopping SNMP daemon process...");

        // Try graceful shutdown first
        if (TerminateProcess(g_ProcessInfo.hProcess, 0)) {
            // Wait for process to exit
            WaitForSingleObject(g_ProcessInfo.hProcess, 5000);
        }

        // Cleanup handles
        CloseHandle(g_ProcessInfo.hProcess);
        CloseHandle(g_ProcessInfo.hThread);

        g_ProcessInfo.hProcess = NULL;
        g_ProcessInfo.hThread = NULL;

        LogEvent(L"SNMP daemon process stopped");
    }
}

// Log event to Windows Event Log
void LogEvent(const std::wstring& message, WORD eventType) {
    HANDLE hEventSource = RegisterEventSource(NULL, SERVICE_NAME);
    if (hEventSource) {
        const wchar_t* strings[] = { message.c_str() };
        ReportEvent(hEventSource, eventType, 0, 0, NULL, 1, 0, strings, NULL);
        DeregisterEventSource(hEventSource);
    }
}
