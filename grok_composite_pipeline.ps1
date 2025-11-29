<#
.SYNOPSIS
    Core pipeline for generating a composite video from images.
.DESCRIPTION
    Collects all images from the input folder recursively.
    Applies optional AI preprocessing.
    Compiles images into a video using ffmpeg.
#>

param(
    [Parameter(Mandatory=$true)][string]$InputFolder,
    [Parameter(Mandatory=$true)][string]$OutputVideo,
    [int]$FPS = 24,
    [switch]$UseAIEnhancement,
    [string]$ExtraFFmpegArgs = ""
)

# Collect all images recursively
Write-Host "Searching for images in $InputFolder..."
$images = Get-ChildItem -Path $InputFolder -Include *.png,*.jpg,*.jpeg -Recurse | Sort-Object FullName

if ($images.Count -eq 0) {
    Write-Error "No images found in $InputFolder"
    exit
}

# Optional AI preprocessing
if ($UseAIEnhancement) {
    Write-Host "Applying AI enhancement to $($images.Count) images..."
    foreach ($img in $images) {
        # Placeholder for AI preprocessing
        # Replace this with your AI image enhancement command
        Write-Host "Processing $($img.FullName)"
        # Example: python enhance_image.py -i $img.FullName -o $img.FullName
    }
}

# Prepare temporary folder for ffmpeg
$tempFolder = Join-Path $InputFolder "ffmpeg_temp"
if (-not (Test-Path $tempFolder)) { New-Item -ItemType Directory -Path $tempFolder | Out-Null }

# Copy images to temp folder with sequential numbering
$count = 1
foreach ($img in $images) {
    $ext = $img.Extension
    Copy-Item $img.FullName -Destination (Join-Path $tempFolder ("img_{0:D5}{1}" -f $count, $ext))
    $count++
}

# Build ffmpeg command
$ffmpegArgs = "-y -r $FPS -i `"$tempFolder\img_%05d$($images[0].Extension)`" $ExtraFFmpegArgs `"$OutputVideo`""
Write-Host "Running ffmpeg to create video..."
& ffmpeg.exe $ffmpegArgs

# Cleanup temp folder
Remove-Item -Recurse -Force $tempFolder
Write-Host "Composite video created at $OutputVideo"
