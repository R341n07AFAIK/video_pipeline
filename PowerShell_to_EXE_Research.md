# PowerShell to EXE Conversion: Comprehensive Research & Guide

## Executive Summary

This document provides an in-depth analysis of converting PowerShell scripts to standalone EXE executables, focusing on professional installer creation that supports system requirements checking, elevated execution, prerequisite installation, and uninstall capabilities.

---

## 1. PS2EXE Tool

**Official Repository:** https://github.com/MScholtes/PS2EXE  
**Current Version:** 1.0.17 (Updated August 2025)

### Overview
PS2EXE is a PowerShell module that converts PowerShell 5.1 scripts into Windows executables. It generates real .NET 4.x binaries with optional GUI support.

### Installation & Setup
```powershell
# Install from PowerShell Gallery
Install-Module ps2exe

# Or download and import directly
Import-Module .\ps2exe.psd1
```

### Capabilities
- **Console & GUI modes:** `-noConsole` creates Windows Forms app without console window
- **Bit version selection:** `-x86` or `-x64` compilation
- **Icon customization:** `-iconFile` parameter
- **Embedded files:** `-embedFiles` hashtable to bundle files within EXE
- **Version metadata:** Company, product, version, copyright information
- **UAC elevation:** `-requireAdmin` flag for elevated execution
- **DPI awareness:** `-DPIAware` and `-DPIAware` for scaling support
- **Credential GUI:** `-credentialGUI` for password prompts
- **File extraction:** Support for extracting source script with `-extract` parameter

### Key Parameters
```powershell
ps2exe [-inputFile] '<file_name>' [[-outputFile] '<file_name>'] `
  [-x86|-x64] `
  [-noConsole] `
  [-iconFile '<filename>'] `
  [-title '<title>'] `
  [-version '<version>'] `
  [-requireAdmin] `
  [-embedFiles @{'target'='source'}] `
  [-credentialGUI] `
  [-UNICODEEncoding]
```

### Pros & Cons

**Pros:**
- ✅ Easy one-command compilation
- ✅ GUI support with optional console-free execution
- ✅ Can embed additional files
- ✅ Supports PowerShell Core and 5.1
- ✅ Professional metadata (version, company, copyright)
- ✅ File extraction capability for debugging
- ✅ Recent active maintenance (2025)
- ✅ PowerShell Gallery distribution
- ✅ Graphical front-end (Win-PS2EXE) available

**Cons:**
- ❌ Script source extractable with `-extract` (security concern)
- ❌ Only compiles PowerShell 5.1 compatible code
- ❌ Limited advanced installer features (no proper MSI)
- ❌ No built-in uninstall mechanism
- ❌ Write-Progress not supported in console mode
- ❌ Start-Transcript/Stop-Transcript not implemented
- ❌ `$PSScriptRoot` variable unavailable

### Complexity Level: **LOW**
Simple command-line conversion with optional parameters.

### Security Considerations
- **CRITICAL:** Scripts can be extracted from compiled EXE
- Do NOT embed sensitive credentials or passwords
- Consider code obfuscation for proprietary logic
- Use signing certificates for trusted distribution

### Best Use Cases
- Internal tools and utilities
- IT automation scripts
- System administration tools
- Quick prototyping and distribution
- Non-sensitive data processing applications

### Limitations for Professional Installers
- No automatic system requirement checks
- No built-in prerequisite installation
- No native uninstall mechanism
- No registry modification support
- No service installation capabilities

---

## 2. Visual Studio Build Tools & WiX Toolset (MSI Creation)

### Overview
Using MSI (Windows Installer) technology via WiX Toolset or Visual Studio provides enterprise-grade installer capabilities but requires compilation and significant setup.

### Installation & Setup
```powershell
# Install WiX Toolset
$wixDownload = "https://github.com/wixtoolset/wix3/releases/download/wix311rtm/wix311.exe"
# Download and install

