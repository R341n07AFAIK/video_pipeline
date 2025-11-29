# PS2EXE Compilation & Distribution Helper Scripts

## File: build-installer.ps1
# Use this script to compile your installer.ps1 to EXE

param(
    [string]$SourceScript = "install.ps1",
    [string]$OutputExe = "install.exe",
    [string]$IconFile = "icon.ico",
    [string]$AppVersion = "1.0.0.0",
    [string]$Company = "MyCompany",
    [string]$ProductName = "MyApp",
    [switch]$X64,
    [switch]$NoConsole,
    [switch]$RequireAdmin,
    [switch]$SkipModuleCheck
)

# ============================================
# Configuration
# ============================================

$ErrorActionPreference = "Stop"

# ============================================
# Validation
# ============================================

Write-Host "=== PowerShell to EXE Compiler ===" -ForegroundColor Green
Write-Host ""

if (-not (Test-Path $SourceScript)) {
    Write-Error "Source script not found: $SourceScript"
    exit 1
}

Write-Host "Source Script: $SourceScript" -ForegroundColor Cyan
Write-Host "Output EXE:    $OutputExe" -ForegroundColor Cyan
Write-Host "Version:       $AppVersion" -ForegroundColor Cyan
Write-Host ""

# ============================================
# Install PS2EXE if needed
# ============================================

if (-not $SkipModuleCheck) {
    Write-Host "Checking for ps2exe module..." -ForegroundColor Yellow
    
    $module = Get-Module -Name ps2exe -ListAvailable
    
    if (-not $module) {
        Write-Host "ps2exe module not found. Installing..." -ForegroundColor Yellow
        
        try {
            Install-Module -Name ps2exe -Scope CurrentUser -Force
            Write-Host "✓ ps2exe installed successfully" -ForegroundColor Green
        } catch {
            Write-Error "Failed to install ps2exe: $_"
            Write-Host "Install manually with: Install-Module ps2exe -Scope CurrentUser"
            exit 1
        }
    } else {
        Write-Host "✓ ps2exe found: $($module.Version)" -ForegroundColor Green
    }
}

Write-Host ""

# ============================================
# Check Icon File
# ============================================

if ($IconFile -and -not (Test-Path $IconFile)) {
    Write-Warning "Icon file not found: $IconFile"
    Write-Host "Continuing without custom icon..." -ForegroundColor Yellow
    $IconFile = $null
} elseif ($IconFile) {
    Write-Host "✓ Icon file: $IconFile" -ForegroundColor Cyan
}

# ============================================
# Build Compilation Command
# ============================================

$ps2exeParams = @{
    inputFile = $SourceScript
    outputFile = $OutputExe
    title = $ProductName
    version = $AppVersion
    company = $Company
    product = $ProductName
    copyright = "(c) $(Get-Date -Format 'yyyy') $Company"
}

# Add optional parameters
if ($X64) {
    $ps2exeParams.Add("x64", $true)
    Write-Host "Target: 64-bit" -ForegroundColor Cyan
} else {
    $ps2exeParams.Add("x86", $true)
    Write-Host "Target: 32-bit (x86)" -ForegroundColor Cyan
}

if ($NoConsole) {
    $ps2exeParams.Add("noConsole", $true)
    Write-Host "Mode: GUI (no console)" -ForegroundColor Cyan
} else {
    Write-Host "Mode: Console" -ForegroundColor Cyan
}

if ($RequireAdmin) {
    $ps2exeParams.Add("requireAdmin", $true)
    Write-Host "Elevation: Required" -ForegroundColor Cyan
}

if ($IconFile) {
    $ps2exeParams.Add("iconFile", $IconFile)
}

Write-Host ""

# ============================================
# Compile
# ============================================

Write-Host "Compiling..." -ForegroundColor Yellow

try {
    Invoke-ps2exe @ps2exeParams
    
    if (Test-Path $OutputExe) {
        $fileSize = (Get-Item $OutputExe).Length / 1KB
        Write-Host "✓ Compilation successful!" -ForegroundColor Green
        Write-Host "Output: $OutputExe ($([math]::Round($fileSize))KB)" -ForegroundColor Green
        Write-Host ""
        
        # ============================================
        # Post-Compilation Actions
        # ============================================
        
        # Verify execution
        Write-Host "Testing executable..." -ForegroundColor Yellow
        
        try {
            $output = & $OutputExe -? 2>&1 | Select-Object -First 5
            if ($output) {
                Write-Host "✓ Executable test passed" -ForegroundColor Green
            }
        } catch {
            Write-Warning "Could not test executable (may require admin)"
        }
        
        Write-Host ""
        Write-Host "Build completed successfully!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Next steps:" -ForegroundColor Cyan
        Write-Host "  1. Test the executable on your target system"
        Write-Host "  2. Verify all features work correctly"
        Write-Host "  3. Sign with certificate (optional but recommended)"
        Write-Host "     signtool sign /f cert.pfx /p password /t http://timestamp.comodoca.com $OutputExe"
        Write-Host "  4. Distribute to users"
        
    } else {
        Write-Error "Compilation failed: Output file not created"
        exit 1
    }
    
} catch {
    Write-Error "Compilation error: $_"
    exit 1
}


