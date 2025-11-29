# extract_frames.ps1
# Extract individual frames from video files using ffmpeg
# Supports .mp4, .mov, .mkv, and other video formats

param(
    [string]$VideoPath = "",
    [string]$OutputFolder = "frames",
    [int]$FPS = 24,
    [string]$Format = "png"
)

if ([string]::IsNullOrWhiteSpace($VideoPath)) {
    Write-Host "Usage: powershell -File extract_frames.ps1 -VideoPath 'video.mp4' -OutputFolder 'frames' -FPS 24 -Format 'png'"
    exit 1
}

if (!(Test-Path $VideoPath)) {
    Write-Host "ERROR: Video file not found: $VideoPath"
    exit 1
}

if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: ffmpeg is not installed. Install with: winget install --id Gyan.FFmpeg --source winget"
    exit 1
}

if (!(Test-Path $OutputFolder)) {
    New-Item -ItemType Directory -Path $OutputFolder | Out-Null
}

Write-Host "=== Extracting Frames ==="
Write-Host "Video       : $VideoPath"
Write-Host "Output      : $OutputFolder"
Write-Host "FPS         : $FPS"
Write-Host "Format      : $Format"
Write-Host ""

$framePattern = Join-Path $OutputFolder "frame_%06d.$Format"
ffmpeg -i $VideoPath -vf "fps=$FPS" $framePattern

Write-Host ""
Write-Host "Frame extraction complete!"
$frameCount = (Get-ChildItem $OutputFolder -Filter "frame_*" | Measure-Object).Count
Write-Host "Total frames extracted: $frameCount"
