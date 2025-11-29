<#
.SYNOPSIS
Batch processing example for video pipeline

.DESCRIPTION
Example script demonstrating batch processing of multiple videos
with progress tracking, error handling, and result logging.

.PARAMETER InputDirectory
Directory containing videos to process

.PARAMETER OutputDirectory
Directory to save processed videos

.PARAMETER Provider
AI provider to use (grok, midjourney, comfyui)

.EXAMPLE
.\batch_process_example.ps1 -InputDirectory C:\videos -Provider comfyui
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$InputDirectory,
    
    [Parameter(Mandatory=$false)]
    [string]$OutputDirectory = "./output",
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("grok", "midjourney", "comfyui")]
    [string]$Provider = "comfyui"
)

# Configuration
$config = @{
    InputDir = $InputDirectory
    OutputDir = $OutputDirectory
    Provider = $Provider
    VideoExtensions = @(".mp4", ".avi", ".mov", ".mkv", ".webm")
    MaxParallelJobs = 2
    RetryCount = 3
    LogFile = "logs/batch_process_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
}

# Setup logging
New-Item -ItemType Directory -Path (Split-Path $config.LogFile) -Force | Out-Null

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    Write-Host $logMessage
    Add-Content -Path $config.LogFile -Value $logMessage
}

function Get-VideoFiles {
    param([string]$Directory)
    
    Write-Log "Scanning directory: $Directory"
    
    $videos = Get-ChildItem -Path $Directory -Recurse -File | 
              Where-Object { $_.Extension -in $config.VideoExtensions }
    
    Write-Log "Found $($videos.Count) video files"
    return $videos
}

function Process-Video {
    param(
        [object]$VideoFile,
        [int]$Index,
        [int]$Total
    )
    
    $outputFile = Join-Path $config.OutputDir $($VideoFile.BaseName + "_processed.mp4")
    
    Write-Log "[$Index/$Total] Processing: $($VideoFile.Name)" "INFO"
    
    try {
        # Call orchestrator
        $params = @(
            "-InputFile", $VideoFile.FullName,
            "-OutputFile", $outputFile,
            "-Provider", $config.Provider,
            "-Verbose"
        )
        
        # Run orchestrator
        & ".\orchestrator.ps1" @params
        
        if (Test-Path $outputFile) {
            $outputSize = (Get-Item $outputFile).Length / 1MB
            Write-Log "[$Index/$Total] Complete: $($VideoFile.Name) -> $([math]::Round($outputSize, 2))MB" "SUCCESS"
            return $true
        }
        else {
            Write-Log "[$Index/$Total] Failed: Output file not created" "ERROR"
            return $false
        }
    }
    catch {
        Write-Log "[$Index/$Total] Error processing $($VideoFile.Name): $_" "ERROR"
        return $false
    }
}

function Process-BatchWithRetry {
    param([object]$VideoFile, [int]$Index, [int]$Total)
    
    $attempt = 0
    $success = $false
    
    while ($attempt -lt $config.RetryCount -and -not $success) {
        $attempt++
        Write-Log "Attempt $attempt/$($config.RetryCount) for $($VideoFile.Name)"
        
        $success = Process-Video -VideoFile $VideoFile -Index $Index -Total $Total
        
        if (-not $success -and $attempt -lt $config.RetryCount) {
            $delay = 5 * $attempt  # Exponential backoff
            Write-Log "Retrying in $delay seconds..."
            Start-Sleep -Seconds $delay
        }
    }
    
    return $success
}

# Main script
Write-Host "╔════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║     BATCH VIDEO PROCESSING EXAMPLE                ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

Write-Log "Batch processing started"
Write-Log "Configuration:"
Write-Log "  Input Directory: $($config.InputDir)"
Write-Log "  Output Directory: $($config.OutputDir)"
Write-Log "  Provider: $($config.Provider)"

# Validate input directory
if (-not (Test-Path $config.InputDir)) {
    Write-Log "Input directory not found: $($config.InputDir)" "ERROR"
    exit 1
}

# Create output directory
New-Item -ItemType Directory -Path $config.OutputDir -Force | Out-Null

# Get video files
$videos = Get-VideoFiles -Directory $config.InputDir

if ($videos.Count -eq 0) {
    Write-Log "No video files found" "WARN"
    exit 0
}

# Process videos
Write-Host ""
Write-Host "Processing $($videos.Count) videos with provider: $($config.Provider)" -ForegroundColor Yellow
Write-Host ""

$successCount = 0
$failCount = 0
$startTime = Get-Date

$videos | ForEach-Object -Parallel {
    $videoFile = $_
    $index = $_.PSParentPath | Select-Object -Last 1  # Placeholder for index
    
    # Note: Full implementation would include proper indexing across parallel jobs
    # This is a simplified example
    
    $result = Process-BatchWithRetry -VideoFile $videoFile -Index 1 -Total $videos.Count
    
    if ($result) { $successCount++ }
    else { $failCount++ }
    
} -ThrottleLimit $config.MaxParallelJobs

$endTime = Get-Date
$duration = ($endTime - $startTime).TotalSeconds

# Summary
Write-Host ""
Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "BATCH PROCESSING SUMMARY" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "Total Videos: $($videos.Count)"
Write-Host "Successful: $successCount" -ForegroundColor Green
Write-Host "Failed: $failCount" -ForegroundColor $(if ($failCount -eq 0) { "Green" } else { "Red" })
Write-Host "Duration: $([math]::Round($duration, 2))s"
Write-Host "Log File: $($config.LogFile)"
Write-Host ""

Write-Log "Batch processing completed"
Write-Log "Results: $successCount succeeded, $failCount failed"

exit if ($failCount -gt 0) { 1 } else { 0 }
