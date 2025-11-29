@echo off
REM Video Pipeline - Windows Batch Launcher
REM This batch file launches the PowerShell run script

setlocal enabledelayedexpansion

REM Get script directory
set SCRIPT_DIR=%~dp0

REM Check if PowerShell is available
where powershell >nul 2>&1
if errorlevel 1 (
    echo ERROR: PowerShell is not installed or not in PATH
    pause
    exit /b 1
)

REM Launch PowerShell run script with any arguments
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%run.ps1" %*

endlocal
