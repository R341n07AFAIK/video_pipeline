# free_local_video_pipeline.ps1
# Free, local, offline video pipeline for .mov/.mp4 and image sequences.
# - Extracts frames from .mov/.mp4 with ffmpeg
# - Optional external interpolation (e.g. RIFE, FILM) via user-provided command
# - Re-encodes processed frames into videos
# - Stitches all processed videos into one final clip
#
# Usage examples:
#   powershell -ExecutionPolicy Bypass -File .\free_local_video_pipeline.ps1
#   powershell -ExecutionPolicy Bypass -File .\free_local_video_pipeline.ps1 -Folder "C:\path\to\clips" -Output "my_film.mp4"
#   powershell -ExecutionPolicy Bypass -File .\free_local_video_pipeline.ps1 -InterpolationCommand "rife-ncnn-vulkan.exe -i {IN} -o {OUT} -f 4"
#
# Notes:
# - Requires ffmpeg on PATH (install with: winget install --id Gyan.FFmpeg --source winget)
# - Interpolation is optional; if no command is provided, raw frames are used.

param(
    # Root folder for your .mov/.mp4 clips or image sequences
    [string]$Folder = "C:\Users\omnic\Documents\vidproj",

    # Final stitched video output name
    [string]$Output = "final_output.mp4",

    # Frames per second for frame extraction and encoding
    [int]$Fps = 24,

    # Optional interpolation command.
    # Use {IN} as placeholder for input frames directory, {OUT} for output frames directory.
    # Example:
    #   "rife-ncnn-vulkan.exe -i {IN} -o {OUT} -f 4"
    [string]$InterpolationCommand = ""
)

Write-Host "=== Free Local Video Pipeline ==="
Write-Host "Folder               : $Folder"
Write-Host "Output               : $Output"
Write-Host "FPS                  : $Fps"
Write-Host "InterpolationCommand : $InterpolationCommand"
Write-Host ""

function Ensure-FFmpeg {
    if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
        Write-Host "ERROR: ffmpeg is not on PATH."
        Write-Host "Install it (once) with:"
        Write-Host "    winget install --id Gyan.FFmpeg --source winget"
        Write-Host "Then open a NEW PowerShell window and run this script again."
        exit 1
    }
}

if (!(Test-Path $Folder)) {
    Write-Host "ERROR: Folder not found: $Folder"
    exit 1
}

Ensure-FFmpeg
Set-Location $Folder

# Working directory inside the project folder
$workDir = Join-Path $Folder "free_video_work"
if (!(Test-Path $workDir)) {
    New-Item -ItemType Directory -Path $workDir | Out-Null
}

function Extract-Frames {
    param(
        [string]$VideoPath,
        [string]$OutputDir,
        [int]$Fps
    )

    if (!(Test-Path $OutputDir)) {
        New-Item -ItemType Directory -Path $OutputDir | Out-Null
    }

    Write-Host "Extracting frames from: $VideoPath"
    Write-Host "  -> $OutputDir (fps=$Fps)"

    # -vf fps=FPS to control frame rate
    ffmpeg -y -i $VideoPath -vf ("fps=" + $Fps) (Join-Path $OutputDir "frame_%06d.png")
}

function Run-InterpolationIfRequested {
    param(
        [string]$FramesIn,
        [string]$FramesOut
    )

    if ([string]::IsNullOrWhiteSpace($InterpolationCommand)) {
        Write-Host "No interpolation command set. Using raw frames from: $FramesIn"
        return $FramesIn
    }

    if (!(Test-Path $FramesOut)) {
        New-Item -ItemType Directory -Path $FramesOut | Out-Null
    }

    $cmd = $InterpolationCommand.Replace("{IN}", $FramesIn).Replace("{OUT}", $FramesOut)

    Write-Host "Running interpolation command:"
    Write-Host "  $cmd"
    Write-Host ""
    Write-Host "NOTE: Ensure the tool (e.g. rife-ncnn-vulkan.exe) is installed and on PATH or in this folder."
    Write-Host ""

    Invoke-Expression $cmd

    # Assume interpolation wrote frames into FramesOut; if not, fall back
    $outFrames = Get-ChildItem -Path $FramesOut -Filter "frame_*.png" -ErrorAction SilentlyContinue
    if ($outFrames -and $outFrames.Count -gt 0) {
        Write-Host "Using interpolated frames from: $FramesOut"
        return $FramesOut
    } else {
        Write-Host "WARNING: No frames found in $FramesOut after interpolation. Falling back to $FramesIn."
        return $FramesIn
    }
}

function Encode-FramesToVideo {
    param(
        [string]$FramesDir,
        [string]$OutputPath,
        [int]$Fps
    )

    Write-Host "Encoding frames to video:"
    Write-Host "  Frames : $FramesDir"
    Write-Host "  Output : $OutputPath"
    Write-Host "  FPS    : $Fps"

    $pattern = Join-Path $FramesDir "frame_%06d.png"
    ffmpeg -y -framerate $Fps -i $pattern -c:v libx264 -pix_fmt yuv420p $OutputPath
}

# Gather video files (.mov and .mp4)
$videos = Get-ChildItem -File | Where-Object { $_.Extension -in ".mov", ".mp4" } | Sort-Object Name

