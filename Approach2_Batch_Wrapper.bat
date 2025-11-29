################################
# APPROACH 2: BATCH WRAPPER LAUNCHER
################################
# File: launcher.bat
# Simple batch wrapper that elevates and runs PowerShell installer
# No compilation needed - works immediately

@echo off
REM ========================================
REM  MyApp Installation Launcher
REM  Batch Wrapper with PowerShell Integration
REM  Handles: Elevation, logging, error handling
REM ========================================

setlocal enabledelayedexpansion

REM Color codes
set "GREEN=[92m"
set "RED=[91m"
set "YELLOW=[93m"
set "NC=[0m"

REM Configuration
set "AppName=MyApp"
set "Version=1.0.0.0"
set "Company=MyCompany"
set "LogFile=%TEMP%\%AppName%_install.log"

REM ========================================
REM  ADMIN CHECK AND ELEVATION
REM ========================================

REM Check for administrator privileges
openfiles >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting administrator privileges...
    echo [%date% %time%] - Requesting elevation >> "%LogFile%"
    
    REM Re-run script with elevation
    powershell -Command "Start-Process cmd.exe -ArgumentList '/c %~f0' -Verb RunAs -Wait"
    
    exit /b %errorlevel%
)

REM Clear screen
cls

REM We have admin privileges - continue
echo.
echo ========================================
echo  %AppName% Installation
echo  Version: %Version%
echo ========================================
echo.

echo [%date% %time%] - Installation started >> "%LogFile%"

REM ========================================
REM  SYSTEM REQUIREMENTS CHECK
REM ========================================

REM Check Windows Version (Windows 10+)
for /f "tokens=3" %%i in ('reg query HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion /v CurrentVersion 2^>nul') do set "WINVER=%%i"

REM More reliable: Check ProductName for Windows 10/11
for /f "tokens=3*" %%i in ('reg query HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion /v ProductName 2^>nul') do set "OSNAME=%%i %%j"

echo Checking system requirements...
echo  OS: %OSNAME%
echo  [%date% %time%] - OS: %OSNAME% >> "%LogFile%"

REM Check minimum RAM using WMI
for /f "tokens=2 delims==" %%i in ('wmic computersystem get totalphysicalmemory /value 2^>nul') do set "TOTALMEM=%%i"
set /a "MEMGB=%TOTALMEM% / 1024 / 1024 / 1024"
echo  RAM: %MEMGB%GB

if %MEMGB% lss 4 (
    echo %RED%ERROR: Minimum 4GB RAM required (Current: %MEMGB%GB)%NC%
    echo [%date% %time%] - ERROR: Insufficient RAM (%MEMGB%GB) >> "%LogFile%"
    timeout /t 5
    exit /b 1
)

REM Check disk space (C: drive)
for /f "tokens=3" %%i in ('dir C:\ ^| find "bytes free"') do set "FREESPACE=%%i"
set /a "FREEGB=%FREESPACE% / 1024 / 1024 / 1024"
echo  Disk Space: %FREEGB%GB free

if %FREEGB% lss 2 (
    echo %RED%ERROR: Minimum 2GB free disk space required%NC%
    echo [%date% %time%] - ERROR: Insufficient disk space (%FREEGB%GB) >> "%LogFile%"
    timeout /t 5
    exit /b 1
)

echo [%date% %time%] - System requirements verified ✓ >> "%LogFile%"
echo.

REM ========================================
REM  EMBEDDED POWERSHELL INSTALLATION
REM ========================================

REM Execute PowerShell script embedded below
echo Installing application...
echo [%date% %time%] - Starting installation >> "%LogFile%"

powershell -NoProfile -ExecutionPolicy Bypass -Command "& {%~f0}"

set "PSExitCode=!errorlevel!"

if !PSExitCode! equ 0 (
    echo.
    echo Installation completed successfully!
    echo [%date% %time%] - Installation completed successfully >> "%LogFile%"
) else (
    echo.
    echo Installation failed with error code: !PSExitCode!
    echo [%date% %time%] - Installation failed with error code: !PSExitCode! >> "%LogFile%"
)

echo.
echo Log file: %LogFile%
timeout /t 3
exit /b !PSExitCode!

REM ========================================
REM  POWERSHELL SECTION BELOW
REM ========================================

#>
# PowerShell installation script starts here
# Everything below executes in PowerShell context

param(
    [string]$InstallPath = "$env:ProgramFiles\MyApp",
    [string]$Company = "MyCompany"
)

$AppName = "MyApp"
$Version = "1.0.0.0"
$LogFile = "$env:TEMP\MyApp_install.log"

# ========================================
# HELPER FUNCTIONS
# ========================================

