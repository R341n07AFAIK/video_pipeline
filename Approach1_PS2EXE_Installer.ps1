################################
# APPROACH 1: PS2EXE INSTALLER
################################
# File: install.ps1
# Convert with: ps2exe -inputFile "install.ps1" -outputFile "install.exe" -requireAdmin -version "1.0.0.0" -company "MyCompany"

#Requires -RunAsAdministrator

param(
    [string]$InstallPath = "$env:ProgramFiles\MyApp",
    [switch]$Silent
)

# ============================================
# CONFIGURATION
# ============================================

$AppName = "MyApp"
$Version = "1.0.0.0"
$Company = "MyCompany"
$LogFile = "$env:TEMP\$AppName`_install.log"

# ============================================
# HELPER FUNCTIONS
# ============================================

function Log-Message {
    param([string]$Message, [string]$Level = "INFO")
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    Add-Content -Path $LogFile -Value $logEntry -Force
    
    if (-not $Silent) {
        switch ($Level) {
            "SUCCESS" { Write-Host "✓ $Message" -ForegroundColor Green }
            "ERROR" { Write-Host "❌ $Message" -ForegroundColor Red }
            "WARN" { Write-Host "⚠ $Message" -ForegroundColor Yellow }
            default { Write-Host "ℹ $Message" -ForegroundColor Cyan }
        }
    }
}

