# stitch_all_images.ps1
# Stitch multiple image sequences into a single video

param(
    [string]$SourceFolder = ".",
    [string]$Pattern = "frame_*.png",
    [string]$OutputVideo = "stitched.mp4",
    [int]$FPS = 24
)

if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: ffmpeg is not installed"
    exit 1
}

if (!(Test-Path $SourceFolder)) {
    Write-Host "ERROR: Source folder not found: $SourceFolder"
    exit 1
}

Write-Host "=== Stitching All Images ==="
Write-Host "Source      : $SourceFolder"
Write-Host "Pattern     : $Pattern"
Write-Host "Output      : $OutputVideo"
Write-Host "FPS         : $FPS"
Write-Host ""

$images = Get-ChildItem $SourceFolder -Filter $Pattern | Sort-Object Name
if ($images.Count -eq 0) {
    Write-Host "ERROR: No images found matching pattern '$Pattern'"
    exit 1
}

Write-Host "Found $($images.Count) images"

$framePattern = Join-Path $SourceFolder $Pattern
ffmpeg -y -framerate $FPS -i $framePattern -c:v libx264 -preset medium -pix_fmt yuv420p $OutputVideo

Write-Host ""
Write-Host "Stitching complete! Output: $OutputVideo"
