# ultra_local_video_pipeline.ps1
# Ultra local AI video pipeline:
# - Input: .mov / .mp4 clips in a folder
# - For each clip:
#     * Extract audio, clean it, loudness-normalize
#     * Extract frames with ffmpeg
#     * (Optional but enabled-by-default) stylize frames via ComfyUI batch
#     * (Optional) interpolate frames via RIFE or FILM
#     * Encode frames back to video
#     * Apply automatic color correction + stabilization
#     * Re-attach cleaned audio, synced to the processed video
#     * Extract auto keyframes using scene/SSIM-like difference
# - Finally, stitch all processed clips into one final movie
#
# Assumptions:
# - All tools are installed and located under:
#       C:\AItools\
#   Specifically:
#       C:\AItools\rife            (rife-ncnn-vulkan.exe inside)
#       C:\AItools\film            (FILM repo with Python entrypoint)
#       C:\AItools\svd             (Stable Video Diffusion; optional, not wired by default)
#       C:\AItools\realesrgan      (Real-ESRGAN repo; optional for future upscaling)
#       C:\AItools\comfyui         (ComfyUI repo with a batch script)
# - Python, ffmpeg, and git are installed and on PATH.
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File .\ultra_local_video_pipeline.ps1
#   powershell -ExecutionPolicy Bypass -File .\ultra_local_video_pipeline.ps1 -Folder "C:\path\to\clips" -Output "my_long_film.mp4"
#
# You can also tweak toggles:
#   -UseInterpolation:$false  -UseComfyUI:$false  -UseColorStab:$false  -UseKeyframes:$false
#
param(
    # Root folder with .mov/.mp4 clips
    [string]$Folder = "C:\Users\omnic\Documents\vidproj",

    # Final stitched movie name (in $Folder)
    [string]$Output = "ultra_output.mp4",

    # FPS for extraction & encoding
    [int]$Fps = 24,

    # Use RIFE / FILM interpolation
    [bool]$UseInterpolation = $true,

    # Use ComfyUI batch stylization on frames
    [bool]$UseComfyUI = $true,

    # Use automatic color correction + stabilization
    [bool]$UseColorStab = $true,

    # Extract auto keyframes with scene-diff/SSIM-like detection
    [bool]$UseKeyframes = $true
)

Write-Host "=== Ultra Local Video Pipeline ==="
Write-Host "Folder        : $Folder"
Write-Host "Output        : $Output"
Write-Host "FPS           : $Fps"
Write-Host "UseInterpolation : $UseInterpolation"
Write-Host "UseComfyUI       : $UseComfyUI"
Write-Host "UseColorStab     : $UseColorStab"
Write-Host "UseKeyframes     : $UseKeyframes"
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

$rootTools   = "C:\AItools"
$rifeRoot    = Join-Path $rootTools "rife"
$filmRoot    = Join-Path $rootTools "film"
$realesrRoot = Join-Path $rootTools "realesrgan"
$comfyRoot   = Join-Path $rootTools "comfyui"

# Working directory
$workDir = Join-Path $Folder "ultra_work"
if (!(Test-Path $workDir)) {
    New-Item -ItemType Directory -Path $workDir | Out-Null
}

function Extract-Audio {
    param(
        [string]$VideoPath,
        [string]$AudioRaw
    )
    Write-Host "  [Audio] Extracting raw WAV from: $VideoPath"
    ffmpeg -y -i $VideoPath -vn -acodec pcm_s16le -ar 48000 -ac 2 $AudioRaw
}

function Clean-Audio-Loudnorm {
    param(
        [string]$AudioRaw,
        [string]$AudioClean
    )
    Write-Host "  [Audio] Cleaning + loudness-normalizing: $AudioRaw"
    # High-pass + low-pass + denoise + EBU R128 loudnorm
    $af = "highpass=f=80,lowpass=f=12000,afftdn,loudnorm=I=-16:TP=-1.5:LRA=11"
    ffmpeg -y -i $AudioRaw -af $af $AudioClean
}

