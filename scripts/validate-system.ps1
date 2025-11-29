<#
.SYNOPSIS
System validation and diagnostic script

.DESCRIPTION
Comprehensive system validation covering:
- FFmpeg availability and capabilities
- Python and required packages
- API key configuration
- Disk space and permissions
- Network connectivity
- Provider availability

.PARAMETER Verbose
Enable verbose output

.EXAMPLE
.\validate-system.ps1 -Verbose
#>

param([switch]$Verbose = $false)

$ErrorActionPreference = "SilentlyContinue"

Write-Host "╔════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║        SYSTEM VALIDATION & DIAGNOSTICS                ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
Write-Host "Started: $timestamp" -ForegroundColor Gray
Write-Host ""

$results = @{
    Passed = 0
    Failed = 0
    Warnings = 0
}

function Test-Component {
    param(
        [string]$Name,
        [scriptblock]$Test,
        [string]$Severity = "ERROR"  # ERROR, WARN, INFO
    )
    
    $result = & $Test
    
    if ($result.Success) {
        Write-Host "✓ $Name" -ForegroundColor Green
        if ($result.Details) {
            Write-Host "  → $($result.Details)" -ForegroundColor DarkGray
        }
        $results.Passed++
    }
    else {
        $color = if ($Severity -eq "WARN") { "Yellow" } else { "Red" }
        $icon = if ($Severity -eq "WARN") { "⚠" } else { "✗" }
        Write-Host "$icon $Name" -ForegroundColor $color
        if ($result.Details) {
            Write-Host "  → $($result.Details)" -ForegroundColor DarkGray
        }
        
        if ($Severity -eq "WARN") {
            $results.Warnings++
        }
        else {
            $results.Failed++
        }
    }
}

# === ENVIRONMENT ===
Write-Host "ENVIRONMENT" -ForegroundColor Yellow
Write-Host "───────────────────────────────────────────────────────" -ForegroundColor DarkGray

Test-Component "Operating System" {
    $os = [System.Environment]::OSVersion
    if ($os.Platform -eq "Win32NT" -and $os.Version.Major -ge 10) {
        @{ Success = $true; Details = "$($os.VersionString)" }
    }
    else {
        @{ Success = $false; Details = "Windows 10+ required" }
    }
}

Test-Component "PowerShell Version" {
    $psVersion = $PSVersionTable.PSVersion
    if ($psVersion.Major -ge 5) {
        @{ Success = $true; Details = "$($psVersion.Major).$($psVersion.Minor)" }
    }
    else {
        @{ Success = $false; Details = "PowerShell 5.0+ required (have: $($psVersion.Major))" }
    }
}

# === FFMPEG ===
Write-Host ""
Write-Host "FFMPEG" -ForegroundColor Yellow
Write-Host "───────────────────────────────────────────────────────" -ForegroundColor DarkGray

Test-Component "FFmpeg Installed" {
    $ffmpeg = Get-Command ffmpeg -ErrorAction SilentlyContinue
    if ($ffmpeg) {
        @{ Success = $true; Details = $ffmpeg.Source }
    }
    else {
        @{ Success = $false; Details = "ffmpeg command not found in PATH" }
    }
}

