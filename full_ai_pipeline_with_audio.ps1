# full_ai_pipeline_with_audio.ps1
# AI pipeline that preserves and processes audio

param(
    [string]$InputFolder = ".",
    [string]$Pattern = "*.mp4",
    [string]$OutputFolder = "output_audio",
    [string]$AudioMode = "preserve"
)

Write-Host "=== Full AI Pipeline with Audio ==="
Write-Host "Input       : $InputFolder"
Write-Host "Audio Mode  : $AudioMode (preserve/enhance/remove)"
Write-Host "Output      : $OutputFolder"
Write-Host ""

if (!(Test-Path $InputFolder)) {
    Write-Host "ERROR: Input folder not found"
    exit 1
}

if (!(Test-Path $OutputFolder)) {
    New-Item -ItemType Directory -Path $OutputFolder | Out-Null
}

if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: ffmpeg required"
    exit 1
}

$videos = Get-ChildItem $InputFolder -Filter $Pattern
foreach ($video in $videos) {
    Write-Host "Processing: $($video.Name)"
    $outputFile = Join-Path $OutputFolder "$($video.BaseName)_audio.mp4"
    
    switch ($AudioMode) {
        "preserve" {
            ffmpeg -i $video.FullName -c:v libx264 -preset fast -c:a aac -b:a 192k $outputFile
        }
        "enhance" {
            ffmpeg -i $video.FullName -c:v libx264 -preset fast -af "volume=1.5" -c:a aac -b:a 192k $outputFile
        }
        "remove" {
            ffmpeg -i $video.FullName -c:v libx264 -preset fast -an $outputFile
        }
        default {
            Write-Host "Unknown audio mode: $AudioMode"
        }
    }
}

Write-Host ""
Write-Host "Audio processing complete!"
