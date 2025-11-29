# composite_images_pipeline.ps1
# End-to-end pipeline: extract frames, process, and re-encode into video

param(
    [string]$VideoPath = "",
    [string]$OutputVideo = "output.mp4",
    [int]$FPS = 24
)

if ([string]::IsNullOrWhiteSpace($VideoPath)) {
    Write-Host "Usage: powershell -File composite_images_pipeline.ps1 -VideoPath 'input.mp4' -OutputVideo 'output.mp4' -FPS 24"
    exit 1
}

if (!(Test-Path $VideoPath)) {
    Write-Host "ERROR: Video file not found: $VideoPath"
    exit 1
}

Write-Host "=== Composite Images Pipeline ==="
Write-Host "Input       : $VideoPath"
Write-Host "Output      : $OutputVideo"
Write-Host "FPS         : $FPS"
Write-Host ""

# Step 1: Extract frames
$framesDir = "frames_temp"
Write-Host "[1/3] Extracting frames..."
& ".\extract_frames.ps1" -VideoPath $VideoPath -OutputFolder $framesDir -FPS $FPS

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Frame extraction failed"
    exit 1
}

# Step 2: Composite frames to video
Write-Host ""
Write-Host "[2/3] Encoding frames to video..."
& ".\composite_video_from_images.ps1" -FramesFolder $framesDir -OutputVideo $OutputVideo -FPS $FPS

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Video encoding failed"
    exit 1
}

# Step 3: Cleanup
Write-Host ""
Write-Host "[3/3] Cleaning up temporary files..."
Remove-Item $framesDir -Recurse -Force -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "=== Pipeline Complete ==="
Write-Host "Final output: $OutputVideo"