if ($null -ne (Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
    Test-Component "FFmpeg Version" {
        $version = (ffmpeg -version 2>&1 | Select-Object -First 1)
        if ($version -match "N-") {
            @{ Success = $true; Details = $version.Trim() }
        }
        else {
            @{ Success = $false; Details = "Unable to determine version" }
        }
    }
    
    Test-Component "FFmpeg Codecs" {
        $codecs = @("h264", "hevc", "libx264", "libx265")
        $available = @()
        
        foreach ($codec in $codecs) {
            $check = ffmpeg -codecs 2>&1 | Select-String $codec
            if ($check) { $available += $codec }
        }
        
        if ($available.Count -ge 2) {
            @{ Success = $true; Details = "Found: $($available -join ', ')" }
        }
        else {
            @{ Success = $false; Details = "Insufficient codecs available" }
        }
    }
    
    Test-Component "FFmpeg GPU Support" {
        $gpuSupport = @("cuda", "dxva2", "qsv", "nvenc")
        $available = @()
        
        $ffmpegHelp = ffmpeg -h encoder=h264_nvenc 2>&1
        
        if ($ffmpegHelp -match "Unknown encoder") {
            @{ Success = $false; Details = "No GPU acceleration detected"; Severity = "WARN" }
        }
        else {
            @{ Success = $true; Details = "GPU acceleration available" }
        }
    }
}

# === PYTHON ===
Write-Host ""
Write-Host "PYTHON" -ForegroundColor Yellow
Write-Host "───────────────────────────────────────────────────────" -ForegroundColor DarkGray

Test-Component "Python Installed" {
    $python = Get-Command python -ErrorAction SilentlyContinue
    if ($python) {
        @{ Success = $true; Details = $python.Source }
    }
    else {
        @{ Success = $false; Details = "python command not found in PATH" }
    }
}

if ($null -ne (Get-Command python -ErrorAction SilentlyContinue)) {
    Test-Component "Python Version" {
        $version = python --version 2>&1
        if ($version -match "3\.1[0-9]") {
            @{ Success = $true; Details = $version }
        }
        else {
            @{ Success = $false; Details = "Python 3.10+ required" }
        }
    }
    
    $pythonModules = @("requests", "PIL", "numpy", "cv2")
    foreach ($module in $pythonModules) {
        $displayName = if ($module -eq "PIL") { "Pillow" } else { $module }
        Test-Component "Python Module: $displayName" {
            python -c "import $module" 2>$null
            if ($LASTEXITCODE -eq 0) {
                @{ Success = $true }
            }
            else {
                @{ Success = $false; Details = "Install with: pip install $module"; Severity = "WARN" }
            }
        } -Severity "WARN"
    }
}

# === DISK ===
Write-Host ""
Write-Host "DISK & STORAGE" -ForegroundColor Yellow
Write-Host "───────────────────────────────────────────────────────" -ForegroundColor DarkGray

Test-Component "Disk Space (>10GB)" {
    $drive = Get-PSDrive C
    $freeGB = $drive.Free / 1GB
    
    if ($freeGB -gt 10) {
        @{ Success = $true; Details = "$([math]::Round($freeGB, 2)) GB available" }
    }
    else {
        @{ Success = $false; Details = "Only $([math]::Round($freeGB, 2)) GB available (10 GB required)" }
    }
} -Severity "WARN"

Test-Component "Directories Writable" {
    $dirs = @(".", "logs", "temp", "output")
    $writable = $true
    $failed = @()
    
    foreach ($dir in $dirs) {
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
        
        $testFile = Join-Path $dir ".write_test"
        try {
            "test" | Out-File -FilePath $testFile -Force -ErrorAction Stop
            Remove-Item $testFile -Force
        }
        catch {
            $writable = $false
            $failed += $dir
        }
    }
    
    if ($writable) {
        @{ Success = $true; Details = "All directories writable" }
    }
    else {
        @{ Success = $false; Details = "Cannot write to: $($failed -join ', ')" }
    }
}

# === NETWORK ===
Write-Host ""
Write-Host "NETWORK & CONNECTIVITY" -ForegroundColor Yellow
Write-Host "───────────────────────────────────────────────────────" -ForegroundColor DarkGray

Test-Component "Internet Connectivity" {
    try {
        $test = Test-NetConnection -ComputerName 8.8.8.8 -WarningAction SilentlyContinue -InformationLevel Quiet
        if ($test) {
            @{ Success = $true; Details = "Internet available" }
        }
        else {
            @{ Success = $false; Details = "No internet connection"; Severity = "WARN" }
        }
    }
    catch {
        @{ Success = $false; Details = "Network test failed"; Severity = "WARN" }
    }
} -Severity "WARN"

$providers = @(
    @{ Name = "Grok (xAI)"; Host = "api.x.ai"; Port = 443 },
    @{ Name = "Midjourney"; Host = "api.midjourney.com"; Port = 443 },
    @{ Name = "ComfyUI"; Host = "127.0.0.1"; Port = 8188 }
)

foreach ($provider in $providers) {
    Test-Component "$($provider.Name) Reachable" {
        try {
            $test = Test-NetConnection -ComputerName $provider.Host -Port $provider.Port -WarningAction SilentlyContinue
            if ($test.TcpTestSucceeded) {
                @{ Success = $true; Details = "$($provider.Host):$($provider.Port)" }
            }
            else {
                @{ Success = $false; Details = "Connection refused"; Severity = "WARN" }
            }
        }
        catch {
            @{ Success = $false; Details = "Test failed"; Severity = "WARN" }
        }
    } -Severity "WARN"
}

# === CONFIGURATION ===
Write-Host ""
Write-Host "CONFIGURATION" -ForegroundColor Yellow
Write-Host "───────────────────────────────────────────────────────" -ForegroundColor DarkGray

Test-Component "Config File Present" {
    if (Test-Path "pipeline.config.json") {
        @{ Success = $true; Details = "pipeline.config.json found" }
    }
    else {
        @{ Success = $false; Details = "Missing pipeline.config.json" }
    }
}

if (Test-Path "pipeline.config.json") {
    Test-Component "Config Valid JSON" {
        try {
            $config = Get-Content pipeline.config.json | ConvertFrom-Json
            @{ Success = $true; Details = "Configuration valid" }
        }
        catch {
            @{ Success = $false; Details = "JSON parse error: $_" }
        }
    }
}

# === API KEYS ===
Write-Host ""
Write-Host "API KEYS" -ForegroundColor Yellow
Write-Host "───────────────────────────────────────────────────────" -ForegroundColor DarkGray

$apiKeys = @(
    @{ Name = "XAI_API_KEY"; Provider = "Grok"; Severity = "WARN" },
    @{ Name = "MIDJOURNEY_API_KEY"; Provider = "Midjourney"; Severity = "WARN" },
    @{ Name = "ANTHROPIC_API_KEY"; Provider = "Claude"; Severity = "WARN" }
)

foreach ($apiKey in $apiKeys) {
    Test-Component "$($apiKey.Provider) API Key" {
        $key = $env:$($apiKey.Name)
        if ($key) {
            $masked = $key.Substring(0, [Math]::Min(10, $key.Length)) + "***"
            @{ Success = $true; Details = "Configured ($masked)" }
        }
        else {
            @{ Success = $false; Details = "Not set (optional)"; Severity = $apiKey.Severity }
        }
    } -Severity $apiKey.Severity
}

# === PERMISSIONS ===
Write-Host ""
Write-Host "PERMISSIONS & PRIVILEGES" -ForegroundColor Yellow
Write-Host "───────────────────────────────────────────────────────" -ForegroundColor DarkGray

Test-Component "Admin Privileges Available" {
    try {
        $admin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        if ($admin) {
            @{ Success = $true; Details = "Running as administrator" }
        }
        else {
            @{ Success = $false; Details = "Not running as administrator"; Severity = "WARN" }
        }
    }
    catch {
        @{ Success = $false; Details = "Unable to determine"; Severity = "WARN" }
    }
} -Severity "WARN"

# === SUMMARY ===
Write-Host ""
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "VALIDATION SUMMARY" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan

$total = $results.Passed + $results.Failed + $results.Warnings
$percentage = if ($total -gt 0) { [math]::Round(($results.Passed / $total) * 100, 1) } else { 0 }

Write-Host ""
Write-Host "Passed:   $($results.Passed)/$total ($percentage%)" -ForegroundColor Green
Write-Host "Warnings: $($results.Warnings)/$total" -ForegroundColor $(if ($results.Warnings -eq 0) { "Green" } else { "Yellow" })
Write-Host "Failed:   $($results.Failed)/$total" -ForegroundColor $(if ($results.Failed -eq 0) { "Green" } else { "Red" })

Write-Host ""

if ($results.Failed -eq 0) {
    Write-Host "✓ System is READY for video processing" -ForegroundColor Green
    $exitCode = 0
}
else {
    Write-Host "✗ System has CRITICAL ISSUES that must be resolved" -ForegroundColor Red
    $exitCode = 1
}

if ($results.Warnings -gt 0) {
    Write-Host "⚠ Address warnings for optimal performance" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Completed: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray

exit $exitCode