function Attach-Audio {
    param(
        [string]$VideoPath,
        [string]$AudioPath,
        [string]$OutputPath
    )
    Write-Host "  [Audio] Attaching cleaned audio to video:"
    Write-Host "          Video: $VideoPath"
    Write-Host "          Audio: $AudioPath"
    ffmpeg -y -i $VideoPath -i $AudioPath -c:v copy -c:a aac -shortest $OutputPath
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
    Write-Host "  [Frames] Extracting from: $VideoPath"
    Write-Host "           -> $OutputDir (fps=$Fps)"
    $pattern = Join-Path $OutputDir "frame_%06d.png"
    ffmpeg -y -i $VideoPath -vf ("fps=" + $Fps) $pattern
}

function Invoke-ComfyUIBatch {
    param(
        [string]$FramesIn,
        [string]$FramesOut
    )

    if (-not $UseComfyUI) {
        return $FramesIn
    }

    if (!(Test-Path $comfyRoot)) {
        Write-Host "  [ComfyUI] Root not found at $comfyRoot. Skipping stylization."
        return $FramesIn
    }

    if (!(Test-Path $FramesOut)) {
        New-Item -ItemType Directory -Path $FramesOut | Out-Null
    }

    Write-Host "  [ComfyUI] Stylizing frames via batch operation:"
    Write-Host "            In : $FramesIn"
    Write-Host "            Out: $FramesOut"

    # NOTE:
    # This assumes you have a batch script or entrypoint in your ComfyUI install,
    # for example batch_frames.py which:
    #   - loads a saved workflow
    #   - processes all PNGs in --input
    #   - writes results to --output
    #
    # Adjust this path and arguments to match your setup.
    $batchScript = Join-Path $comfyRoot "batch_frames.py"

    if (!(Test-Path $batchScript)) {
        Write-Host "  [ComfyUI] batch_frames.py not found. Skipping stylization."
        return $FramesIn
    }

    $cmd = "python `"$batchScript`" --input `"$FramesIn`" --output `"$FramesOut`""
    Write-Host "  [ComfyUI] Running: $cmd"
    Invoke-Expression $cmd

    # If output frames exist, use them; otherwise fall back
    $outFrames = Get-ChildItem -Path $FramesOut -Filter "frame_*.png" -ErrorAction SilentlyContinue
    if ($outFrames -and $outFrames.Count -gt 0) {
        Write-Host "  [ComfyUI] Stylized frames found. Using $FramesOut."
        return $FramesOut
    } else {
        Write-Host "  [ComfyUI] No outputs found; falling back to $FramesIn."
        return $FramesIn
    }
}

function Run-Interpolation {
    param(
        [string]$FramesIn,
        [string]$FramesOut
    )

    if (-not $UseInterpolation) {
        Write-Host "  [Interp] Interpolation disabled. Using $FramesIn"
        return $FramesIn
    }

    if (!(Test-Path $FramesOut)) {
        New-Item -ItemType Directory -Path $FramesOut | Out-Null
    }

    $rifeExe = Join-Path $rifeRoot "rife-ncnn-vulkan.exe"
    $used = $false

    if (Test-Path $rifeExe) {
        Write-Host "  [Interp] Using RIFE (rife-ncnn-vulkan) for interpolation."
        $cmd = "`"$rifeExe`" -i `"$FramesIn`" -o `"$FramesOut`" -f 4"
        Write-Host "           $cmd"
        Invoke-Expression $cmd
        $used = $true
    }
    elseif (Test-Path $filmRoot) {
        Write-Host "  [Interp] RIFE not found. Using FILM for interpolation."
        # Assumes FILM repo has a simple CLI (you may need to adjust this):
        # e.g., python inference_video.py --input_dir=FramesIn --output_dir=FramesOut
        $cmd = "python `"$filmRoot\inference_video.py`" --input_dir `"$FramesIn`" --output_dir `"$FramesOut`""
        Write-Host "           $cmd"
        Invoke-Expression $cmd
        $used = $true
    } else {
        Write-Host "  [Interp] No interpolation engine found. Using $FramesIn."
        return $FramesIn
    }

    # Validate output
    $outFrames = Get-ChildItem -Path $FramesOut -Filter "frame_*.png" -ErrorAction SilentlyContinue
    if ($used -and $outFrames -and $outFrames.Count -gt 0) {
        Write-Host "  [Interp] Interpolated frames found: $($outFrames.Count)."
        return $FramesOut
    } else {
        Write-Host "  [Interp] No interpolated frames; falling back to input frames."
        return $FramesIn
    }
}