function Log-Message {
    param(
        [string]$Message,
        [string]$Level = "INFO",
        [switch]$NoHost
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    Add-Content -Path $LogFile -Value $logEntry -Force
    
    if (-not $NoHost) {
        switch ($Level) {
            "SUCCESS" { Write-Host "✓ $Message" -ForegroundColor Green }
            "ERROR" { Write-Host "✗ $Message" -ForegroundColor Red }
            "WARN" { Write-Host "⚠ $Message" -ForegroundColor Yellow }
            default { Write-Host "ℹ $Message" -ForegroundColor Cyan }
        }
    }
}

function Test-Administrator {
    $current = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
    return $current.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# ========================================
# INSTALLATION STEPS
# ========================================

function Configure-Environment {
    Log-Message "Configuring environment..."
    
    # Create installation directory
    if (-not (Test-Path $InstallPath)) {
        try {
            New-Item -ItemType Directory -Path $InstallPath -Force | Out-Null
            Log-Message "Created installation directory: $InstallPath" "SUCCESS"
        } catch {
            Log-Message "Failed to create directory: $_" "ERROR"
            return $false
        }
    }
    
    # Create registry entries
    try {
        $regPath = "HKLM:\Software\$Company\$AppName"
        if (-not (Test-Path "HKLM:\Software\$Company")) {
            New-Item -Path "HKLM:\Software\$Company" -Force | Out-Null
        }
        
        New-Item -Path $regPath -Force | Out-Null
        New-ItemProperty -Path $regPath -Name "InstallPath" -Value $InstallPath -PropertyType String -Force | Out-Null
        New-ItemProperty -Path $regPath -Name "Version" -Value $Version -PropertyType String -Force | Out-Null
        New-ItemProperty -Path $regPath -Name "InstallDate" -Value (Get-Date -Format "yyyyMMdd") -PropertyType String -Force | Out-Null
        
        Log-Message "Registry entries created" "SUCCESS"
    } catch {
        Log-Message "Registry configuration failed: $_" "WARN"
        return $false
    }
    
    return $true
}

function Install-Application {
    Log-Message "Installing application files..."
    
    try {
        # Create placeholder application files
        @"
# $AppName Application
Write-Host "MyApp is running..."
Write-Host "Version: $Version"
"@ | Set-Content "$InstallPath\app.ps1" -Force
        
        Log-Message "Application files installed" "SUCCESS"
        return $true
    } catch {
        Log-Message "Failed to install files: $_" "ERROR"
        return $false
    }
}

function Create-Shortcuts {
    Log-Message "Creating shortcuts..."
    
    try {
        $shell = New-Object -ComObject WScript.Shell
        
        # Start Menu
        $startMenuPath = "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\$AppName"
        New-Item -ItemType Directory -Path $startMenuPath -Force | Out-Null
        
        $shortcut = $shell.CreateShortcut("$startMenuPath\$AppName.lnk")
        $shortcut.TargetPath = "$InstallPath\app.ps1"
        $shortcut.WorkingDirectory = $InstallPath
        $shortcut.Description = "$AppName v$Version"
        $shortcut.Save()
        
        Log-Message "Shortcuts created" "SUCCESS"
        return $true
    } catch {
        Log-Message "Failed to create shortcuts: $_" "WARN"
        return $true  # Don't fail for this
    }
}

function Create-UninstallScript {
    Log-Message "Creating uninstall script..."
    
    $uninstallScript = @"
#Requires -RunAsAdministrator
Write-Host "Uninstalling $AppName..."

`$appPath = "`$env:ProgramFiles\$AppName"
`$regPath = "HKLM:\Software\$Company\$AppName"

if (Test-Path `$appPath) {
    Remove-Item `$appPath -Recurse -Force
    Write-Host "✓ Application files removed"
}

if (Test-Path `$regPath) {
    Remove-Item `$regPath -Recurse -Force
    Write-Host "✓ Registry entries removed"
}

Write-Host "✓ Uninstallation complete"
"@
    
    try {
        Set-Content -Path "$InstallPath\Uninstall.ps1" -Value $uninstallScript -Force
        Log-Message "Uninstall script created" "SUCCESS"
    } catch {
        Log-Message "Failed to create uninstall script: $_" "WARN"
    }
}

# ========================================
# MAIN EXECUTION
# ========================================

try {
    Log-Message "========================================" "INFO" -NoHost
    Log-Message "$AppName Installation" "INFO" -NoHost
    Log-Message "Version: $Version" "INFO" -NoHost
    Log-Message "========================================" "INFO" -NoHost
    
    Write-Host ""
    
    # Check admin
    if (-not (Test-Administrator)) {
        Log-Message "Not running as administrator!" "ERROR"
        Write-Host "This installation requires administrator privileges."
        exit 1
    }
    
    # Run installation steps
    if (-not (Configure-Environment)) {
        exit 1
    }
    
    if (-not (Install-Application)) {
        exit 1
    }
    
    Create-Shortcuts
    Create-UninstallScript
    
    Write-Host ""
    Log-Message "========================================" "INFO" -NoHost
    Log-Message "Installation Completed Successfully!" "SUCCESS"
    Log-Message "Installed to: $InstallPath" "INFO" -NoHost
    Log-Message "========================================" "INFO" -NoHost
    Write-Host ""
    Write-Host "Press any key to continue..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    
} catch {
    Log-Message "Installation failed: $_" "ERROR"
    exit 1
}
