# unified_ai_pipeline_live.ps1
# Live streaming integration for the unified AI pipeline

param(
    [string]$StreamURL = "rtmp://localhost/live/stream",
    [string]$OutputFolder = "live_output",
    [string]$Provider = "grok"
)

Write-Host "=== Unified AI Pipeline - Live Streaming ==="
Write-Host "Stream URL : $StreamURL"
Write-Host "AI Provider: $Provider"
Write-Host "Output     : $OutputFolder"
Write-Host ""

if (!(Test-Path $OutputFolder)) {
    New-Item -ItemType Directory -Path $OutputFolder | Out-Null
}

if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: ffmpeg required"
    exit 1
}

Write-Host "Starting live stream capture..."
Write-Host "Press Ctrl+C to stop"
Write-Host ""

$outputFile = Join-Path $OutputFolder "stream_$(Get-Date -Format 'yyyyMMdd_HHmmss').mp4"

# Capture live stream
ffmpeg -rtsp_transport tcp -i $StreamURL -c:v copy -c:a copy $outputFile

Write-Host ""
Write-Host "Stream capture complete: $outputFile"
