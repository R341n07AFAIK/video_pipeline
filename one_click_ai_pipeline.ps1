# one_click_ai_pipeline.ps1
# One-click automated AI video processing with all features

param(
    [string]$InputFolder = "input",
    [string]$OutputFolder = "output",
    [string]$Provider = "grok",
    [int]$TargetFPS = 30
)

Write-Host "=== One-Click AI Pipeline ==="
Write-Host "This will process all videos with:"
Write-Host "  Input Folder  : $InputFolder"
Write-Host "  Output Folder : $OutputFolder"
Write-Host "  AI Provider   : $Provider"
Write-Host "  Target FPS    : $TargetFPS"
Write-Host ""
Write-Host "Press Enter to continue or Ctrl+C to cancel..."
Read-Host

# Verify prerequisites
$missingTools = @()
if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) { $missingTools += "ffmpeg" }
if ($Provider -eq "grok" -and [string]::IsNullOrWhiteSpace($env:XAI_API_KEY)) { $missingTools += "XAI_API_KEY" }

if ($missingTools.Count -gt 0) {
    Write-Host "ERROR: Missing prerequisites: $($missingTools -join ', ')"
    exit 1
}

if (!(Test-Path $InputFolder)) {
    New-Item -ItemType Directory -Path $InputFolder | Out-Null
    Write-Host "Created input folder: $InputFolder"
    Write-Host "Place your videos here and run again."
    exit 0
}

if (!(Test-Path $OutputFolder)) {
    New-Item -ItemType Directory -Path $OutputFolder | Out-Null
}

$videos = Get-ChildItem $InputFolder -Filter "*.mp4", "*.mov", "*.mkv"
if ($videos.Count -eq 0) {
    Write-Host "No videos found in $InputFolder"
    exit 0
}

Write-Host ""
Write-Host "Processing $($videos.Count) video(s)..."

$count = 0
foreach ($video in $videos) {
    $count++
    Write-Host "[$count/$($videos.Count)] $($video.Name)"
    
    $outputFile = Join-Path $OutputFolder "$($video.BaseName)_processed.mp4"
    
    # Apply FPS conversion
    ffmpeg -i $video.FullName -r $TargetFPS -c:v libx264 -preset fast -c:a aac $outputFile
}

Write-Host ""
Write-Host "=== Processing Complete ==="
Write-Host "Output folder: $OutputFolder"