function Encode-FramesToVideo {
    param(
        [string]$FramesDir,
        [string]$OutputPath,
        [int]$Fps
    )
    Write-Host "  [Encode] Encoding frames to video:"
    Write-Host "           Frames: $FramesDir"
    Write-Host "           Output: $OutputPath"
    $pattern = Join-Path $FramesDir "frame_%06d.png"
    ffmpeg -y -framerate $Fps -i $pattern -c:v libx264 -pix_fmt yuv420p $OutputPath
}

function ColorCorrectAndStabilize {
    param(
        [string]$InputVideo,
        [string]$TransformsBase,
        [string]$OutputVideo
    )

    if (-not $UseColorStab) {
        Write-Host "  [Color/Stab] Disabled. Using $InputVideo directly."
        Copy-Item $InputVideo $OutputVideo -Force
        return
    }

    Write-Host "  [Color/Stab] Analysing motion for stabilization..."
    $trf = Join-Path $TransformsBase "transforms.trf"

    # vidstabdetect writes transforms to file; NUL is the null sink on Windows
    ffmpeg -y -i $InputVideo -vf "vidstabdetect=shakiness=5:accuracy=15:result='$trf'" -f null NUL

    Write-Host "  [Color/Stab] Applying stabilization + color correction..."
    # Color correction via eq filter, plus vidstabtransform
    $vf = "vidstabtransform=input='$trf':smoothing=30,eq=brightness=0.02:contrast=1.1:saturation=1.05"
    ffmpeg -y -i $InputVideo -vf $vf -c:v libx264 -pix_fmt yuv420p $OutputVideo
}

function Extract-Keyframes {
    param(
        [string]$VideoPath,
        [string]$KeyframesDir
    )

    if (-not $UseKeyframes) {
        return
    }

    if (!(Test-Path $KeyframesDir)) {
        New-Item -ItemType Directory -Path $KeyframesDir | Out-Null
    }

    Write-Host "  [Keyframes] Extracting auto keyframes (scene-based) from: $VideoPath"
    Write-Host "               -> $KeyframesDir"

    # We use ffmpeg's scene detection (based on changes in frames, conceptually similar
    # to SSIM difference use-cases). It selects frames where the scene score exceeds a threshold.
    #
    # It also writes logging info (including scene values) to scene_log.txt.
    $kfPattern = Join-Path $KeyframesDir "kf_%06d.png"
    $logPath   = Join-Path $KeyframesDir "scene_log.txt"

    # -vsync vfr ensures we only output selected frames
    ffmpeg -y -i $VideoPath -vf "select='gt(scene,0.35)',showinfo" -vsync vfr $kfPattern -f null NUL 2> $logPath
}

# Collect processed final clips for stitching
$finalClips = New-Object System.Collections.Generic.List[string]

# Enumerate input videos
$videos = Get-ChildItem -File | Where-Object { $_.Extension -in ".mov", ".mp4" } | Sort-Object Name

if ($videos.Count -eq 0) {
    Write-Host "ERROR: No .mov/.mp4 files found in $Folder"
    exit 1
}

Write-Host "Found $($videos.Count) input video(s)."
Write-Host ""

