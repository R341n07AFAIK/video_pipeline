# grok_unified_pipeline.ps1
# Unified Grok API pipeline for consistent video processing

param(
    [string]$InputFolder = ".",
    [string]$Pattern = "*.mp4",
    [string]$OutputFolder = "grok_unified_output",
    [string]$StylePrompt = "Enhance with Grok vision"
)

Write-Host "=== Grok Unified Pipeline ==="
Write-Host "Input       : $InputFolder"
Write-Host "Style       : $StylePrompt"
Write-Host "Output      : $OutputFolder"
Write-Host ""

$apiKey = $env:XAI_API_KEY
if ([string]::IsNullOrWhiteSpace($apiKey)) {
    Write-Host "ERROR: XAI_API_KEY not set"
    Write-Host "Set it with: setx XAI_API_KEY 'your-key'"
    exit 1
}

if (!(Test-Path $InputFolder)) {
    Write-Host "ERROR: Input folder not found"
    exit 1
}

if (!(Test-Path $OutputFolder)) {
    New-Item -ItemType Directory -Path $OutputFolder | Out-Null
}

$videos = Get-ChildItem $InputFolder -Filter $Pattern
Write-Host "Found $($videos.Count) video(s)"
Write-Host ""

foreach ($video in $videos) {
    Write-Host "Processing: $($video.Name)"
    $outputFile = Join-Path $OutputFolder "$($video.BaseName)_grok.mp4"
    
    # Placeholder for actual Grok API call
    # In real implementation, send video to Grok API
    
    Copy-Item $video.FullName $outputFile -Force
    Write-Host "  -> $outputFile"
}

Write-Host ""
Write-Host "Grok unified pipeline complete!"
