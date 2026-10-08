@echo off
setlocal EnableDelayedExpansion

echo ===========================================
echo       Uninstalling Windows Proxy Guard
echo ===========================================
echo.

set "TARGET_DIR=%LOCALAPPDATA%\ProxyGuard"
set "STARTUP_LAUNCHER=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\ProxyGuard.vbs"

:: 1. Terminate only the specific background watcher process
echo [*] Stopping background watcher process...
powershell -Command "Get-CimInstance Win32_Process | Where-Object { $_.CommandLine -like '*watch_proxy.ps1*' } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force }" >nul 2>&1

:: 2. Remove the startup entry
echo [*] Removing startup launcher...
if exist "%STARTUP_LAUNCHER%" (
    del /f /q "%STARTUP_LAUNCHER%" >nul 2>&1
    echo     - Removed from Startup folder.
) else (
    echo     - Startup entry not found or already removed.
)

:: 3. Delete the ProxyGuard directory and its contents
echo [*] Deleting installed files...
if exist "%TARGET_DIR%" (
    rmdir /s /q "%TARGET_DIR%" >nul 2>&1
    echo     - Deleted %TARGET_DIR%
) else (
    echo     - Directory not found or already deleted.
)

echo.
echo ===========================================
echo  Proxy Guard successfully uninstalled!
echo ===========================================
echo.
pause
