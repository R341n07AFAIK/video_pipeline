# unified_ai_tool_preview.ps1
# Preview and test AI processing without full pipeline

param(
    [string]$VideoPath = "",
    [int]$PreviewDuration = 10,
    [string]$Provider = "grok"
)

if ([string]::IsNullOrWhiteSpace($VideoPath)) {
    Write-Host "Usage: powershell -File unified_ai_tool_preview.ps1 -VideoPath 'video.mp4' -PreviewDuration 10"
    exit 1
}

if (!(Test-Path $VideoPath)) {
    Write-Host "ERROR: Video not found: $VideoPath"
    exit 1
}

Write-Host "=== AI Tool Preview ==="
Write-Host "Video       : $VideoPath"
Write-Host "Duration    : $PreviewDuration seconds"
Write-Host "Provider    : $Provider"
Write-Host ""

if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: ffmpeg required"
    exit 1
}

# Create preview clip
$previewFile = "preview_temp.mp4"
Write-Host "Creating preview clip ($PreviewDuration seconds)..."
ffmpeg -y -i $VideoPath -t $PreviewDuration -c:v libx264 -c:a aac $previewFile

if (Test-Path $previewFile) {
    Write-Host "Preview created: $previewFile"
    Write-Host ""
    Write-Host "You can now:"
    Write-Host "  1. Test AI processing on this preview"
    Write-Host "  2. Verify settings before full processing"
    Write-Host ""
    Write-Host "To process the full video, use the main pipeline scripts."
} else {
    Write-Host "ERROR: Failed to create preview"
    exit 1
}