# Visual Studio Build Tools require substantial disk space (4-8GB)
# Download from: https://visualstudio.microsoft.com/visual-cpp-build-tools/
```

### Capabilities
- Complete MSI package with full Windows Installer features
- Registry modification and cleanup
- Service installation
- Automatic uninstall through Control Panel
- Repair functionality
- Feature selection during installation
- Custom actions via C# or VBScript
- System requirement checks
- Component versioning and upgrading

### Basic WiX Example (Product.wxs)
```xml
<?xml version="1.0" encoding="UTF-8"?>
<Wix xmlns="http://schemas.microsoft.com/wix/2006/wi">
  <Product Id="*" Name="MyPowerShellApp" Language="1033" 
           Version="1.0.0.0" UpgradeCode="PUT-GUID-HERE">
    
    <Package InstallerVersion="200" Compressed="yes" />
    <Media Id="1" Cabinet="app.cab" EmbedCab="yes" />
    
    <Directory Id="TARGETDIR" Name="SourceDir">
      <Directory Id="ProgramFilesFolder">
        <Directory Id="INSTALLFOLDER" Name="MyPowerShellApp" />
      </Directory>
      <Directory Id="ProgramMenuFolder">
        <Directory Id="ApplicationProgramsFolder" Name="MyPowerShellApp" />
      </Directory>
    </Directory>
    
    <Feature Id="ProductFeature" Title="My PowerShell App" Level="1">
      <ComponentRef Id="MainExeComponent" />
      <ComponentRef Id="ProgramMenuComponent" />
    </Feature>
    
  </Product>
</Wix>
```

### Pros & Cons

**Pros:**
- ✅ Professional MSI format (industry standard)
- ✅ Complete Control Panel Add/Remove Programs integration
- ✅ Built-in repair and uninstall
- ✅ System requirement validation at install time
- ✅ Registry management and cleanup
- ✅ Service installation support
- ✅ Feature selection during installation
- ✅ Rollback on failure

**Cons:**
- ❌ Steep learning curve (XML configuration)
- ❌ Significant disk space required (Build Tools ~8GB)
- ❌ Complex setup for simple applications
- ❌ Compilation time between builds
- ❌ Requires Visual Studio or Build Tools installation
- ❌ Overkill for simple internal tools
- ❌ Long initial setup time

### Complexity Level: **HIGH**
Requires understanding of WiX/MSI concepts, XML configuration, and build processes.

### Security Considerations
- MSI signatures with code signing certificates
- Custom actions execute with installer privileges
- Registry modifications require careful planning
- No embedded sensitive data
- Use authenticode signing for trusted distribution

### Best Use Cases
- Production/commercial software distribution
- Enterprise software deployment
- Applications requiring system integration
- Complex dependency management
- Multi-user or multi-machine deployment

### Limitations
- Overkill for simple internal tools
- Steep learning curve for novices
- Long development cycle

---

## 3. Batch Wrapper Approach

### Overview
Create a batch file that invokes PowerShell to run your script, optionally requesting elevation. Simple but less professional than compiled solutions.

### Installation & Setup
No installation required. Batch is native to Windows.

### Implementation Example

**launcher.bat**
```batch
@echo off
REM Batch wrapper for PowerShell script
REM This script requests elevation and runs PowerShell

setlocal enabledelayedexpansion