# ============================================
# File: sign-executable.ps1
# Code sign your compiled EXE (requires certificate)
# ============================================

# Usage: .\sign-executable.ps1 -ExePath "install.exe" -CertPath "cert.pfx" -Password "certpassword"

param(
    [Parameter(Mandatory=$true)]
    [string]$ExePath,
    
    [Parameter(Mandatory=$true)]
    [string]$CertPath,
    
    [Parameter(Mandatory=$true)]
    [string]$Password,
    
    [string]$TimestampUrl = "http://timestamp.comodoca.com/rfc3161",
    
    [string]$Description = "Application Installer"
)

$ErrorActionPreference = "Stop"

Write-Host "=== Executable Code Signing Tool ===" -ForegroundColor Green

if (-not (Test-Path $ExePath)) {
    Write-Error "Executable not found: $ExePath"
    exit 1
}

if (-not (Test-Path $CertPath)) {
    Write-Error "Certificate not found: $CertPath"
    exit 1
}

Write-Host "Executable: $ExePath" -ForegroundColor Cyan
Write-Host "Certificate: $CertPath" -ForegroundColor Cyan

# Check for signtool
$signTool = Get-Command signtool.exe -ErrorAction SilentlyContinue

if (-not $signTool) {
    Write-Error "signtool.exe not found. Install Windows SDK or Visual Studio Build Tools."
    exit 1
}

Write-Host ""
Write-Host "Signing executable..." -ForegroundColor Yellow

try {
    & signtool.exe sign /f $CertPath /p $Password /d $Description /t $TimestampUrl $ExePath
    
    Write-Host "✓ Signing successful!" -ForegroundColor Green
    
    # Verify signature
    Write-Host "Verifying signature..." -ForegroundColor Yellow
    & signtool.exe verify /pa $ExePath
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Signature verified!" -ForegroundColor Green
    }
    
} catch {
    Write-Error "Signing failed: $_"
    exit 1
}


# ============================================
# File: build-and-package.ps1
# Complete build pipeline with testing
# ============================================

param(
    [string]$ProjectName = "MyApp",
    [string]$Version = "1.0.0.0",
    [string]$Company = "MyCompany",
    [switch]$Sign,
    [string]$CertPath,
    [string]$CertPassword
)

$ErrorActionPreference = "Stop"

# Directories
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$sourceScript = Join-Path $scriptPath "install.ps1"
$outputExe = Join-Path $scriptPath "dist\$ProjectName-$Version.exe"
$distDir = Join-Path $scriptPath "dist"

Write-Host "=== Complete Build Pipeline ===" -ForegroundColor Green
Write-Host "Project: $ProjectName" -ForegroundColor Cyan
Write-Host "Version: $Version" -ForegroundColor Cyan
Write-Host ""

# Create dist directory
if (-not (Test-Path $distDir)) {
    New-Item -ItemType Directory -Path $distDir | Out-Null
    Write-Host "✓ Created dist directory" -ForegroundColor Green
}

# Validate source
if (-not (Test-Path $sourceScript)) {
    Write-Error "Source script not found: $sourceScript"
    exit 1
}

Write-Host "✓ Source script found" -ForegroundColor Green
Write-Host ""

# Compile
Write-Host "Step 1: Compiling..." -ForegroundColor Yellow
$compileParams = @{
    SourceScript = $sourceScript
    OutputExe = $outputExe
    AppVersion = $Version
    Company = $Company
    ProductName = $ProjectName
    X64 = $true
    RequireAdmin = $true
}

& "$scriptPath\build-installer.ps1" @compileParams

if (-not (Test-Path $outputExe)) {
    Write-Error "Compilation failed"
    exit 1
}

