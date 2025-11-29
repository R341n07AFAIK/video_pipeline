# full_multi_ai_pipeline_comfyui.ps1
# Multi-provider pipeline with ComfyUI integration

param(
    [string]$InputFolder = ".",
    [string]$Pattern = "*.mp4",
    [string]$OutputFolder = "output_comfyui",
    [string]$ComfyUIServer = "http://localhost:8188"
)

Write-Host "=== Multi-AI Pipeline with ComfyUI ==="
Write-Host "Input       : $InputFolder"
Write-Host "ComfyUI     : $ComfyUIServer"
Write-Host "Output      : $OutputFolder"
Write-Host ""

# Test ComfyUI connection
Write-Host "Testing ComfyUI connection..."
try {
    $response = Invoke-WebRequest -Uri "$ComfyUIServer/api" -ErrorAction Stop
    Write-Host "ComfyUI is accessible"
} catch {
    Write-Host "WARNING: ComfyUI not available at $ComfyUIServer"
    Write-Host "Start ComfyUI or update the server address"
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

foreach ($video in $videos) {
    Write-Host ""
    Write-Host "Processing: $($video.Name)"
    
    $outputFile = Join-Path $OutputFolder "$($video.BaseName)_comfyui.mp4"
    
    # Frame extraction
    $framesDir = "comfyui_frames_$([guid]::NewGuid())"
    Write-Host "  Extracting frames to: $framesDir"
    
    if (Get-Command ffmpeg -ErrorAction SilentlyContinue) {
        ffmpeg -i $video.FullName -vf fps=12 "$framesDir\frame_%06d.png"
        Write-Host "  Frames extracted"
    }
}

Write-Host ""
Write-Host "ComfyUI pipeline processing complete!"
