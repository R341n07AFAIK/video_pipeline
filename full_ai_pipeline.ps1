# full_ai_pipeline.ps1
# Complete AI-powered video processing pipeline

param(
    [string]$InputFolder = ".",
    [string]$Pattern = "*.mp4",
    [string]$OutputFolder = "output",
    [string]$AIProvider = "grok",
    [string]$Prompt = "Enhance and upscale this video"
)

Write-Host "=== Full AI Pipeline ==="
Write-Host "Input       : $InputFolder"
Write-Host "Pattern     : $Pattern"
Write-Host "Output      : $OutputFolder"
Write-Host "AI Provider : $AIProvider"
Write-Host "Prompt      : $Prompt"
Write-Host ""

if (!(Test-Path $InputFolder)) {
    Write-Host "ERROR: Input folder not found"
    exit 1
}

if (!(Test-Path $OutputFolder)) {
    New-Item -ItemType Directory -Path $OutputFolder | Out-Null
}

$videos = Get-ChildItem $InputFolder -Filter $Pattern | Sort-Object Name
if ($videos.Count -eq 0) {
    Write-Host "ERROR: No videos found"
    exit 1
}

Write-Host "Found $($videos.Count) video(s)"
Write-Host ""

$processedCount = 0
foreach ($video in $videos) {
    $processedCount++
    Write-Host "[$processedCount/$($videos.Count)] Processing: $($video.Name)"
    
    $outputFile = Join-Path $OutputFolder "$($video.BaseName)_processed.mp4"
    
    # Import and use core functions
    . ".\unified_ai_core.ps1"
    
    if (Initialize-AIEnvironment -Provider $AIProvider) {
        Process-WithAI -InputPath $video.FullName -OutputPath $outputFile -Prompt $Prompt
        Write-Host "  -> Saved: $outputFile"
    } else {
        Write-Host "  WARNING: Skipping - AI not available"
    }
}

Write-Host ""
Write-Host "=== Pipeline Complete ==="
Write-Host "Processed $processedCount video(s)"
