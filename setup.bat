@echo off
setlocal EnableDelayedExpansion

echo ===========================================
echo       Setting up Windows Proxy Guard
echo ===========================================
echo.

:: 1. Force turn off proxy immediately right now
echo [*] Disabling proxy right now...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyEnable /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyServer /t REG_SZ /d "" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v AutoConfigURL /t REG_SZ /d "" /f >nul 2>&1

:: 2. Set up target directory in Local AppData
set "TARGET_DIR=%LOCALAPPDATA%\ProxyGuard"
if not exist "%TARGET_DIR%" mkdir "%TARGET_DIR%"

set "PS_SCRIPT=%TARGET_DIR%\watch_proxy.ps1"
set "VBS_SCRIPT=%TARGET_DIR%\run_silent.vbs"
set "STARTUP_FOLDER=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
set "STARTUP_LAUNCHER=%STARTUP_FOLDER%\ProxyGuard.vbs"

:: 3. Generate the updated watch_proxy.ps1
echo [*] Writing monitoring script...
(
echo $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"
echo.
echo # 1. Immediately disable proxy on script startup
echo Set-ItemProperty -Path $regPath -Name ProxyEnable -Value 0
echo Set-ItemProperty -Path $regPath -Name ProxyServer -Value ""
echo Set-ItemProperty -Path $regPath -Name AutoConfigURL -Value ""
echo.
echo # 2. Real-time loop to keep it disabled
echo while ($true^) {
echo     $props = Get-ItemProperty -Path $regPath
echo     if ($props.ProxyEnable -eq 1 -or $props.ProxyServer -ne "" -or $props.AutoConfigURL -ne ""^) {
echo         Set-ItemProperty -Path $regPath -Name ProxyEnable -Value 0
echo         Set-ItemProperty -Path $regPath -Name ProxyServer -Value ""
echo         Set-ItemProperty -Path $regPath -Name AutoConfigURL -Value ""
echo     }
echo     Start-Sleep -Seconds 2
echo }
) > "%PS_SCRIPT%"

:: 4. Generate the silent VBS launcher
echo [*] Writing silent background launcher...
(
echo Set WshShell = CreateObject^("WScript.Shell"^)
echo WshShell.Run "powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File """ ^& "%PS_SCRIPT%" ^& """", 0, False
) > "%VBS_SCRIPT%"

:: 5. Copy the launcher to the Startup folder
echo [*] Registering in Startup folder...
copy /y "%VBS_SCRIPT%" "%STARTUP_LAUNCHER%" >nul

:: 6. Launch it right now invisibly
echo [*] Launching background watcher...
wscript.exe "%STARTUP_LAUNCHER%"

echo.
echo ===========================================
echo  Done! Proxy is disabled and protected.
echo  The watcher will start automatically on boot.
echo ===========================================
echo.
pause