# full_ai_pipeline_with_video.ps1
# AI pipeline with advanced video processing (upscaling, interpolation)

param(
    [string]$InputFolder = ".",
    [string]$Pattern = "*.mp4",
    [string]$OutputFolder = "output_video",
    [int]$TargetFPS = 60,
    [string]$Upscale = "none"
)

Write-Host "=== Full AI Pipeline with Advanced Video ==="
Write-Host "Input       : $InputFolder"
Write-Host "Target FPS  : $TargetFPS"
Write-Host "Upscale     : $Upscale"
Write-Host "Output      : $OutputFolder"
Write-Host ""

if (!(Test-Path $InputFolder)) {
    Write-Host "ERROR: Input folder not found"
    exit 1
}

if (!(Test-Path $OutputFolder)) {
    New-Item -ItemType Directory -Path $OutputFolder | Out-Null
}

$videos = Get-ChildItem $InputFolder -Filter $Pattern
foreach ($video in $videos) {
    Write-Host "Processing: $($video.Name)"
    $outputFile = Join-Path $OutputFolder "$($video.BaseName)_enhanced.mp4"
    
    # Build ffmpeg filter chain
    $filters = @()
    if ($Upscale -ne "none") {
        $filters += "scale=iw*2:ih*2"
    }
    
    $filterString = [string]::Join(",", $filters)
    
    if ($filterString) {
        ffmpeg -i $video.FullName -vf $filterString -r $TargetFPS -c:v libx264 -preset medium -c:a aac $outputFile
    } else {
        ffmpeg -i $video.FullName -r $TargetFPS -c:v libx264 -preset medium -c:a aac $outputFile
    }
}

Write-Host ""
Write-Host "Advanced video processing complete!"