# Also allow pure image-sequence mode if there are no videos but there are PNGs/JPGs
$images = Get-ChildItem -File | Where-Object { $_.Extension -in ".png", ".jpg", ".jpeg" } | Sort-Object Name

$processedVideos = New-Object System.Collections.Generic.List[string]

if ($videos.Count -gt 0) {
    Write-Host "Found $($videos.Count) video file(s) (.mov/.mp4)."
    Write-Host ""

    $index = 0
    foreach ($vid in $videos) {
        $index++
        $percent = [int](($index / $videos.Count) * 100)
        Write-Progress -Activity "Processing videos" -Status "Video $index of $($videos.Count): $($vid.Name)" -PercentComplete $percent

        $baseName   = [System.IO.Path]::GetFileNameWithoutExtension($vid.Name)
        $framesIn   = Join-Path $workDir ("frames_in_" + $baseName)
        $framesOut  = Join-Path $workDir ("frames_out_" + $baseName)
        $videoOut   = Join-Path $workDir ("processed_" + $baseName + ".mp4")

        # Clean up any previous runs for this clip
        if (Test-Path $framesIn)  { Remove-Item $framesIn -Recurse -Force }
        if (Test-Path $framesOut) { Remove-Item $framesOut -Recurse -Force }
        if (Test-Path $videoOut)  { Remove-Item $videoOut -Force }

        # 1) Extract frames
        Extract-Frames -VideoPath $vid.FullName -OutputDir $framesIn -Fps $Fps

        # 2) Optional interpolation
        $finalFramesDir = Run-InterpolationIfRequested -FramesIn $framesIn -FramesOut $framesOut

        # 3) Encode back to video
        Encode-FramesToVideo -FramesDir $finalFramesDir -OutputPath $videoOut -Fps $Fps

        if (Test-Path $videoOut) {
            $processedVideos.Add($videoOut) | Out-Null
        } else {
            Write-Host "WARNING: Processed video not found for $($vid.Name). Skipping."
        }
    }

    Write-Progress -Activity "Processing videos" -Completed -Status "Done"
    Write-Host ""
}
elseif ($images.Count -gt 0) {
    Write-Host "No .mov/.mp4 files found, but found $($images.Count) image(s)."
    Write-Host "Using images as a single sequence."
    Write-Host ""

    $framesDir = Join-Path $workDir "frames_sequence"
    if (Test-Path $framesDir) { Remove-Item $framesDir -Recurse -Force }
    New-Item -ItemType Directory -Path $framesDir | Out-Null

    $i = 0
    foreach ($img in $images) {
        $i++
        $name = "frame_{0:D6}{1}" -f $i, ".png"
        # Convert to PNG to standardize naming; ImageMagick or ffmpeg can do conversion,
        # but for simplicity we copy PNG directly and for JPG we use ffmpeg.
        if ($img.Extension -in ".png") {
            Copy-Item $img.FullName (Join-Path $framesDir $name)
        } else {
            # Convert non-PNG to PNG via ffmpeg
            ffmpeg -y -i $img.FullName (Join-Path $framesDir $name)
        }
    }

    $framesOut = Join-Path $workDir "frames_sequence_out"
    if (Test-Path $framesOut) { Remove-Item $framesOut -Recurse -Force }
    New-Item -ItemType Directory -Path $framesOut | Out-Null

    $finalFramesDir = Run-InterpolationIfRequested -FramesIn $framesDir -FramesOut $framesOut

    $videoOut = Join-Path $workDir "processed_sequence.mp4"
    Encode-FramesToVideo -FramesDir $finalFramesDir -OutputPath $videoOut -Fps $Fps

    if (Test-Path $videoOut) {
        $processedVideos.Add($videoOut) | Out-Null
    }
}
else {
    Write-Host "ERROR: No .mov/.mp4 videos or image files (.png/.jpg/.jpeg) found in $Folder"
    exit 1
}

if ($processedVideos.Count -eq 0) {
    Write-Host "ERROR: No processed videos available to stitch."
    exit 1
}

# If only one processed video, just copy/rename it to the final output
if ($processedVideos.Count -eq 1) {
    Write-Host "Only one processed video. Copying it to final output: $Output"
    Copy-Item $processedVideos[0] (Join-Path $Folder $Output) -Force
    Write-Host "Done. Final video: $Folder\$Output"
    exit 0
}

# Build concat list for multiple processed videos
$listFile = Join-Path $workDir "concat_list.txt"
Write-Host "Building concat list: $listFile"

$lines = $processedVideos | ForEach-Object {
    "file '" + (Split-Path $_ -Leaf) + "'"
}
$lines | Set-Content -Path $listFile -Encoding ascii

Write-Host "Stitching processed videos with ffmpeg..."
Write-Host ("ffmpeg -f concat -safe 0 -i `"{0}`" -c copy `"{1}`"" -f $listFile, $Output)

ffmpeg -y -f concat -safe 0 -i $listFile -c copy (Join-Path $Folder $Output)

Write-Host ""
Write-Host "=== Pipeline complete ==="
Write-Host ("Final video: {0}\{1}" -f $Folder, $Output)
