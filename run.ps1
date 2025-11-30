#Requires -Version 5.1
<#
.SYNOPSIS
    Video Pipeline - Main Entry Point & Launcher
    
.DESCRIPTION
    This script provides a unified entry point to launch and manage the video pipeline.
    Supports multiple interfaces: GUI, CLI menu, batch processing, and system validation.
    
.EXAMPLE
    .\run.ps1                          # Interactive menu
    .\run.ps1 -GUI                     # Launch WinForms GUI
    .\run.ps1 -Web                     # Launch web GUI
    .\run.ps1 -CLI                     # Launch CLI menu
    .\run.ps1 -Validate                # Validate system
    .\run.ps1 -Install                 # Run installer
    
.AUTHOR
    Video Pipeline Contributors
    
.VERSION
    1.0.0
#>

param(
    [switch]$GUI,
    [switch]$Web,
    [switch]$CLI,
    [switch]$Validate,
    [switch]$Install,
    [switch]$Uninstall,
    [switch]$Setup,
    [switch]$Help
)

$ErrorActionPreference = "Continue"
$scriptPath = Split-Path -Parent $PSCommandPath

# ============================================
# HELPER FUNCTIONS
# ============================================

function Write-Header {
    param([string]$Title)
    Clear-Host
    Write-Host "===============================================================" -ForegroundColor Cyan
    Write-Host "  $Title" -ForegroundColor Cyan
    Write-Host "===============================================================" -ForegroundColor Cyan
    Write-Host ""
}

function Write-Menu {
    Write-Host "VIDEO PIPELINE - MAIN MENU" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Launch Options:" -ForegroundColor Yellow
    Write-Host "  1. Desktop GUI (WinForms)      - Native Windows interface with file dialogs"
    Write-Host "  2. Web GUI (Browser)           - Modern responsive web interface"
    Write-Host "  3. CLI Menu (Interactive)      - Command-line interface with 14+ options"
    Write-Host ""
    Write-Host "System Management:" -ForegroundColor Yellow
    Write-Host "  4. Validate System             - Check prerequisites & system readiness"
    Write-Host "  5. Setup Environment           - Configure API keys & settings"
    Write-Host "  6. Install Pipeline            - Install to Program Files (admin)"
    Write-Host "  7. Uninstall Pipeline          - Remove installed files (admin)"
    Write-Host ""
    Write-Host "Utilities:" -ForegroundColor Yellow
    Write-Host "  8. View Documentation          - Open README in browser"
    Write-Host "  9. Open Folder                 - Explorer to project directory"
    Write-Host " 10. Open Terminal              - PowerShell in project directory"
    Write-Host ""
    Write-Host "  0. Exit"
    Write-Host ""
}

