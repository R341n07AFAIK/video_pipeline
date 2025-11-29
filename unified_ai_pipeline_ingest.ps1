# unified_ai_pipeline_ingest.ps1
# Ingest videos into the unified AI pipeline system

param(
    [string]$SourcePath = "",
    [string]$IngestFolder = "ingest"
)

if ([string]::IsNullOrWhiteSpace($SourcePath)) {
    Write-Host "Usage: powershell -File unified_ai_pipeline_ingest.ps1 -SourcePath 'C:\videos' -IngestFolder 'ingest'"
    exit 1
}

if (!(Test-Path $SourcePath)) {
    Write-Host "ERROR: Source path not found: $SourcePath"
    exit 1
}

if (!(Test-Path $IngestFolder)) {
    New-Item -ItemType Directory -Path $IngestFolder | Out-Null
}

Write-Host "=== Unified AI Pipeline - Ingest ==="
Write-Host "Source : $SourcePath"
Write-Host "Ingest : $IngestFolder"
Write-Host ""

$videos = Get-ChildItem $SourcePath -Filter @("*.mp4", "*.mov", "*.mkv")
Write-Host "Found $($videos.Count) video(s)"

foreach ($video in $videos) {
    Write-Host "Ingesting: $($video.Name)"
    $destination = Join-Path $IngestFolder $video.Name
    Copy-Item $video.FullName $destination -Force
    Write-Host "  -> $destination"
}

Write-Host ""
Write-Host "Ingest complete! Run the pipeline with: .\unified_ai_pipeline.ps1 -IngestFolder $IngestFolder"
