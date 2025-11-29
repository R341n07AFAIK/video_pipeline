# make_composite_video.ps1
# Combine multiple videos and/or image sequences into a single composite

param(
    [string]$ConfigFile = "composite.json",
    [string]$OutputVideo = "composite.mp4"
)

if (!(Test-Path $ConfigFile)) {
    Write-Host "ERROR: Config file not found: $ConfigFile"
    Write-Host ""
    Write-Host "Example composite.json:"
    Write-Host @"
{
  "inputs": [
    { "type": "video", "path": "clip1.mp4" },
    { "type": "video", "path": "clip2.mp4" },
    { "type": "images", "folder": "frames", "fps": 24 }
  ],
  "fps": 24,
  "width": 1920,
  "height": 1080
}
"@
    exit 1
}

Write-Host "=== Make Composite Video ==="
Write-Host "Config      : $ConfigFile"
Write-Host "Output      : $OutputVideo"

$config = Get-Content $ConfigFile | ConvertFrom-Json
$fps = $config.fps
$tmpDir = "composite_tmp"

if (!(Test-Path $tmpDir)) {
    New-Item -ItemType Directory -Path $tmpDir | Out-Null
}

Write-Host "Processing $($config.inputs.Count) input(s)..."

$outputList = "$tmpDir\concat_list.txt"
$fileContent = ""

foreach ($i = 0; $i -lt $config.inputs.Count; $i++) {
    $input = $config.inputs[$i]
    Write-Host "[$($i+1)/$($config.inputs.Count)] Processing: $($input.path)"
    $fileContent += "file '$($tmpDir)\part_$i.mp4'`n"
}

$fileContent | Set-Content $outputList -Encoding UTF8

# Use ffmpeg concat demuxer
if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: ffmpeg not found"
    exit 1
}

ffmpeg -y -f concat -safe 0 -i $outputList -c copy $OutputVideo

Remove-Item $tmpDir -Recurse -Force -ErrorAction SilentlyContinue
Write-Host ""
Write-Host "Composite video created: $OutputVideo"
