<#
.SYNOPSIS
Test suite for orchestrator.ps1

.DESCRIPTION
Comprehensive tests for the video pipeline orchestrator component.
Tests prerequisite validation, configuration loading, and provider detection.

.NOTES
Run with: powershell -File test_orchestrator.ps1
#>

param(
    [switch]$Verbose = $false,
    [string]$LogPath = "logs/test_orchestrator.log"
)

# Test configuration
$testConfig = @{
    InputDir = "test_input"
    OutputDir = "test_output"
    LogFile = $LogPath
    Verbose = $Verbose
}

# Color output
function Write-TestResult {
    param([string]$Test, [bool]$Passed, [string]$Details)
    
    $status = if ($Passed) { "✓ PASS" } else { "✗ FAIL" }
    $color = if ($Passed) { "Green" } else { "Red" }
    Write-Host "$status : $Test" -ForegroundColor $color
    if ($Details) { Write-Host "        $Details" -ForegroundColor Gray }
}

function Write-TestSection {
    param([string]$Section)
    Write-Host ""
    Write-Host "=== $Section ===" -ForegroundColor Cyan
}

# Test cases
Write-Host "VIDEO PIPELINE TEST SUITE" -ForegroundColor Yellow
Write-Host "Started: $(Get-Date)" -ForegroundColor Gray
Write-Host ""

$passCount = 0
$failCount = 0

# Test 1: FFmpeg availability
Write-TestSection "Prerequisite Tests"

$ffmpegAvailable = $null -ne (Get-Command ffmpeg -ErrorAction SilentlyContinue)
Write-TestResult "FFmpeg Available" $ffmpegAvailable
if ($ffmpegAvailable) { $passCount++ } else { $failCount++ }

if ($ffmpegAvailable) {
    $ffmpegVersion = (ffmpeg -version 2>&1 | Select-Object -First 1)
    Write-Host "  Version: $ffmpegVersion" -ForegroundColor DarkGray
}

# Test 2: Python availability
$pythonAvailable = $null -ne (Get-Command python -ErrorAction SilentlyContinue)
Write-TestResult "Python Available" $pythonAvailable
if ($pythonAvailable) { $passCount++ } else { $failCount++ }

if ($pythonAvailable) {
    $pythonVersion = (python --version 2>&1)
    Write-Host "  Version: $pythonVersion" -ForegroundColor DarkGray
}

# Test 3: Configuration file
Write-TestSection "Configuration Tests"

$configExists = Test-Path "pipeline.config.json"
Write-TestResult "Config File Exists" $configExists
if ($configExists) { $passCount++ } else { $failCount++ }

if ($configExists) {
    try {
        $config = Get-Content pipeline.config.json | ConvertFrom-Json
        Write-TestResult "Config Valid JSON" $true
        $passCount++
    }
    catch {
        Write-TestResult "Config Valid JSON" $false "Parse error: $_"
        $failCount++
    }
}

# Test 4: Directory structure
Write-TestSection "Directory Structure Tests"

$dirs = @("input", "output", "logs", "temp")
foreach ($dir in $dirs) {
    $exists = Test-Path $dir
    Write-TestResult "Directory: $dir" $exists
    if ($exists) { $passCount++ } else { $failCount++ }
}

# Test 5: Required modules
Write-TestSection "Module Tests"

$modules = @("ffmpeg-utils.ps1", "unified_ai_core.ps1", "orchestrator.ps1")
foreach ($module in $modules) {
    $exists = Test-Path $module
    Write-TestResult "Module: $module" $exists
    if ($exists) { $passCount++ } else { $failCount++ }
}

# Test 6: Python modules
Write-TestSection "Python Module Tests"

if ($pythonAvailable) {
    $pythonModules = @("requests", "PIL", "numpy")
    foreach ($pymod in $pythonModules) {
        try {
            python -c "import $pymod" 2>$null
            Write-TestResult "Python Module: $pymod" $true
            $passCount++
        }
        catch {
            Write-TestResult "Python Module: $pymod" $false
            $failCount++
        }
    }
}

# Test 7: API configuration
Write-TestSection "API Configuration Tests"

$apiKeys = @("XAI_API_KEY", "MIDJOURNEY_API_KEY")
foreach ($key in $apiKeys) {
    $keySet = $null -ne [System.Environment]::GetEnvironmentVariable($key)
    Write-TestResult "API Key: $key" $keySet "$(if ($keySet) { 'configured' } else { 'not configured' })"
    if ($keySet) { $passCount++ } else { $failCount++ }
}

# Test 8: Provider detection
Write-TestSection "Provider Detection Tests"

if (Test-Path "providers/process-grok.ps1") {
    Write-TestResult "Grok Provider" $true
    $passCount++
}

if (Test-Path "providers/process-comfyui.ps1") {
    Write-TestResult "ComfyUI Provider" $true
    $passCount++
}

if (Test-Path "providers/process-midjourney.ps1") {
    Write-TestResult "Midjourney Provider" $true
    $passCount++
}

# Test 9: Logging capability
Write-TestSection "Logging Tests"

try {
    $testLog = "logs/test_$(Get-Random).log"
    "Test log entry" | Out-File -FilePath $testLog -Encoding UTF8
    $logExists = Test-Path $testLog
    Write-TestResult "Log File Creation" $logExists
    if ($logExists) { 
        Remove-Item $testLog
        $passCount++ 
    } else { 
        $failCount++ 
    }
}
catch {
    Write-TestResult "Log File Creation" $false $_
    $failCount++
}

# Test 10: PowerShell version
Write-TestSection "Environment Tests"

$psVersion = $PSVersionTable.PSVersion.Major
$psVersionOk = $psVersion -ge 5
Write-TestResult "PowerShell 5.0+" $psVersionOk "Version: $psVersion.$($PSVersionTable.PSVersion.Minor)"
if ($psVersionOk) { $passCount++ } else { $failCount++ }

# Test 11: Disk space
$diskFree = (Get-PSDrive C).Free / 1GB
$diskOk = $diskFree -gt 5
Write-TestResult "Disk Space (>5GB)" $diskOk "Available: $([math]::Round($diskFree, 2)) GB"
if ($diskOk) { $passCount++ } else { $failCount++ }

# Test 12: Network connectivity
Write-TestSection "Network Tests"

try {
    $testConnection = Test-NetConnection -ComputerName "api.x.ai" -Port 443 -WarningAction SilentlyContinue
    $netOk = $testConnection.TcpTestSucceeded
    Write-TestResult "Network Connectivity" $netOk "xAI API endpoint"
    if ($netOk) { $passCount++ } else { $failCount++ }
}
catch {
    Write-TestResult "Network Connectivity" $false
    $failCount++
}

# Summary
Write-Host ""
Write-Host "=== TEST SUMMARY ===" -ForegroundColor Cyan
$total = $passCount + $failCount
$percentage = if ($total -gt 0) { [math]::Round(($passCount / $total) * 100, 1) } else { 0 }
Write-Host "Passed:  $passCount/$total ($percentage%)" -ForegroundColor Green
Write-Host "Failed:  $failCount/$total" -ForegroundColor $(if ($failCount -eq 0) { "Green" } else { "Red" })
Write-Host "Status:  $(if ($failCount -eq 0) { 'ALL TESTS PASSED ✓' } else { 'SOME TESTS FAILED ✗' })" -ForegroundColor $(if ($failCount -eq 0) { "Green" } else { "Red" })
Write-Host ""
Write-Host "Completed: $(Get-Date)" -ForegroundColor Gray

exit if ($failCount -gt 0) { 1 } else { 0 }