# Sign (optional)
if ($Sign) {
    Write-Host ""
    Write-Host "Step 2: Signing..." -ForegroundColor Yellow
    
    if (-not $CertPath -or -not (Test-Path $CertPath)) {
        Write-Error "Certificate path required for signing"
        exit 1
    }
    
    if (-not $CertPassword) {
        Write-Error "Certificate password required for signing"
        exit 1
    }
    
    & "$scriptPath\sign-executable.ps1" `
        -ExePath $outputExe `
        -CertPath $CertPath `
        -Password $CertPassword
}

Write-Host ""
Write-Host "=== Build Complete ===" -ForegroundColor Green
Write-Host "Output: $outputExe" -ForegroundColor Cyan
Write-Host ""
Write-Host "Distribution files ready in: $distDir" -ForegroundColor Cyan


# ============================================
# File: test-installer.ps1
# Test the compiled installer before distribution
# ============================================

param(
    [Parameter(Mandatory=$true)]
    [string]$ExePath,
    
    [switch]$Elevated
)

$ErrorActionPreference = "Stop"

Write-Host "=== Installer Testing Tool ===" -ForegroundColor Green

if (-not (Test-Path $ExePath)) {
    Write-Error "Executable not found: $ExePath"
    exit 1
}

$fileInfo = Get-Item $ExePath
$fileSize = $fileInfo.Length / 1MB

Write-Host "Testing: $ExePath" -ForegroundColor Cyan
Write-Host "Size: $([math]::Round($fileSize, 2))MB" -ForegroundColor Cyan
Write-Host ""

# Test 1: File signature check
Write-Host "Test 1: File Signature" -ForegroundColor Yellow
$signature = Get-AuthenticodeSignature -FilePath $ExePath

if ($signature.Status -eq "Valid") {
    Write-Host "✓ Valid digital signature" -ForegroundColor Green
} else {
    Write-Warning "No digital signature (consider signing with certificate)"
}

Write-Host ""

# Test 2: Help information
Write-Host "Test 2: Help Information" -ForegroundColor Yellow
try {
    $help = & $ExePath -? 2>&1 | Select-Object -First 10
    if ($help) {
        Write-Host "✓ Help available" -ForegroundColor Green
        $help | ForEach-Object { Write-Host "  $_" }
    }
} catch {
    Write-Warning "Could not retrieve help: $_"
}

Write-Host ""

# Test 3: Antivirus scan URL
Write-Host "Test 3: Security Check" -ForegroundColor Yellow
$virusTotalUrl = "https://www.virustotal.com/gui/home/upload"
Write-Host "Consider uploading to VirusTotal for security scan:" -ForegroundColor Cyan
Write-Host "  $virusTotalUrl" -ForegroundColor Gray

Write-Host ""

# Test 4: System requirements
Write-Host "Test 4: System Requirements" -ForegroundColor Yellow
$osVersion = [Environment]::OSVersion.Version
$memoryGB = [math]::Round((Get-WmiObject Win32_ComputerSystem).TotalPhysicalMemory / 1GB)
$psVersion = "$($PSVersionTable.PSVersion.Major).$($PSVersionTable.PSVersion.Minor)"

Write-Host "  OS Version: $osVersion" -ForegroundColor Cyan
Write-Host "  Memory: ${memoryGB}GB" -ForegroundColor Cyan
Write-Host "  PowerShell: $psVersion" -ForegroundColor Cyan

Write-Host ""
Write-Host "=== Pre-Distribution Testing ===" -ForegroundColor Yellow
Write-Host "Before distributing, verify:" -ForegroundColor Cyan
Write-Host "  ☐ Test on Windows 10 system"
Write-Host "  ☐ Test on Windows 11 system"
Write-Host "  ☐ Test with minimal RAM (4GB)"
Write-Host "  ☐ Test without admin privileges (should prompt)"
Write-Host "  ☐ Test full installation flow"
Write-Host "  ☐ Test uninstall process"
Write-Host "  ☐ Test removal of registry entries"
Write-Host "  ☐ Scan with antivirus"
Write-Host "  ☐ Code sign with trusted certificate"
Write-Host "  ☐ Test signature validation"

Write-Host ""
Write-Host "✓ Testing tools ready" -ForegroundColor Green


# ============================================
# Usage Examples
# ============================================

<#

EXAMPLE 1: Simple Compilation
───────────────────────────────
.\build-installer.ps1 -SourceScript "install.ps1" -OutputExe "install.exe"


EXAMPLE 2: Compilation with Custom Icon
─────────────────────────────────────────
.\build-installer.ps1 `
  -SourceScript "install.ps1" `
  -OutputExe "MyApp-1.0.exe" `
  -IconFile "app.ico" `
  -RequireAdmin `
  -X64


EXAMPLE 3: Sign After Compilation
──────────────────────────────────
.\sign-executable.ps1 `
  -ExePath "MyApp-1.0.exe" `
  -CertPath "mycert.pfx" `
  -Password "password123" `
  -Description "MyApp Installer"


EXAMPLE 4: Complete Pipeline
─────────────────────────────
.\build-and-package.ps1 `
  -ProjectName "MyApp" `
  -Version "1.0.0.0" `
  -Company "MyCompany" `
  -Sign `
  -CertPath "mycert.pfx" `
  -CertPassword "password123"


EXAMPLE 5: Test Installer
─────────────────────────
.\test-installer.ps1 -ExePath "MyApp-1.0.exe"

#>
