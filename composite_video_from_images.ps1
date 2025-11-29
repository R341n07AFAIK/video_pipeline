# composite_video_from_images.ps1
# Encode image sequences into video files using ffmpeg

param(
    [string]$FramesFolder = "frames",
    [string]$OutputVideo = "output.mp4",
    [int]$FPS = 24,
    [string]$Codec = "libx264",
    [string]$Preset = "medium"
)

if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: ffmpeg is not installed. Install with: winget install --id Gyan.FFmpeg --source winget"
    exit 1
}

if (!(Test-Path $FramesFolder)) {
    Write-Host "ERROR: Frames folder not found: $FramesFolder"
    exit 1
}

Write-Host "=== Encoding Frames to Video ==="
Write-Host "Input       : $FramesFolder"
Write-Host "Output      : $OutputVideo"
Write-Host "FPS         : $FPS"
Write-Host "Codec       : $Codec"
Write-Host "Preset      : $Preset"
Write-Host ""

$framePattern = Join-Path $FramesFolder "frame_%06d.png"
ffmpeg -y -framerate $FPS -i $framePattern -c:v $Codec -preset $Preset -pix_fmt yuv420p $OutputVideo

if (Test-Path $OutputVideo) {
    $fileSizeMB = [math]::Round((Get-Item $OutputVideo).Length / 1MB, 2)
    Write-Host ""
    Write-Host "Video encoding complete!"
    Write-Host "Output file: $OutputVideo ($fileSizeMB MB)"
} else {
    Write-Host "ERROR: Failed to create output video"
    exit 1
}
