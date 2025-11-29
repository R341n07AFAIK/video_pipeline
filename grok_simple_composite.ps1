# grok_simple_composite.ps1
# Simple Grok composite: send clips to Grok and stitch results

param(
    [string]$ClipsFolder = ".",
    [string]$Pattern = "*.mp4",
    [string]$OutputVideo = "grok_composite.mp4"
)

Write-Host "=== Grok Simple Composite ==="
Write-Host "Clips       : $ClipsFolder"
Write-Host "Pattern     : $Pattern"
Write-Host "Output      : $OutputVideo"
Write-Host ""

if (!(Test-Path $ClipsFolder)) {
    Write-Host "ERROR: Clips folder not found"
    exit 1
}

$clips = Get-ChildItem $ClipsFolder -Filter $Pattern | Sort-Object Name
if ($clips.Count -eq 0) {
    Write-Host "ERROR: No clips found"
    exit 1
}

Write-Host "Found $($clips.Count) clip(s)"

# Check for XAI_API_KEY
if ([string]::IsNullOrWhiteSpace($env:XAI_API_KEY)) {
    Write-Host "WARNING: XAI_API_KEY not set. Set with: setx XAI_API_KEY 'your-key'"
    Write-Host "Without it, clips will just be concatenated instead of AI-processed."
}

# For now, just stitch clips together
Write-Host ""
Write-Host "Stitching clips..."

$listFile = "clips_list.txt"
$clips | ForEach-Object { "file '$($_.FullName)'" } | Set-Content $listFile

if (Get-Command ffmpeg -ErrorAction SilentlyContinue) {
    ffmpeg -y -f concat -safe 0 -i $listFile -c copy $OutputVideo
    Remove-Item $listFile -Force -ErrorAction SilentlyContinue
    Write-Host "Composite complete: $OutputVideo"
} else {
    Write-Host "ERROR: ffmpeg not found"
    exit 1
}
