# orchestrator.ps1
# Master orchestration script for the entire video pipeline
# Coordinates PowerShell, ffmpeg, Python, and API integrations

param(
    [string]$Config = "pipeline.config.json",
    [string]$InputFolder = "input",
    [string]$OutputFolder = "output",
    [string]$Mode = "process",
    [string[]]$Providers = @("grok")
)

$ErrorActionPreference = "Stop"

# ===== CONFIGURATION & CONSTANTS =====
$SCRIPT_VERSION = "1.0"
$LOG_FILE = "pipeline_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    Write-Host $logMessage
    Add-Content $LOG_FILE $logMessage -ErrorAction SilentlyContinue
}

function Test-Prerequisites {
    Write-Log "Testing prerequisites..." "CHECK"
    
    $missing = @()
    
    # Check ffmpeg
    if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
        $missing += "ffmpeg"
    } else {
        Write-Log "   ffmpeg available"
    }
    
    # Check Python
    if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
        $missing += "python"
    } else {
        Write-Log "   Python 3 available"
    }
    
    # Check API keys for providers
    foreach ($provider in $Providers) {
        $envVarName = "$($provider.ToUpper())_API_KEY"
        $envVar = Get-ChildItem "Env:$envVarName" -ErrorAction SilentlyContinue
        
        if ([string]::IsNullOrWhiteSpace($envVar.Value)) {
            Write-Log "   $provider API key not set (optional)" "WARN"
        } else {
            Write-Log "   $provider API key configured"
        }
    }
    
    if ($missing.Count -gt 0) {
        Write-Log "ERROR: Missing prerequisites: $($missing -join ', ')" "ERROR"
        return $false
    }
    
    return $true
}

function Load-Config {
    param([string]$ConfigPath)
    
    if (-not (Test-Path $ConfigPath)) {
        Write-Log "Config file not found, using defaults" "WARN"
        return @{
            fps = 24
            codec = "libx264"
            preset = "medium"
            quality = 23
        }
    }
    
    try {
        $config = Get-Content $ConfigPath | ConvertFrom-Json
        Write-Log "Config loaded from: $ConfigPath"
        return $config
    } catch {
        Write-Log "Failed to parse config: $_" "ERROR"
        return @{}
    }
}

function Initialize-Directories {
    Write-Log "Initializing directories..." "CHECK"
    
    foreach ($dir in @($InputFolder, $OutputFolder, "logs", "temp")) {
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir | Out-Null
            Write-Log "  Created: $dir"
        }
    }
}

function Process-Videos {
    param(
        [string]$InputPath,
        [string]$OutputPath,
        [hashtable]$Config,
        [string[]]$Providers
    )
    
    Write-Log "Starting video processing..." "START"
    Write-Log "Input: $InputPath" "INFO"
    Write-Log "Output: $OutputPath" "INFO"
    Write-Log "Providers: $($Providers -join ', ')" "INFO"
    
    $videos = Get-ChildItem $InputPath -Include "*.mp4", "*.mov", "*.mkv" -ErrorAction SilentlyContinue
    
    if ($videos.Count -eq 0) {
        Write-Log "No videos found in $InputPath" "WARN"
        return 0
    }
    
    Write-Log "Found $($videos.Count) video(s) to process"
    
    $processedCount = 0
    foreach ($video in $videos) {
        $processedCount++
        Write-Log "[$processedCount/$($videos.Count)] Processing: $($video.Name)" "PROC"
        
        $baseName = $video.BaseName
        $outputFile = Join-Path $OutputPath "$baseName.processed.mp4"
        
        # Process with each provider
        foreach ($provider in $Providers) {
            Write-Log "  Using provider: $provider" "PROC"
            
            $providerOutput = Join-Path $OutputPath "$baseName.$provider.mp4"
            
            # Call provider-specific processing
            & ".\providers\process-$provider.ps1" -InputFile $video.FullName -OutputFile $providerOutput -Config $Config
            
            if ($LASTEXITCODE -eq 0) {
                Write-Log "   $provider processed successfully"
            } else {
                Write-Log "   $provider processing failed" "WARN"
            }
        }
    }
    
    Write-Log "Processing complete: $processedCount video(s)" "END"
    return $processedCount
}

function Generate-Report {
    param(
        [int]$ProcessedCount,
        [string]$OutputFolder
    )
    
    Write-Log "Generating report..." "CHECK"
    
    $reportFile = Join-Path $OutputFolder "processing_report.txt"
    
    $outputCount = (Get-ChildItem $OutputFolder -Filter "*.mp4" | Measure-Object).Count
    $totalSize = (Get-ChildItem $OutputFolder -Filter "*.mp4" | Measure-Object -Sum Length).Sum
    $totalSizeMB = [math]::Round($totalSize / 1MB, 2)
    
    $report = @"
=== Video Pipeline Processing Report ===
Generated: $(Get-Date)
PowerShell Version: $($PSVersionTable.PSVersion.Major).$($PSVersionTable.PSVersion.Minor)
Log File: $LOG_FILE

Processing Summary:
  Videos Processed: $ProcessedCount
  Output Files: $outputCount
  Total Output Size: $totalSizeMB MB
  
Output Location: $OutputFolder

Log: $LOG_FILE
"@
    
    $report | Set-Content $reportFile
    Write-Log "Report saved to: $reportFile"
}

# ===== MAIN EXECUTION =====
Write-Log "=== Video Pipeline Orchestrator v$SCRIPT_VERSION ===" "INIT"
Write-Log "Mode: $Mode"

if (-not (Test-Prerequisites)) {
    exit 1
}

Initialize-Directories
$config = Load-Config $Config

switch ($Mode) {
    "process" {
        $count = Process-Videos -InputPath $InputFolder -OutputPath $OutputFolder -Config $config -Providers $Providers
        Generate-Report -ProcessedCount $count -OutputFolder $OutputFolder
    }
    "validate" {
        Write-Log "Validation mode - checking pipeline integrity"
        if (Test-Prerequisites) {
            Write-Log " All prerequisites satisfied"
        }
    }
    default {
        Write-Log "Unknown mode: $Mode" "ERROR"
        exit 1
    }
}

Write-Log "=== Pipeline Execution Complete ===" "DONE"
