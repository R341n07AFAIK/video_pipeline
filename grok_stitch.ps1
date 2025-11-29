# grok_stitch_full.ps1
# Auto-stitch Grok video clips:
# 1) Generate clips.txt
# 2) Clean BOM with a progress bar (ASCII, no BOM)
# 3) Run ffmpeg concat to produce a single MP4

param(
    [string]$Folder = "C:\Users\omnic\Documents\vidproj",
    [string]$Pattern = "*.mp4",
    [string]$Output = "grok_stitched.mp4"
)

Write-Host "=== Grok Video Stitcher ==="
Write-Host "Folder : $Folder"
Write-Host "Pattern: $Pattern"
Write-Host "Output : $Output"
Write-Host ""

# 1) Sanity check on folder
if (!(Test-Path $Folder)) {
    Write-Host "ERROR: Folder not found: $Folder"
    exit 1
}

Set-Location $Folder

# 2) Build clips.txt from matching files
$listFile = Join-Path $Folder "clips.txt"
Write-Host "Step 1/3: Building clip list -> $listFile"

$files = Get-ChildItem -Filter $Pattern | Sort-Object Name

if ($files.Count -eq 0) {
    Write-Host "ERROR: No files found matching pattern '$Pattern' in $Folder"
    exit 1
}

$files | ForEach-Object {
    "file '$($_.Name)'"
} | Set-Content -Path $listFile -Encoding utf8

Write-Host "  Found $($files.Count) clip(s)."
Write-Host ""

# 3) Clean BOM / enforce ASCII with progress
Write-Host "Step 2/3: Cleaning clips.txt (removing BOM, enforcing ASCII) with progress..."

$src = $listFile
$tmp = Join-Path $Folder "clips_clean.tmp"

$lines = Get-Content $src
$total = $lines.Count
if ($total -eq 0) {
    Write-Host "ERROR: clips.txt is empty."
    exit 1
}

$i = 0
$lines | ForEach-Object {
    $i++
    $percent = [int](($i / $total) * 100)
    Write-Progress -Activity "Cleaning clips.txt" -Status "Line $i of $total" -PercentComplete $percent
    $_
} | Set-Content $tmp -Encoding ascii

# Replace original with cleaned version
Move-Item -Force $tmp $src

Write-Host "  Cleaning complete. clips.txt is now ASCII with no BOM."
Write-Host ""

# 4) Ensure ffmpeg is available
Write-Host "Step 3/3: Running ffmpeg concat..."

if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: ffmpeg is not on PATH."
    Write-Host "Install it (once) with:"
    Write-Host "    winget install --id Gyan.FFmpeg --source winget"
    Write-Host "Then close all PowerShell windows, open a new one, and run this script again."
    exit 1
}

Write-Host ("Executing: ffmpeg -f concat -safe 0 -i `"{0}`" -c copy `"{1}`"" -f $listFile, $Output)
Write-Host ""

ffmpeg -f concat -safe 0 -i $listFile -c copy $Output

Write-Host ""
Write-Host "=== Done ==="
Write-Host ("Stitched video saved as: {0}\{1}" -f $Folder, $Output)
