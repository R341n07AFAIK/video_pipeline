# mj_video_pipeline.ps1
# Multi-mode pipeline for Midjourney + video engines + Grok-style processing.
#
# Modes:
#   1) MJToVideo       - Midjourney keyframes -> external video engine (Pika/Runway/Luma/etc.) -> stitched video
#   2) MJInterpolate   - Midjourney frames -> optional external frame interpolation -> stitched video
#   3) MJStyleGrok     - Existing video clips -> Grok Video API style processing -> stitched long-form clip
#
# IMPORTANT:
# - All API calls in here are TEMPLATES. You MUST:
#     * Set the correct $VideoEndpoint and field names for your provider (Pika, Runway, Luma, Kling, etc.).
#     * For Grok, set the real endpoint and response structure when xAI exposes it.
# - Requires:
#     * PowerShell 5+ or 7+
#     * ffmpeg on PATH
#     * For API modes: environment variable(s) set for keys (XAI_API_KEY, VIDEO_API_KEY, etc.).
#
# Example usage:
#   powershell -ExecutionPolicy Bypass -File .\mj_video_pipeline.ps1 -Mode MJToVideo -Folder C:\Users\omnic\Documents\vidproj
#   powershell -ExecutionPolicy Bypass -File .\mj_video_pipeline.ps1 -Mode MJInterpolate -Folder C:\Users\omnic\Documents\vidproj
#   powershell -ExecutionPolicy Bypass -File .\mj_video_pipeline.ps1 -Mode MJStyleGrok -Folder C:\Users\omnic\Documents\vidproj

param(
    [ValidateSet("MJToVideo","MJInterpolate","MJStyleGrok")]
    [string]$Mode = "MJToVideo",

    # Root folder containing images or clips
    [string]$Folder = "C:\Users\omnic\Documents\vidproj",

    # Image pattern for MJ frames (PNG/JPG)
    [string]$PatternImages = "*.png",

    # Video clip pattern for Grok-style processing
    [string]$PatternClips = "*.mp4",

    # Output video name
    [string]$Output = "mj_video_output.mp4",

    # For MJToVideo: prompt sent to external video model for each keyframe
    [string]$VideoStylePrompt = "Turn this Midjourney keyframe into a short cinematic video clip matching its style, motion, and atmosphere.",

    # For MJStyleGrok: prompt used to unify style over existing clips
    [string]$GrokStylePrompt = "Unify all clips into a single long cinematic with a Midjourney-like surreal style, consistent color, motion, and atmosphere.",

    # For MJInterpolate: optional external interpolation command
    # Example: 'rife-ncnn-vulkan -i frames_in -o frames_out -f 4'
    [string]$InterpolationCommand = ""
)

Write-Host "=== MJ Video Pipeline ==="
Write-Host "Mode           : $Mode"
Write-Host "Folder         : $Folder"
Write-Host "Images pattern : $PatternImages"
Write-Host "Clips pattern  : $PatternClips"
Write-Host "Output         : $Output"
Write-Host ""

# ---------- COMMON HELPERS ----------

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

# Prepare a working directory inside Folder
$workDir = Join-Path $Folder "mj_video_work"
if (!(Test-Path $workDir)) {
    New-Item -ItemType Directory -Path $workDir | Out-Null
}

# =====================================================================
# MODE 1: Midjourney keyframes -> external video engine per frame -> stitched
# =====================================================================

