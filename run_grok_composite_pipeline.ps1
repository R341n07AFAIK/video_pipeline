# run_grok_composite_pipeline.ps1
# Runner script for the Grok composite pipeline

param(
    [string]$ClipsFolder = "clips",
    [string]$OutputVideo = "grok_composite_final.mp4"
)

Write-Host "=== Running Grok Composite Pipeline ==="

if (!(Test-Path $ClipsFolder)) {
    Write-Host "ERROR: Clips folder not found: $ClipsFolder"
    Write-Host "Usage: powershell -File run_grok_composite_pipeline.ps1 -ClipsFolder 'C:\clips' -OutputVideo 'final.mp4'"
    exit 1
}

# Verify prerequisites
if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: ffmpeg required. Install with: winget install --id Gyan.FFmpeg"
    exit 1
}

# Run the pipeline
& ".\grok_composite_pipeline.ps1" -ClipsFolder $ClipsFolder -OutputVideo $OutputVideo

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "Pipeline completed successfully!"
    Write-Host "Output: $OutputVideo"
} else {
    Write-Host ""
    Write-Host "Pipeline failed with exit code: $LASTEXITCODE"
    exit 1
}