REM Check for admin privileges
openfiles >nul 2>&1
if errorlevel 1 (
    REM Request elevation
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

REM Admin check - if we get here, we have elevation
echo Running with elevated privileges...

REM Execute PowerShell script
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1"
exit /b %errorlevel%
```

**Better hybrid approach (single file with both batch and PowerShell):**
```batch
:: ====== BATCH SECTION ======
@echo off
setlocal enabledelayedexpansion

REM Check if running as admin
openfiles >nul 2>&1
if errorlevel 1 (
    REM Not admin - request elevation
    powershell -Command "Start-Process cmd.exe -ArgumentList '/c %~f0' -Verb RunAs"
    exit /b %errorlevel%
)

REM We have admin privileges - run PowerShell
cls
echo Installing application...
powershell -NoProfile -ExecutionPolicy Bypass -Command "& {%~f0}"
exit /b

:: ====== POWERSHELL SECTION ======
#>
# Everything below this line is PowerShell code

Write-Host "Running PowerShell installation script..."
Write-Host "Current user: $env:USERNAME"
Write-Host "Is elevated: $([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]'Administrator')"

# Check system requirements
function Test-SystemRequirements {
    param(
        [string]$OSVersion = "10.0",
        [string]$PowerShellVersion = "5.1",
        [int]$MinMemoryGB = 2
    )
    
    $currentOS = [Environment]::OSVersion.Version
    $currentPS = $PSVersionTable.PSVersion.Major.ToString() + "." + $PSVersionTable.PSVersion.Minor.ToString()
    $totalMemoryGB = [math]::Round((Get-WmiObject Win32_ComputerSystem).TotalPhysicalMemory / 1GB)
    
    Write-Host "`nSystem Check:"
    Write-Host "  OS Version: $currentOS"
    Write-Host "  PowerShell: $currentPS"
    Write-Host "  Memory: ${totalMemoryGB}GB"
    
    if ($currentOS -lt [version]$OSVersion) {
        Write-Host "  ❌ OS version too old. Required: $OSVersion"
        return $false
    }
    
    if ($totalMemoryGB -lt $MinMemoryGB) {
        Write-Host "  ❌ Insufficient memory. Required: ${MinMemoryGB}GB"
        return $false
    }
    
    Write-Host "  ✓ All requirements met"
    return $true
}

# Install prerequisites
function Install-Prerequisites {
    Write-Host "`nInstalling prerequisites..."
    
    # Example: Install .NET Framework
    # This is placeholder - adapt to your needs
    
    Write-Host "  ✓ Prerequisites installed"
}

# Configure environment
function Configure-Environment {
    Write-Host "`nConfiguring environment..."
    
    $appPath = "$env:ProgramFiles\MyApp"
    if (-not (Test-Path $appPath)) {
        New-Item -ItemType Directory -Path $appPath | Out-Null
        Write-Host "  ✓ Created app directory: $appPath"
    }
    
    # Set environment variables, create config files, etc.
}

# Create shortcuts
function Create-Shortcuts {
    Write-Host "`nCreating shortcuts..."
    
    $appPath = "$env:ProgramFiles\MyApp\MyApp.exe"
    $desktopPath = [Environment]::GetFolderPath("Desktop")
    $shortcutPath = "$desktopPath\MyApp.lnk"
    
    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($shortcutPath)
    $shortcut.TargetPath = $appPath
    $shortcut.WorkingDirectory = [System.IO.Path]::GetDirectoryName($appPath)
    $shortcut.Save()
    
    Write-Host "  ✓ Desktop shortcut created"
}

# Main installation logic
if (Test-SystemRequirements -OSVersion "10.0" -MinMemoryGB 2) {
    Install-Prerequisites
    Configure-Environment
    Create-Shortcuts
    Write-Host "`n✓ Installation completed successfully!"
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
} else {
    Write-Host "`n❌ Installation failed. System requirements not met."
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}
```

### Pros & Cons

**Pros:**
- ✅ No external dependencies (native to Windows)
- ✅ Simple creation (just text files)
- ✅ Can request elevation smoothly
- ✅ Easy to understand and modify
- ✅ Low resource overhead
- ✅ Works across all Windows versions

**Cons:**
- ❌ Not a true compiled executable
- ❌ Source code visible in batch file
- ❌ PowerShell script extractable
- ❌ Less professional appearance
- ❌ No built-in installer UI
- ❌ Requires PowerShell installed
- ❌ Execution policy concerns

### Complexity Level: **MEDIUM**
Straightforward for simple scripts; complexity increases with feature requirements.

### Security Considerations
- Batch and PowerShell both human-readable
- Credentials visible in plaintext
- Execution policy must be permissive
- Less suitable for sensitive operations
- Code obfuscation recommended

### Best Use Cases
- Internal IT tools
- Quick deployment scripts
- Testing and prototyping
- Simple system administration tasks
- Scenarios where full installer not needed

---

## 4. ProtoScript2EXE & Alternative Tools

**Status:** Legacy/Discontinued

ProtoScript2EXE is largely superseded by PS2EXE and is not recommended for new projects.

### Known Alternatives
1. **AutoIt3** - General-purpose automation (not PowerShell specific)
2. **AutoHotkey** - Automation but different language
3. **NSSM** (Non-Sucking Service Manager) - For service creation
4. **Enigma Virtual Box** - File virtualization for deployment

None offer specific advantages over PS2EXE for PowerShell conversion.

---

## 5. WinRAR SFX Approach

### Overview
WinRAR's Self-Extracting Archive (SFX) feature can package files and execute batch/executable. Not ideal for PowerShell but usable.

### Implementation
```
1. Create RAR archive with your files
2. Add SFX stub (WinRAR's sfxrar.exe)
3. Configure extraction and execution
```

### Basic Configuration (SFX Script)
```ini
;The comment below contains SFX script commands
;!@Install@!UTF-8!
GUIMode="2"
Title="My PowerShell Application"
BeginPrompt="Install My Application?"
RunProgram="cmd.exe /c powershell -NoProfile -ExecutionPolicy Bypass -File ""%S\install.ps1"""
;!@InstallEnd@!
```

### Pros & Cons

**Pros:**
- ✅ Single file distribution
- ✅ Built-in extraction and compression
- ✅ Can display prompts and progress
- ✅ Works without additional software

**Cons:**
- ❌ WinRAR is commercial (trial available)
- ❌ Not ideal for PowerShell workflows
- ❌ Limited customization
- ❌ Less professional than true installers
- ❌ File association issues
- ❌ No proper uninstall mechanism

### Complexity Level: **MEDIUM-LOW**
Simpler than MSI but less featured than dedicated approaches.

### Security Considerations
- SFX executable requires trust
- Can be used for malware delivery (reputation risk)
- Source files extractable
- Antivirus may flag SFX files
- Use code signing certificates

### Best Use Cases
- Simple file distribution
- Quick deployment when installer not available
- Legacy systems requiring RAR
- Compression + execution in one file

---

## 6. InstallShield & Advanced Installer

### Overview
Professional third-party installer creation tools with GUI builders and extensive features.

### Advanced Installer Features
- **Editions:** Free, Professional, Enterprise
- **Formats:** MSI, MSIX, EXE
- **GUI:**  Full WYSIWYG builder
- **Integration:** Visual Studio extension
- **Automation:** PowerShell support built-in
- **Code signing:** Trusted Signing integration (Azure)
- **Updater:** Built-in auto-update system
- **Support:** Dedicated support team

### Example Workflow with Advanced Installer

**1. Create Project**
```
- Launch Advanced Installer
- New Project → MSI or EXE format
- Select application type (desktop, service, etc.)
```

**2. Configure Installation**
```
- Add files to install
- Configure installation folders
- Set version information
- Create registry entries if needed
```

**3. System Requirements Check**
```xml
<!-- Built into Advanced Installer UI -->
<!-- Checks OS version, available disk space, required registry keys -->
```

**4. Custom Actions (PowerShell Integration)**
```xml
<!-- Advanced Installer can run PowerShell scripts at different stages -->
<CustomAction
  Id="RunPowerShellSetup"
  Property="RunPowerShellScript"
  Value="C:\Scripts\setup.ps1"
  Execute="deferred"
/>
```

### Pros & Cons

**Pros:**
- ✅ Full GUI-based builder (no XML/coding)
- ✅ Professional output (MSI/EXE/MSIX)
- ✅ Extensive feature set
- ✅ Built-in system requirement checking
- ✅ Auto-updater included
- ✅ Code signing integration
- ✅ Visual Studio integration
- ✅ Dedicated support

**Cons:**
- ❌ Commercial license required ($200-500)
- ❌ Learning curve for complex features
- ❌ Trial period limited (30 days)
- ❌ Overkill for simple scripts
- ❌ Disk space required

### Complexity Level: **LOW-MEDIUM**
GUI-driven; complexity depends on project requirements.

### Security Considerations
- Professional code signing support
- Trusted Signing integration via Azure
- Registry modification logging
- No embedded sensitive data
- Enterprise-grade security

### Best Use Cases
- Commercial software distribution
- Enterprise deployments
- Complex multi-component installations
- Products requiring auto-update capability
- Professional service companies

### Licensing
- **Free Edition:** Basic MSI creation, no GUI builder
- **Professional:** $299-500 one-time
- **Enterprise:** Custom pricing for teams

---

## InstallShield (Older Alternative)

InstallShield is more expensive and less frequently updated compared to Advanced Installer. Not recommended for new projects.

---

## COMPARISON MATRIX

| Feature | PS2EXE | WiX/MSI | Batch Wrapper | WinRAR SFX | Advanced Installer |
|---------|--------|--------|---------------|------------|-------------------|
| **Ease of Use** | Easy | Hard | Easy | Medium | Easy |
| **Professional Look** | Medium | High | Low | Low | High |
| **Compiled** | Yes | Yes | No | No | Yes |
| **GUI Builder** | No | No | No | No | Yes |
| **System Checks** | Manual | Yes | Manual | Limited | Yes |
| **Uninstall** | No | Yes | No | No | Yes |
| **Cost** | Free | Free | Free | Free/Paid | Paid ($299+) |
| **Learning Curve** | Low | High | Low | Low | Low |
| **Installation File Size** | ~30KB | Variable | ~10KB | ~100KB | ~500KB |
| **Distribution** | Single EXE | Single MSI | Single BAT | Single RAR/EXE | Single MSI/EXE |
| **Code Visibility** | Extractable | Compiled | Visible | Visible | Compiled |
| **Enterprise Support** | No | Community | No | No | Yes |

---

## RECOMMENDED SOLUTIONS (2-3 BEST APPROACHES)

### **Approach 1: PS2EXE (Best for Internal Tools) ⭐**

**Recommended for:** Quick deployment, internal tools, IT automation, non-critical applications

**Pros:**
- Single command compilation
- Professional metadata support
- Recent active development
- File embedding capability
- GUI/Console modes
- Free

**Setup:**
```powershell
# Install
Install-Module ps2exe -Scope CurrentUser

# Basic usage
ps2exe -inputFile "install.ps1" -outputFile "install.exe" `
  -iconFile "icon.ico" `
  -version "1.0.0.0" `
  -company "MyCompany" `
  -requireAdmin
```

**Complete Installer Example with PS2EXE:**

**install.ps1** (Source script)
```powershell
#Requires -RunAsAdministrator

function Test-SystemRequirements {
    $osVersion = [Environment]::OSVersion.Version
    if ($osVersion.Major -lt 10) {
        Write-Error "Windows 10 or later required"
        return $false
    }
    
    $memoryGB = [math]::Round((Get-WmiObject Win32_ComputerSystem).TotalPhysicalMemory / 1GB)
    if ($memoryGB -lt 4) {
        Write-Error "Minimum 4GB RAM required"
        return $false
    }
    
    Write-Host "✓ System requirements verified"
    return $true
}

function Install-Prerequisites {
    Write-Host "Installing prerequisites..."
    
    # Example: Ensure .NET 4.7.2 installed
    $netVersion = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full" -ErrorAction SilentlyContinue
    if (-not $netVersion -or $netVersion.Release -lt 461808) {
        Write-Host "Installing .NET Framework 4.7.2..."
        # Download and install silently
    }
}

function Install-Application {
    $appPath = "$env:ProgramFiles\MyApp"
    if (-not (Test-Path $appPath)) {
        New-Item -ItemType Directory -Path $appPath -Force | Out-Null
    }
    
    # Copy files (in real scenario, extract embedded files)
    Write-Host "Installing application files to $appPath"
    
    # Create registry entries
    $regPath = "HKLM:\Software\MyApp"
    if (-not (Test-Path $regPath)) {
        New-Item -Path $regPath -Force | Out-Null
        New-ItemProperty -Path $regPath -Name "InstallPath" -Value $appPath -PropertyType String -Force | Out-Null
        New-ItemProperty -Path $regPath -Name "Version" -Value "1.0.0.0" -PropertyType String -Force | Out-Null
    }
    
    Write-Host "✓ Application installed successfully"
}

function Create-Shortcuts {
    $appPath = "$env:ProgramFiles\MyApp"
    $startMenuPath = "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\MyApp"
    $desktopPath = [Environment]::GetFolderPath("Desktop")
    
    if (-not (Test-Path $startMenuPath)) {
        New-Item -ItemType Directory -Path $startMenuPath -Force | Out-Null
    }
    
    $shell = New-Object -ComObject WScript.Shell
    
    # Create Start Menu shortcut
    $shortcut = $shell.CreateShortcut("$startMenuPath\MyApp.lnk")
    $shortcut.TargetPath = "$appPath\MyApp.exe"
    $shortcut.WorkingDirectory = $appPath
    $shortcut.Description = "My Application"
    $shortcut.Save()
    
    Write-Host "✓ Shortcuts created"
}

# Main execution
try {
    Write-Host "MyApp Installer v1.0`n" -ForegroundColor Green
    
    if (-not (Test-SystemRequirements)) {
        Write-Host "Installation failed: System requirements not met" -ForegroundColor Red
        exit 1
    }
    
    Install-Prerequisites
    Install-Application
    Create-Shortcuts
    
    Write-Host "`n✓ Installation completed successfully!" -ForegroundColor Green
    Write-Host "Application installed to: $env:ProgramFiles\MyApp"
    
} catch {
    Write-Host "`n❌ Installation failed: $_" -ForegroundColor Red
    exit 1
}
```

**Compilation:**
```powershell
ps2exe -inputFile "install.ps1" `
  -outputFile "install.exe" `
  -title "MyApp Installer" `
  -version "1.0.0.0" `
  -company "MyCompany" `
  -copyright "(c) 2025 MyCompany" `
  -iconFile "icon.ico" `
  -requireAdmin
```

---

### **Approach 2: Advanced Installer (Best for Professional Products) ⭐⭐**

**Recommended for:** Commercial distribution, enterprise deployment, complex requirements

**Advantages:**
- Full GUI builder (no coding)
- Professional MSI/EXE output
- Built-in system requirement checking
- Auto-updater included
- Code signing support
- Excellent support
- MSIX format support

**Workflow:**

1. **Create New Project**
   - Open Advanced Installer
   - New Project → EXE or MSI
   - Select application type

2. **Add Files & Configure**
   - Drag/drop files to install
   - Set installation directories
   - Configure version information

3. **Add System Requirements**
   ```
   - Right-click Project → System Requirements
   - Add OS version check (Windows 10+)
   - Add RAM check (minimum 4GB)
   - Add disk space check
   ```

4. **Add Custom Actions (PowerShell)**
   ```
   - Custom Actions → New Custom Action
   - Type: Inline script (PowerShell)
   - Execute during: Installation finalization
   - Content: PowerShell setup code
   ```

5. **Build & Sign**
   ```
   - Build → Build Solution
   - Sign output with code signing certificate
   - Trusted Signing integration available
   ```

---

### **Approach 3: Batch Wrapper + PS2EXE (Best for Mixed Scenarios) ⭐**

**Recommended for:** Legacy support, dual distribution format, maximum compatibility

**Concept:** Distribute both .BAT and .EXE versions for maximum compatibility

**launcher.bat**
```batch
@echo off
:: Batch launcher wrapper
:: Automatically elevates and runs PowerShell script

setlocal enabledelayedexpansion

REM Check for admin privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting administrator privileges...
    powershell -Command "Start-Process cmd.exe -ArgumentList '/c %~f0' -Verb RunAs" -Wait
    exit /b
)

REM Execute PS2EXE compiled executable
call "%~dp0install.exe"
exit /b %errorlevel%
```

**Or use embedded PowerShell in batch:**
```batch
@echo off
setlocal
pushd "%~dp0"

REM Check admin
openfiles >nul 2>&1
if errorlevel 1 (
    powershell -Command "Start-Process cmd.exe -ArgumentList '/c %~f0' -Verb RunAs" -Wait
    exit /b %errorlevel%
)

REM Run embedded PowerShell
powershell -NoProfile -ExecutionPolicy Bypass -Command "& {%~f0}"
exit /b

#>
# PowerShell code starts here
Write-Host "Running installation in elevated mode..."

# Your installation logic here
```

---

## SECURITY BEST PRACTICES

### For All Approaches

1. **Never embed passwords or sensitive data**
   ```powershell
   # BAD - Never do this!
   $password = "SuperSecretPassword123"
   
   # GOOD - Use credential prompts
   $cred = Get-Credential -Message "Enter admin credentials"
   ```

2. **Code Signing**
   ```powershell
   # Sign PowerShell script
   $cert = Get-ChildItem Cert:\CurrentUser\My -CodeSigningCert
   Set-AuthenticodeSignature -FilePath install.ps1 -Certificate $cert
   
   # Sign compiled EXE (requires Signtool.exe)
   signtool.exe sign /f certificate.pfx /p password /t http://timestamp.comodoca.com install.exe
   ```

3. **Execution Policy Handling**
   ```powershell
   # In compiled EXE or batch wrapper
   powershell -ExecutionPolicy Bypass -File script.ps1  # Temporary override
   ```

4. **Input Validation**
   ```powershell
   param(
       [ValidatePattern('^[a-zA-Z0-9\-_]+$')]
       [string]$AppName,
       
       [ValidateRange(1,65535)]
       [int]$Port
   )
   ```

5. **Error Handling**
   ```powershell
   $ErrorActionPreference = "Stop"
   
   try {
       # Installation code
   } catch {
       Write-Error "Installation failed: $_"
       exit 1
   } finally {
       # Cleanup code
   }
   ```

---

## SYSTEM REQUIREMENT CHECKING

### Template for All Approaches

```powershell
function Test-InstallationRequirements {
    param(
        [ValidateSet('10', '11')]
        [string]$WindowsVersion = '10',
        
        [int]$MinimumRAMGB = 4,
        
        [int]$MinimumDiskSpaceGB = 2,
        
        [string[]]$RequiredPrograms = @()
    )
    
    $allRequirementsMet = $true
    
    # Check OS Version
    $osInfo = [Environment]::OSVersion.Version
    if ($osInfo.Major -lt $WindowsVersion) {
        Write-Warning "Windows $WindowsVersion or later is required (Current: $osInfo.Major.$osInfo.Minor)"
        $allRequirementsMet = $false
    }
    
    # Check RAM
    $totalMemory = [math]::Round((Get-WmiObject Win32_ComputerSystem).TotalPhysicalMemory / 1GB)
    if ($totalMemory -lt $MinimumRAMGB) {
        Write-Warning "Minimum ${MinimumRAMGB}GB RAM required (Current: ${totalMemory}GB)"
        $allRequirementsMet = $false
    }
    
    # Check Disk Space
    $installDrive = [System.IO.Path]::GetPathRoot($env:ProgramFiles)
    $diskInfo = Get-Volume -DriveLetter $installDrive[0]
    $diskSpaceGB = [math]::Round($diskInfo.SizeRemaining / 1GB)
    
    if ($diskSpaceGB -lt $MinimumDiskSpaceGB) {
        Write-Warning "Minimum ${MinimumDiskSpaceGB}GB disk space required (Available: ${diskSpaceGB}GB)"
        $allRequirementsMet = $false
    }
    
    # Check for required programs
    foreach ($program in $RequiredPrograms) {
        $programPath = Get-Command $program -ErrorAction SilentlyContinue
        if (-not $programPath) {
            Write-Warning "$program is required but not found in PATH"
            $allRequirementsMet = $false
        }
    }
    
    return $allRequirementsMet
}

# Usage
if (-not (Test-InstallationRequirements -WindowsVersion '10' -MinimumRAMGB 4)) {
    Write-Error "System requirements not met"
    exit 1
}
```

---

## UNINSTALL CAPABILITY

### For PS2EXE Approach

```powershell
function Create-UninstallScript {
    $uninstallScript = @"
    Write-Host "Uninstalling MyApp..."
    
    `$appPath = "`$env:ProgramFiles\MyApp"
    if (Test-Path `$appPath) {
        Remove-Item `$appPath -Recurse -Force
        Write-Host "✓ Application files removed"
    }
    
    `$regPath = "HKLM:\Software\MyApp"
    if (Test-Path `$regPath) {
        Remove-Item `$regPath -Recurse -Force
        Write-Host "✓ Registry entries removed"
    }
    
    `$startMenuPath = "`$env:ProgramData\Microsoft\Windows\Start Menu\Programs\MyApp"
    if (Test-Path `$startMenuPath) {
        Remove-Item `$startMenuPath -Recurse -Force
        Write-Host "✓ Shortcuts removed"
    }
    
    Write-Host "✓ Uninstallation complete"
"@
    
    $uninstallPath = "$env:ProgramFiles\MyApp\Uninstall.ps1"
    $uninstallScript | Set-Content $uninstallPath
}
```

---

## CONCLUSION

### Quick Recommendation Table

| Scenario | Recommended Approach | Rationale |
|----------|--------------------|------------|
| **Internal IT tool** | PS2EXE | Fast, simple, no license cost |
| **Commercial product** | Advanced Installer | Professional, auto-update, support |
| **Enterprise deployment** | Advanced Installer or WiX | MSI standard, control panel integration |
| **Quick prototype** | Batch wrapper | Immediate, no compilation |
| **Maximum compatibility** | PS2EXE + Batch | Works everywhere |
| **Service deployment** | WiX + Custom actions | Full Windows integration |
| **Legacy system support** | Batch wrapper | Minimal dependencies |

### Next Steps

1. **For PS2EXE:**
   ```powershell
   Install-Module ps2exe
   # Follow examples above
   ```

2. **For Advanced Installer:**
   - Download 30-day trial: https://www.advancedinstaller.com/trial.html
   - Follow UI-based workflow

3. **For Batch Wrapper:**
   - Use provided templates
   - No installation needed

4. **For Production:**
   - Implement code signing
   - Test on target systems
   - Document installation steps
   - Create uninstall procedure

