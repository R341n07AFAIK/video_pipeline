# install-prerequisites.ps1
# Automated installation of all video pipeline prerequisites
# Requires: Admin privileges, Windows 10/11

param(
    [switch]$SkipFFmpeg,
    [switch]$SkipPython,
    [switch]$SkipComfyUI,
    [switch]$NoPrompt
)

$ErrorActionPreference = "Continue"

function Write-Status {
    param([string]$Message, [string]$Status = "INFO")
    $color = switch($Status) {
        "OK" { "Green" }
        "WARN" { "Yellow" }
        "ERROR" { "Red" }
        "CHECK" { "Cyan" }
        default { "White" }
    }
    Write-Host "[$Status] $Message" -ForegroundColor $color
}

function Test-AdminPrivileges {
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
    return $isAdmin
}

function Install-FFmpeg {
    Write-Status "Installing FFmpeg..." "CHECK"
    
    if (Get-Command ffmpeg -ErrorAction SilentlyContinue) {
        Write-Status "FFmpeg already installed" "OK"
        ffmpeg -version | Select-Object -First 1
        return $true
    }
    
    try {
        Write-Status "Downloading FFmpeg via winget..." "CHECK"
        winget install --id Gyan.FFmpeg --source winget -e
        
        # Verify installation
        if (Get-Command ffmpeg -ErrorAction SilentlyContinue) {
            Write-Status "FFmpeg installed successfully" "OK"
            return $true
        }
    } catch {
        Write-Status "FFmpeg installation failed: $_" "ERROR"
        Write-Status "Manual install: https://ffmpeg.org/download.html" "WARN"
        return $false
    }
}

function Install-Python {
    Write-Status "Installing Python 3..." "CHECK"
    
    if (Get-Command python -ErrorAction SilentlyContinue) {
        Write-Status "Python already installed" "OK"
        python --version
        return $true
    }
    
    try {
        Write-Status "Downloading Python via winget..." "CHECK"
        winget install --id Python.Python.3.12 --source winget -e
        
        # Verify installation
        if (Get-Command python -ErrorAction SilentlyContinue) {
            Write-Status "Python installed successfully" "OK"
            return $true
        }
    } catch {
        Write-Status "Python installation failed: $_" "ERROR"
        Write-Status "Manual install: https://www.python.org/downloads/" "WARN"
        return $false
    }
}

function Install-ComfyUI {
    Write-Status "Setting up ComfyUI..." "CHECK"
    
    $comfyDir = "C:\ComfyUI"
    
    if (Test-Path "$comfyDir\main.py") {
        Write-Status "ComfyUI already installed at $comfyDir" "OK"
        return $true
    }
    
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Status "Git not found - required for ComfyUI" "ERROR"
        Write-Status "Install from: https://git-scm.com/download/win" "WARN"
        return $false
    }
    
    try {
        Write-Status "Cloning ComfyUI repository..." "CHECK"
        
        if (-not (Test-Path $comfyDir)) {
            New-Item -ItemType Directory -Path $comfyDir | Out-Null
        }
        
        git clone https://github.com/comfyanonymous/ComfyUI.git $comfyDir
        
        Write-Status "ComfyUI cloned to $comfyDir" "OK"
        Write-Status "Run: python main.py in ComfyUI directory" "WARN"
        return $true
    } catch {
        Write-Status "ComfyUI setup failed: $_" "ERROR"
        return $false
    }
}

function Install-PythonDependencies {
    Write-Status "Installing Python dependencies..." "CHECK"
    
    $requirements = @(
        "requests",
        "Pillow",
        "numpy"
    )
    
    foreach ($pkg in $requirements) {
        Write-Status "Installing $pkg..." "CHECK"
        try {
            pip install $pkg -q
            Write-Status "$pkg installed" "OK"
        } catch {
            Write-Status "Failed to install $pkg: $_" "WARN"
        }
    }
}