function Test-Administrator {
    $current = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
    return $current.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# ============================================
# SYSTEM REQUIREMENTS CHECK
# ============================================

function Test-SystemRequirements {
    Log-Message "Checking system requirements..."
    
    # Windows Version Check
    $osVersion = [Environment]::OSVersion.Version
    if ($osVersion.Major -lt 10) {
        Log-Message "Windows 10 or later required (Current: $osVersion)" "ERROR"
        return $false
    }
    Log-Message "✓ OS version: Windows $($osVersion.Major).$($osVersion.Minor)" "INFO"
    
    # RAM Check
    $memoryGB = [math]::Round((Get-WmiObject Win32_ComputerSystem).TotalPhysicalMemory / 1GB)
    if ($memoryGB -lt 4) {
        Log-Message "Minimum 4GB RAM required (Current: ${memoryGB}GB)" "ERROR"
        return $false
    }
    Log-Message "✓ Memory: ${memoryGB}GB" "INFO"
    
    # Disk Space Check
    $diskInfo = Get-PSDrive -Name C
    $freeSpaceGB = [math]::Round($diskInfo.Free / 1GB)
    if ($freeSpaceGB -lt 2) {
        Log-Message "Minimum 2GB free disk space required (Available: ${freeSpaceGB}GB)" "ERROR"
        return $false
    }
    Log-Message "✓ Disk space: ${freeSpaceGB}GB available" "INFO"
    
    # PowerShell Version
    if ($PSVersionTable.PSVersion.Major -lt 5) {
        Log-Message "PowerShell 5.0 or later required" "ERROR"
        return $false
    }
    Log-Message "✓ PowerShell: $($PSVersionTable.PSVersion.Major).$($PSVersionTable.PSVersion.Minor)" "INFO"
    
    Log-Message "System requirements verified successfully" "SUCCESS"
    return $true
}

# ============================================
# PREREQUISITE INSTALLATION
# ============================================

function Install-Prerequisites {
    Log-Message "Checking prerequisites..."
    
    # Check .NET Framework 4.7.2+
    $netVersion = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full" -ErrorAction SilentlyContinue
    
    if (-not $netVersion -or $netVersion.Release -lt 461808) {
        Log-Message ".NET Framework 4.7.2 or later not found" "WARN"
        Log-Message "Please install .NET Framework 4.7.2 from: https://dotnet.microsoft.com/download/dotnet-framework" "WARN"
        
        # In production, you could download and install automatically:
        # $url = "https://download.microsoft.com/download/D/D/3/DD35CC25-6E9C-484B-A746-C5BE0C923290/NDP472-KB4054530-x86-x64-AllOS-ENU.exe"
        # Invoke-WebRequest -Uri $url -OutFile "$env:TEMP\dotnet472.exe"
        # & "$env:TEMP\dotnet472.exe" /q /norestart
        
        return $false
    }
    
    Log-Message "✓ .NET Framework 4.7.2+ installed" "SUCCESS"
    return $true
}

# ============================================
# ENVIRONMENT CONFIGURATION
# ============================================

function Configure-Environment {
    Log-Message "Configuring environment..."
    
    # Create installation directory
    if (-not (Test-Path $InstallPath)) {
        try {
            New-Item -ItemType Directory -Path $InstallPath -Force -ErrorAction Stop | Out-Null
            Log-Message "✓ Created installation directory: $InstallPath" "SUCCESS"
        } catch {
            Log-Message "Failed to create installation directory: $_" "ERROR"
            return $false
        }
    }
    
    # Create registry entries
    try {
        $regPath = "HKLM:\Software\$Company\$AppName"
        if (-not (Test-Path $regPath)) {
            New-Item -Path "HKLM:\Software\$Company" -Force -ErrorAction SilentlyContinue | Out-Null
            New-Item -Path $regPath -Force -ErrorAction Stop | Out-Null
        }
        
        New-ItemProperty -Path $regPath -Name "InstallPath" -Value $InstallPath -PropertyType String -Force | Out-Null
        New-ItemProperty -Path $regPath -Name "Version" -Value $Version -PropertyType String -Force | Out-Null
        New-ItemProperty -Path $regPath -Name "InstallDate" -Value (Get-Date -Format "yyyyMMdd") -PropertyType String -Force | Out-Null
        
        Log-Message "✓ Registry entries created" "SUCCESS"
    } catch {
        Log-Message "Failed to create registry entries: $_" "ERROR"
        return $false
    }
    
    # Create config directory
    $configPath = "$env:ProgramData\$Company\$AppName"
    if (-not (Test-Path $configPath)) {
        New-Item -ItemType Directory -Path $configPath -Force -ErrorAction SilentlyContinue | Out-Null
        Log-Message "✓ Created config directory: $configPath" "SUCCESS"
    }
    
    return $true
}

# ============================================
# APPLICATION INSTALLATION
# ============================================

function Install-Application {
    Log-Message "Installing application..."
    
    try {
        # Copy application files (in production, extract from embedded archive or download)
        # For demo: create placeholder files
        
        @"
# $AppName Main Application
Write-Host "Application running..."
"@ | Set-Content "$InstallPath\app.ps1"
        
        # Create uninstall script
        New-UninstallScript
        
        Log-Message "✓ Application files installed" "SUCCESS"
        return $true
    } catch {
        Log-Message "Failed to install application: $_" "ERROR"
        return $false
    }
}

# ============================================
# SHORTCUT CREATION
# ============================================

function Create-Shortcuts {
    Log-Message "Creating shortcuts..."
    
    try {
        $shell = New-Object -ComObject WScript.Shell
        
        # Start Menu shortcut
        $startMenuPath = "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\$AppName"
        if (-not (Test-Path $startMenuPath)) {
            New-Item -ItemType Directory -Path $startMenuPath -Force | Out-Null
        }
        
        $shortcutPath = "$startMenuPath\$AppName.lnk"
        $appExePath = "$InstallPath\$AppName.exe"
        
        $shortcut = $shell.CreateShortcut($shortcutPath)
        $shortcut.TargetPath = $appExePath
        $shortcut.WorkingDirectory = $InstallPath
        $shortcut.Description = "$AppName v$Version"
        $shortcut.IconLocation = $appExePath
        $shortcut.Save()
        
        Log-Message "✓ Start Menu shortcut created" "SUCCESS"
        
        # Desktop shortcut (optional)
        $desktopPath = [Environment]::GetFolderPath("Desktop")
        $desktopShortcut = "$desktopPath\$AppName.lnk"
        
        $shortcut = $shell.CreateShortcut($desktopShortcut)
        $shortcut.TargetPath = $appExePath
        $shortcut.WorkingDirectory = $InstallPath
        $shortcut.Save()
        
        Log-Message "✓ Desktop shortcut created" "SUCCESS"
        return $true
        
    } catch {
        Log-Message "Failed to create shortcuts: $_" "WARN"
        return $true  # Don't fail installation for this
    }
}

# ============================================
# UNINSTALL SCRIPT CREATION
# ============================================

function New-UninstallScript {
    $uninstallScript = @"
#Requires -RunAsAdministrator
Write-Host "Uninstalling $AppName..."

`$appPath = "`$env:ProgramFiles\$AppName"
`$regPath = "HKLM:\Software\$Company\$AppName"

# Remove application files
if (Test-Path `$appPath) {
    Remove-Item `$appPath -Recurse -Force
    Write-Host "✓ Application files removed"
}

# Remove registry entries
if (Test-Path `$regPath) {
    Remove-Item `$regPath -Recurse -Force
    Write-Host "✓ Registry entries removed"
}

# Remove shortcuts
`$startMenuPath = "`$env:ProgramData\Microsoft\Windows\Start Menu\Programs\$AppName"
if (Test-Path `$startMenuPath) {
    Remove-Item `$startMenuPath -Recurse -Force
    Write-Host "✓ Shortcuts removed"
}

Write-Host "✓ Uninstallation complete"
"@
    
    try {
        $uninstallPath = "$InstallPath\Uninstall.ps1"
        Set-Content -Path $uninstallPath -Value $uninstallScript -Force
        Log-Message "✓ Uninstall script created" "SUCCESS"
    } catch {
        Log-Message "Failed to create uninstall script: $_" "WARN"
    }
}

# ============================================
# MAIN INSTALLATION FLOW
# ============================================

function Start-Installation {
    try {
        Log-Message "========================================" "INFO"
        Log-Message "$AppName Installation Started" "INFO"
        Log-Message "Version: $Version" "INFO"
        Log-Message "Installation Path: $InstallPath" "INFO"
        Log-Message "========================================" "INFO"
        
        # Check admin rights
        if (-not (Test-Administrator)) {
            Log-Message "This installation requires administrator privileges" "ERROR"
            if (-not $Silent) {
                Write-Host "Press any key to exit..."
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            exit 1
        }
        
        # Check system requirements
        if (-not (Test-SystemRequirements)) {
            if (-not $Silent) {
                Write-Host "`nPress any key to exit..."
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            exit 1
        }
        
        # Install prerequisites
        if (-not (Install-Prerequisites)) {
            Log-Message "Installation aborted: prerequisites not met" "ERROR"
            if (-not $Silent) {
                Write-Host "`nPress any key to exit..."
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            exit 1
        }
        
        # Configure environment
        if (-not (Configure-Environment)) {
            Log-Message "Installation failed during configuration" "ERROR"
            exit 1
        }
        
        # Install application
        if (-not (Install-Application)) {
            Log-Message "Installation failed" "ERROR"
            exit 1
        }
        
        # Create shortcuts
        Create-Shortcuts
        
        Log-Message "========================================" "INFO"
        Log-Message "$AppName Installation Completed Successfully!" "SUCCESS"
        Log-Message "Application installed to: $InstallPath" "INFO"
        Log-Message "Log file: $LogFile" "INFO"
        Log-Message "========================================" "INFO"
        
        if (-not $Silent) {
            Write-Host "`nPress any key to exit..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        
    } catch {
        Log-Message "Unexpected error: $_" "ERROR"
        if (-not $Silent) {
            Write-Host "`nPress any key to exit..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        exit 1
    }
}

# Run installation
Start-Installation