function Invoke-ExternalVideoFromImage {
    param(
        [string]$ImagePath,
        [string]$OutputPath,
        [string]$Prompt
    )

    # TEMPLATE for external video model (Pika, Runway, Luma, Kling, etc.)
    # You must configure:
    #   - $VideoEndpoint
    #   - $VideoApiKey
    #   - form field names (file, prompt, model, aspect_ratio, duration, etc.)
    $VideoEndpoint = "https://YOUR-VIDEO-MODEL-ENDPOINT-HERE"
    $VideoApiKey   = $Env:VIDEO_API_KEY

    if ([string]::IsNullOrWhiteSpace($VideoApiKey)) {
        Write-Host "ERROR: VIDEO_API_KEY environment variable is not set."
        Write-Host "Set it like this (example):"
        Write-Host '    setx VIDEO_API_KEY "your-video-model-api-key"'
        Write-Host "Then open a NEW PowerShell window and run again."
        return $null
    }

    Write-Host "Calling external video model for image: $ImagePath"
    Write-Host "  Output -> $OutputPath"

    $headers = @{
        "Authorization" = "Bearer $VideoApiKey"
    }

    # Example generic multipart form data. Adjust for your provider.
    $form = @{
        "file"   = Get-Item $ImagePath
        "prompt" = $Prompt
        "model"  = "video-model-name-or-id"   # TODO: replace
        "mode"   = "image-to-video"          # TODO: adjust or remove
        "duration" = "5"                     # seconds, if applicable
    }

    try {
        $response = Invoke-RestMethod -Method Post -Uri $VideoEndpoint -Headers $headers -Form $form

        # Common patterns:
        #   1) Binary bytes returned directly
        #   2) JSON with a URL to download
        if ($response -is [byte[]]) {
            [System.IO.File]::WriteAllBytes($OutputPath, $response)
        }
        elseif ($response.video_url) {
            Write-Host "  Downloading video from: $($response.video_url)"
            Invoke-WebRequest -Uri $response.video_url -OutFile $OutputPath
        }
        else {
            Write-Host "WARNING: Unknown response shape from video API."
            Write-Host "Raw response:"
            $response | ConvertTo-Json -Depth 5
            return $null
        }

        if (Test-Path $OutputPath) {
            Write-Host "  Saved: $OutputPath"
            return $OutputPath
        } else {
            Write-Host "  ERROR: Output file not created."
            return $null
        }
    }
    catch {
        Write-Host "ERROR calling external video API:"
        Write-Host $_
        return $null
    }
}

