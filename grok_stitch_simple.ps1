# grok_stitch_simple.ps1
# Simple auto-stitch for Grok clips using ffmpeg

param(
    [string]$Folder = "C:\Users\omnic\Documents\vidproj",
    [string]$Pattern = "*.mp4",
    [string]$Output = "grok_stitched.mp4"
)

Write-Host "Starting Grok stitcher..."
Write-Host "Folder: $Folder"
Write-Host "Pattern: $Pattern"
Write-Host ""

if (!(Test-Path $Folder)) {
    Write-Host "Folder not found: $Folder"
    exit 1
}

Set-Location $Folder

$listFile = Join-Path $Folder "clips.txt"

Write-Host "Creating clip list: $listFile"

Get-ChildItem -Filter $Pattern |
    Sort-Object Name |
    ForEach-Object {
        "file '$($_.Name)'"
    } | Out-File -FilePath $listFile -Encoding utf8

if (!(Test-Path $listFile)) {
    Write-Host "Failed to create list file."
    exit 1
}

Write-Host "Output video will be: $Output"
Write-Host ""

# Ensure ffmpeg exists
if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: ffmpeg is not on PATH."
    Write-Host "Install it with:"
    Write-Host "    winget install --id Gyan.FFmpeg --source winget --silent"
    Write-Host "Then open a NEW PowerShell window and run this script again."
    exit 1
}

Write-Host "Running ffmpeg..."
Write-Host ("ffmpeg -f concat -safe 0 -i `"{0}`" -c copy `"{1}`"" -f $listFile, $Output)

ffmpeg -f concat -safe 0 -i $listFile -c copy $Output

Write-Host ""
Write-Host ("Finished. Stitched video saved as: {0}\{1}" -f $Folder, $Output)