$idx = 0
foreach ($vid in $videos) {
    $idx++
    $percent = [int](($idx / $videos.Count) * 100)
    Write-Progress -Activity "Processing clip(s)" -Status "Clip $idx of $($videos.Count): $($vid.Name)" -PercentComplete $percent

    Write-Host "=== Processing: $($vid.Name) ==="

    $baseName    = [System.IO.Path]::GetFileNameWithoutExtension($vid.Name)
    $clipWorkDir = Join-Path $workDir $baseName

    if (!(Test-Path $clipWorkDir)) {
        New-Item -ItemType Directory -Path $clipWorkDir | Out-Null
    }

    $framesRaw   = Join-Path $clipWorkDir "frames_raw"
    $framesStyl  = Join-Path $clipWorkDir "frames_stylized"
    $framesInterp= Join-Path $clipWorkDir "frames_interp"

    $audioRaw    = Join-Path $clipWorkDir "audio_raw.wav"
    $audioClean  = Join-Path $clipWorkDir "audio_clean.wav"

    $videoFromFrames = Join-Path $clipWorkDir "video_from_frames.mp4"
    $videoColorStab  = Join-Path $clipWorkDir "video_color_stab.mp4"
    $videoFinalClip  = Join-Path $clipWorkDir "final_clip_with_audio.mp4"

    $keyframesDir    = Join-Path $clipWorkDir "keyframes"

    # 1) Audio extraction + cleaning
    Extract-Audio -VideoPath $vid.FullName -AudioRaw $audioRaw
    Clean-Audio-Loudnorm -AudioRaw $audioRaw -AudioClean $audioClean

    # 2) Frames extraction
    Extract-Frames -VideoPath $vid.FullName -OutputDir $framesRaw -Fps $Fps

    # 3) ComfyUI stylization (if enabled)
    $framesAfterComfy = Invoke-ComfyUIBatch -FramesIn $framesRaw -FramesOut $framesStyl

    # 4) Interpolation (if enabled)
    $framesForEncode = Run-Interpolation -FramesIn $framesAfterComfy -FramesOut $framesInterp

    # 5) Encode frames -> video
    Encode-FramesToVideo -FramesDir $framesForEncode -OutputPath $videoFromFrames -Fps $Fps

    # 6) Color correction + stabilization
    ColorCorrectAndStabilize -InputVideo $videoFromFrames -TransformsBase $clipWorkDir -OutputVideo $videoColorStab

    # 7) Auto keyframes extraction
    Extract-Keyframes -VideoPath $videoColorStab -KeyframesDir $keyframesDir

    # 8) Re-attach cleaned audio
    Attach-Audio -VideoPath $videoColorStab -AudioPath $audioClean -OutputPath $videoFinalClip

    if (Test-Path $videoFinalClip) {
        $finalClips.Add($videoFinalClip) | Out-Null
        Write-Host "  [Done] Final per-clip output: $videoFinalClip"
    } else {
        Write-Host "  [WARNING] Final per-clip output missing, skipping: $($vid.Name)"
    }

    Write-Host ""
}

Write-Progress -Activity "Processing clip(s)" -Completed -Status "Done"

if ($finalClips.Count -eq 0) {
    Write-Host "ERROR: No final clips produced."
    exit 1
}

# If only one final clip, just copy it to $Output
$finalOutputPath = Join-Path $Folder $Output

if ($finalClips.Count -eq 1) {
    Write-Host "Only one final clip produced. Copying it to: $finalOutputPath"
    Copy-Item $finalClips[0] $finalOutputPath -Force
    Write-Host "=== All done ==="
    Write-Host "Final movie: $finalOutputPath"
    exit 0
}

# Build concat list for multiple clips
$listFile = Join-Path $workDir "concat_final.txt"
Write-Host "Building concat list: $listFile"

$lines = $finalClips | ForEach-Object {
    "file '" + (Split-Path $_ -Leaf) + "'"
}
$lines | Set-Content -Path $listFile -Encoding ascii

Write-Host "Stitching all final clips into: $finalOutputPath"
Write-Host ("ffmpeg -f concat -safe 0 -i `"{0}`" -c copy `"{1}`"" -f $listFile, $finalOutputPath)

ffmpeg -y -f concat -safe 0 -i $listFile -c copy $finalOutputPath

Write-Host ""
Write-Host "=== Ultra pipeline complete ==="
Write-Host ("Final movie: {0}" -f $finalOutputPath)