function Test-Prerequisites {
    Write-Header "System Validation"
    Write-Host "Checking prerequisites..." -ForegroundColor Yellow
    Write-Host ""
    
    $passed = 0
    $failed = 0
    
    # Check PowerShell version
    if ($PSVersionTable.PSVersion.Major -ge 5) {
        Write-Host "✓ PowerShell: $($PSVersionTable.PSVersion.Major).$($PSVersionTable.PSVersion.Minor)" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "✗ PowerShell 5.1+ required" -ForegroundColor Red
        $failed++
    }
    
    # Check FFmpeg
    if (Get-Command ffmpeg -ErrorAction SilentlyContinue) {
        $ffVersion = ffmpeg -version 2>&1 | Select-Object -First 1
        Write-Host "✓ FFmpeg installed" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "✗ FFmpeg not found (install: winget install Gyan.FFmpeg)" -ForegroundColor Red
        $failed++
    }
    
    # Check Python
    if (Get-Command python -ErrorAction SilentlyContinue) {
        $pyVersion = python --version 2>&1
        Write-Host "✓ $pyVersion" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "✗ Python 3 not found (install: winget install Python.Python.3.12)" -ForegroundColor Red
        $failed++
    }
    
    # Check Git
    if (Get-Command git -ErrorAction SilentlyContinue) {
        Write-Host "✓ Git installed" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "⚠ Git not found (optional, for version control)" -ForegroundColor Yellow
    }
    
    # Check API keys
    Write-Host ""
    Write-Host "API Configuration:" -ForegroundColor Yellow
    if ([System.Environment]::GetEnvironmentVariable("XAI_API_KEY")) {
        Write-Host "✓ Grok API Key: configured" -ForegroundColor Green
    } else {
        Write-Host "⚠ Grok API Key: not set (optional)" -ForegroundColor Yellow
    }
    
    if ([System.Environment]::GetEnvironmentVariable("MIDJOURNEY_API_KEY")) {
        Write-Host "✓ Midjourney API Key: configured" -ForegroundColor Green
    } else {
        Write-Host "⚠ Midjourney API Key: not set (optional)" -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "Summary: $passed passed, $failed failed" -ForegroundColor $(if ($failed -eq 0) { "Green" } else { "Red" })
    Write-Host ""
    Read-Host "Press Enter to continue"
}

function Show-Help {
    Write-Header "VIDEO PIPELINE - HELP"
    Write-Host "Usage: .\run.ps1 [options]" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Options:" -ForegroundColor Yellow
    Write-Host "  -GUI          Launch WinForms desktop GUI"
    Write-Host "  -Web          Launch web browser interface"
    Write-Host "  -CLI          Launch interactive CLI menu"
    Write-Host "  -Validate     Validate system prerequisites"
    Write-Host "  -Install      Run installer (requires admin)"
    Write-Host "  -Uninstall    Run uninstaller (requires admin)"
    Write-Host "  -Setup        Configure environment variables"
    Write-Host "  -Help         Show this help message"
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor Yellow
    Write-Host "  .\run.ps1              # Interactive menu"
    Write-Host "  .\run.ps1 -GUI         # Open desktop GUI"
    Write-Host "  .\run.ps1 -Validate    # Check system"
    Write-Host "  .\run.ps1 -Web         # Open in browser"
    Write-Host ""
    Read-Host "Press Enter to continue"
}

function Launch-GUI {
    Write-Header "Launching Desktop GUI"
    Write-Host "Starting WinForms interface..." -ForegroundColor Green
    Write-Host ""
    
    $guiScript = Join-Path $scriptPath "pipeline-gui.ps1"
    if (Test-Path $guiScript) {
        & $guiScript
    } else {
        Write-Host "ERROR: GUI script not found: $guiScript" -ForegroundColor Red
        Read-Host "Press Enter to continue"
    }
}

function Launch-Web {
    Write-Header "Launching Web GUI"
    Write-Host "Starting web server on http://localhost:8000" -ForegroundColor Green
    Write-Host "Opening in default browser..." -ForegroundColor Green
    Write-Host ""
    Write-Host "Press Ctrl+C to stop the server" -ForegroundColor Yellow
    Write-Host ""
    
    $webScript = Join-Path $scriptPath "start-gui.ps1"
    if (Test-Path $webScript) {
        & $webScript -GUI web
    } else {
        Write-Host "ERROR: Web GUI script not found: $webScript" -ForegroundColor Red
        Read-Host "Press Enter to continue"
    }
}

function Launch-CLI {
    Write-Header "Launching CLI Menu"
    Write-Host "Starting interactive menu..." -ForegroundColor Green
    Write-Host ""
    
    $cliScript = Join-Path $scriptPath "cli-menu.ps1"
    if (Test-Path $cliScript) {
        & $cliScript
    } else {
        Write-Host "ERROR: CLI menu script not found: $cliScript" -ForegroundColor Red
        Read-Host "Press Enter to continue"
    }
}

function Setup-Environment {
    Write-Header "Environment Setup"
    Write-Host "Configure API Keys and Settings" -ForegroundColor Yellow
    Write-Host ""
    
    $setupScript = Join-Path $scriptPath "setup-environment.ps1"
    if (Test-Path $setupScript) {
        & $setupScript
    } else {
        Write-Host "ERROR: Setup script not found: $setupScript" -ForegroundColor Red
        Read-Host "Press Enter to continue"
    }
}

function Run-Installer {
    Write-Header "Installation"
    Write-Host "Starting Video Pipeline installer..." -ForegroundColor Green
    Write-Host "This will install to: $env:ProgramFiles\VideoPipeline" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Admin privileges required. Continuing..." -ForegroundColor Yellow
    Write-Host ""
    
    $installerScript = Join-Path $scriptPath "installer.ps1"
    if (Test-Path $installerScript) {
        & $installerScript
    } else {
        Write-Host "ERROR: Installer script not found: $installerScript" -ForegroundColor Red
        Read-Host "Press Enter to continue"
    }
}

function Run-Uninstaller {
    Write-Header "Uninstallation"
    Write-Host "Starting Video Pipeline uninstaller..." -ForegroundColor Yellow
    Write-Host "This will remove: $env:ProgramFiles\VideoPipeline" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Admin privileges required. Continuing..." -ForegroundColor Yellow
    Write-Host ""
    
    $uninstallerScript = Join-Path $scriptPath "uninstall.ps1"
    if (Test-Path $uninstallerScript) {
        & $uninstallerScript
    } else {
        Write-Host "ERROR: Uninstaller script not found: $uninstallerScript" -ForegroundColor Red
        Read-Host "Press Enter to continue"
    }
}

function View-Documentation {
    Write-Header "Documentation"
    $readmeFile = Join-Path $scriptPath "README.md"
    
    if (Test-Path $readmeFile) {
        Write-Host "Opening README.md..." -ForegroundColor Green
        & explorer.exe $readmeFile
    } else {
        Write-Host "ERROR: README.md not found" -ForegroundColor Red
        Read-Host "Press Enter to continue"
    }
}

function Open-Folder {
    Write-Host "Opening project folder in Explorer..." -ForegroundColor Green
    & explorer.exe $scriptPath
}

function Open-Terminal {
    Write-Host "Opening new PowerShell terminal in project directory..." -ForegroundColor Green
    Start-Process powershell.exe -WorkingDirectory $scriptPath
}

# ============================================
# MAIN EXECUTION
# ============================================

if ($Help) {
    Show-Help
    exit 0
}

if ($Validate) {
    Test-Prerequisites
    exit 0
}

if ($GUI) {
    Launch-GUI
    exit 0
}

if ($Web) {
    Launch-Web
    exit 0
}

if ($CLI) {
    Launch-CLI
    exit 0
}

if ($Install) {
    Run-Installer
    exit 0
}

if ($Uninstall) {
    Run-Uninstaller
    exit 0
}

if ($Setup) {
    Setup-Environment
    exit 0
}

# Interactive menu mode (default)
do {
    Write-Menu
    $choice = Read-Host "Select option (0-10)"
    
    switch ($choice) {
        "1" { Launch-GUI }
        "2" { Launch-Web }
        "3" { Launch-CLI }
        "4" { Test-Prerequisites }
        "5" { Setup-Environment }
        "6" { Run-Installer }
        "7" { Run-Uninstaller }
        "8" { View-Documentation }
        "9" { Open-Folder }
        "10" { Open-Terminal }
        "0" { 
            Write-Host ""
            Write-Host "Goodbye!" -ForegroundColor Green
            exit 0 
        }
        default { 
            Write-Host "Invalid option. Please try again." -ForegroundColor Red
            Start-Sleep -Seconds 1
        }
    }
} while ($true)