function Run-MJToVideoMode {
    Write-Host "Mode: MJToVideo (images -> external video model -> stitched)"
    Write-Host ""

    $images = Get-ChildItem -Filter $PatternImages | Sort-Object Name
    if ($images.Count -eq 0) {
        Write-Host "ERROR: No images found matching '$PatternImages' in $Folder"
        return
    }

    Write-Host "Found $($images.Count) Midjourney image(s)."
    $clipList = New-Object System.Collections.Generic.List[string]

    $index = 0
    foreach ($img in $images) {
        $index++
        $percent = [int](($index / $images.Count) * 100)
        Write-Progress -Activity "Generating clips from MJ images" -Status "Image $index of $($images.Count): $($img.Name)" -PercentComplete $percent

        $outName = [System.IO.Path]::GetFileNameWithoutExtension($img.Name) + "_clip.mp4"
        $outPath = Join-Path $workDir $outName

        $res = Invoke-ExternalVideoFromImage -ImagePath $img.FullName -OutputPath $outPath -Prompt $VideoStylePrompt
        if ($null -ne $res) {
            $clipList.Add($res) | Out-Null
        } else {
            Write-Host "  WARNING: Skipping image due to API failure: $($img.FullName)"
        }
    }

    Write-Progress -Activity "Generating clips from MJ images" -Completed -Status "Done"
    Write-Host ""

    if ($clipList.Count -eq 0) {
        Write-Host "ERROR: No clips were generated."
        return
    }

    # Build concat list and stitch
    $listFile = Join-Path $workDir "mjtovideo_concat.txt"
    $lines = $clipList | ForEach-Object {
        "file '" + (Split-Path $_ -Leaf) + "'"
    }
    $lines | Set-Content -Path $listFile -Encoding ascii

    Write-Host "Stitching generated clips with ffmpeg..."
    Write-Host ("ffmpeg -f concat -safe 0 -i `"{0}`" -c copy `"{1}`"" -f $listFile, $Output)
    ffmpeg -f concat -safe 0 -i $listFile -c copy $Output

    Write-Host "MJToVideo mode complete. Output: $Folder\$Output"
}

# =====================================================================
# MODE 2: MJInterpolate – image sequence -> optional interpolation -> video
# =====================================================================

function Run-MJInterpolateMode {
    Write-Host "Mode: MJInterpolate (image sequence -> interpolation -> video)"
    Write-Host ""

    $images = Get-ChildItem -Filter $PatternImages | Sort-Object Name
    if ($images.Count -eq 0) {
        Write-Host "ERROR: No images found matching '$PatternImages' in $Folder"
        return
    }

    Write-Host "Found $($images.Count) Midjourney image(s)."

    # Copy or link images into a dedicated frames folder to ensure clean naming
    $framesIn  = Join-Path $workDir "frames_in"
    $framesOut = Join-Path $workDir "frames_out"

    if (Test-Path $framesIn)  { Remove-Item $framesIn -Recurse -Force }
    if (Test-Path $framesOut) { Remove-Item $framesOut -Recurse -Force }

    New-Item -ItemType Directory -Path $framesIn  | Out-Null
    New-Item -ItemType Directory -Path $framesOut | Out-Null

    Write-Host "Copying frames into: $framesIn"

    $i = 0
    foreach ($img in $images) {
        $i++
        $name = "frame_{0:D4}.png" -f $i
        Copy-Item $img.FullName (Join-Path $framesIn $name)
    }

    if (-not [string]::IsNullOrWhiteSpace($InterpolationCommand)) {
        Write-Host "Running external interpolation command:"
        Write-Host "  $InterpolationCommand"
        Write-Host ""
        Write-Host "NOTE: You must edit -InterpolationCommand to call your installed tool, e.g.:"
        Write-Host "  rife-ncnn-vulkan -i `"$framesIn`" -o `"$framesOut`" -f 4"
        Write-Host ""

        # Replace placeholders in the command with real paths if you want:
        # Example convention: use {IN} and {OUT} as markers
        $cmd = $InterpolationCommand.Replace("{IN}", $framesIn).Replace("{OUT}", $framesOut)
        Invoke-Expression $cmd
    }
    else {
        Write-Host "No interpolation command set. Using raw frames for video."
        # In this case, use framesIn as source
        $framesOut = $framesIn
    }

    # Build video from framesOut
    Write-Host "Encoding frames into video with ffmpeg..."

    # Assume frame_0001.png, frame_0002.png, ... at 24 fps
    $framesPattern = Join-Path $framesOut "frame_%04d.png"
    Write-Host ("ffmpeg -framerate 24 -i `"{0}`" -c:v libx264 -pix_fmt yuv420p `"{1}`"" -f $framesPattern, $Output)
    ffmpeg -framerate 24 -i $framesPattern -c:v libx264 -pix_fmt yuv420p $Output

    Write-Host "MJInterpolate mode complete. Output: $Folder\$Output"
}

# =====================================================================
# MODE 3: MJStyleGrok – existing clips -> Grok-style unify -> stitched
# =====================================================================

function Invoke-GrokVideoClip {
    param(
        [string]$InputPath,
        [string]$OutputPath,
        [string]$Prompt
    )

    # TEMPLATE for Grok Video API.
    # You must set:
    #   - $GrokEndpoint
    #   - $GrokModel
    #   - any fields required by xAI once video API is available to you.
    $GrokEndpoint = "https://YOUR-GROK-VIDEO-ENDPOINT-HERE"
    $GrokModel    = "grok-imagine-video"   # placeholder

    $ApiKey = $Env:XAI_API_KEY
    if ([string]::IsNullOrWhiteSpace($ApiKey)) {
        Write-Host "ERROR: XAI_API_KEY environment variable is not set."
        Write-Host "Set it like this (example):"
        Write-Host '    setx XAI_API_KEY "your-real-xai-key-here"'
        Write-Host "Then open a NEW PowerShell window and run this mode again."
        return $null
    }

    Write-Host "Calling Grok Video API for clip: $InputPath"
    Write-Host "  Output -> $OutputPath"

    $headers = @{
        "Authorization" = "Bearer $ApiKey"
    }

    # Example generic form. Adjust to match the actual Grok video API once documented.
    $form = @{
        "file"   = Get-Item $InputPath
        "prompt" = $Prompt
        "model"  = $GrokModel
        "mode"   = "enhance"      # placeholder
    }

    try {
        $response = Invoke-RestMethod -Method Post -Uri $GrokEndpoint -Headers $headers -Form $form

        if ($response -is [byte[]]) {
            [System.IO.File]::WriteAllBytes($OutputPath, $response)
        }
        elseif ($response.video_url) {
            Write-Host "  Downloading from video_url: $($response.video_url)"
            Invoke-WebRequest -Uri $response.video_url -OutFile $OutputPath
        }
        else {
            Write-Host "WARNING: Unknown response shape from Grok Video API."
            $response | ConvertTo-Json -Depth 5
            return $null
        }

        if (Test-Path $OutputPath) {
            Write-Host "  Grok-processed clip saved: $OutputPath"
            return $OutputPath
        } else {
            Write-Host "  ERROR: Output file not created."
            return $null
        }
    }
    catch {
        Write-Host "ERROR calling Grok Video API:"
        Write-Host $_
        return $null
    }
}

function Run-MJStyleGrokMode {
    Write-Host "Mode: MJStyleGrok (clips -> Grok style unify -> stitched)"
    Write-Host ""

    $clips = Get-ChildItem -Filter $PatternClips | Sort-Object Name
    if ($clips.Count -eq 0) {
        Write-Host "ERROR: No clips found matching '$PatternClips' in $Folder"
        return
    }

    Write-Host "Found $($clips.Count) clip(s)."
    $processed = New-Object System.Collections.Generic.List[string]

    $index = 0
    foreach ($clip in $clips) {
        $index++
        $percent = [int](($index / $clips.Count) * 100)
        Write-Progress -Activity "Grok-style processing clips" -Status "Clip $index of $($clips.Count): $($clip.Name)" -PercentComplete $percent

        $outName = [System.IO.Path]::GetFileNameWithoutExtension($clip.Name) + "_grok.mp4"
        $outPath = Join-Path $workDir $outName

        $res = Invoke-GrokVideoClip -InputPath $clip.FullName -OutputPath $outPath -Prompt $GrokStylePrompt
        if ($null -ne $res) {
            $processed.Add($res) | Out-Null
        } else {
            Write-Host "  WARNING: Using original clip due to Grok failure: $($clip.FullName)"
            $processed.Add($clip.FullName) | Out-Null
        }
    }

    Write-Progress -Activity "Grok-style processing clips" -Completed -Status "Done"
    Write-Host ""

    if ($processed.Count -eq 0) {
        Write-Host "ERROR: No clips available to stitch."
        return
    }

    # Build concat list
    $listFile = Join-Path $workDir "grokstyle_concat.txt"
    $lines = $processed | ForEach-Object {
        "file '" + (Split-Path $_ -Leaf) + "'"
    }
    $lines | Set-Content -Path $listFile -Encoding ascii

    Write-Host "Stitching Grok-styled clips with ffmpeg..."
    Write-Host ("ffmpeg -f concat -safe 0 -i `"{0}`" -c copy `"{1}`"" -f $listFile, $Output)
    ffmpeg -f concat -safe 0 -i $listFile -c copy $Output

    Write-Host "MJStyleGrok mode complete. Output: $Folder\$Output"
}

# =====================================================================
# DISPATCH
# =====================================================================

switch ($Mode) {
    "MJToVideo"     { Run-MJToVideoMode }
    "MJInterpolate" { Run-MJInterpolateMode }
    "MJStyleGrok"   { Run-MJStyleGrokMode }
    default {
        Write-Host "Unknown mode: $Mode"
        exit 1
    }
}