function Configure-EnvironmentVariables {
    Write-Status "Configuring environment variables..." "CHECK"
    
    Write-Host ""
    Write-Host "Optional API Key Configuration:" -ForegroundColor Cyan
    Write-Host ""
    
    $grokKey = Read-Host "Enter Grok API key (or press Enter to skip)"
    if (-not [string]::IsNullOrWhiteSpace($grokKey)) {
        [Environment]::SetEnvironmentVariable("XAI_API_KEY", $grokKey, "User")
        Write-Status "XAI_API_KEY configured" "OK"
    }
    
    $mjKey = Read-Host "Enter Midjourney API key (or press Enter to skip)"
    if (-not [string]::IsNullOrWhiteSpace($mjKey)) {
        [Environment]::SetEnvironmentVariable("MIDJOURNEY_API_KEY", $mjKey, "User")
        Write-Status "MIDJOURNEY_API_KEY configured" "OK"
    }
    
    Write-Host ""
    Write-Status "Environment variables saved (restart PowerShell to use)" "WARN"
}

function Run-Validation {
    Write-Status "Running validation tests..." "CHECK"
    Write-Host ""
    
    $results = @{}
    
    # Check PowerShell
    $results["PowerShell"] = if ($PSVersionTable.PSVersion.Major -ge 5) { "OK" } else { "FAIL" }
    Write-Status "PowerShell: $($PSVersionTable.PSVersion)" $results["PowerShell"]
    
    # Check FFmpeg
    $results["FFmpeg"] = if (Get-Command ffmpeg -ErrorAction SilentlyContinue) { "OK" } else { "FAIL" }
    Write-Status "FFmpeg: $(if ($results['FFmpeg'] -eq 'OK') { 'Installed' } else { 'Not Found' })" $results["FFmpeg"]
    
    # Check Python
    $results["Python"] = if (Get-Command python -ErrorAction SilentlyContinue) { "OK" } else { "FAIL" }
    Write-Status "Python: $(if ($results['Python'] -eq 'OK') { 'Installed' } else { 'Not Found' })" $results["Python"]
    
    # Check Git
    $results["Git"] = if (Get-Command git -ErrorAction SilentlyContinue) { "OK" } else { "WARN" }
    Write-Status "Git: $(if ($results['Git'] -eq 'OK') { 'Installed' } else { 'Not Installed (optional)' })" $results["Git"]
    
    Write-Host ""
    
    $allOK = $results.Values -notcontains "FAIL"
    return $allOK
}

# Main execution
Write-Host "" -ForegroundColor Cyan
Write-Host "  Video Pipeline - Prerequisites Installation                  " -ForegroundColor Cyan
Write-Host "" -ForegroundColor Cyan
Write-Host ""

# Check admin privileges
if (-not (Test-AdminPrivileges)) {
    Write-Status "Admin privileges required for installation" "ERROR"
    Write-Status "Please run: powershell -RunAs Administrator" "WARN"
    exit 1
}

Write-Status "Running with admin privileges" "OK"
Write-Host ""

# Installation steps
if (-not $SkipFFmpeg) {
    Install-FFmpeg
    Write-Host ""
}

if (-not $SkipPython) {
    Install-Python
    Write-Host ""
    Install-PythonDependencies
    Write-Host ""
}

if (-not $SkipComfyUI) {
    $installComfyUI = if ($NoPrompt) { $true } else { Read-Host "Install ComfyUI? (y/n)" -eq "y" }
    if ($installComfyUI) {
        Install-ComfyUI
        Write-Host ""
    }
}

# Configure environment
$configEnv = if ($NoPrompt) { $false } else { Read-Host "Configure API keys? (y/n)" -eq "y" }
if ($configEnv) {
    Configure-EnvironmentVariables
    Write-Host ""
}

# Run validation
$valid = Run-Validation

Write-Host ""
if ($valid) {
    Write-Status "Installation successful!" "OK"
    Write-Host "Next: Run .\orchestrator.ps1 -Mode validate" -ForegroundColor Green
} else {
    Write-Status "Some components missing. Please install manually." "WARN"
}

exit 0
