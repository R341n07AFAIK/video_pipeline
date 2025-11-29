# grok_superflow.ps1
# Grok Superflow: process clips through Grok Video API and stitch into one long video.
# IMPORTANT:
# - This is a TEMPLATE. You MUST adjust the $VideoEndpoint, form fields, and response handling
#   to match the actual xAI / Grok Imagine Video API you have access to.
# - Requires:
#     * PowerShell 5+ or 7+
#     * ffmpeg on PATH
#     * XAI_API_KEY environment variable set to your xAI API key

param(
    [string]$Folder = "C:\Users\omnic\Documents\Documents\vidproj",
    [string]$Pattern = "*.mp4",
    [string]$Output = "grok_superflow_final.mp4",
    [string]$StylePrompt = "Unify all clips into a single Grok-style cinematic with consistent color, motion, and atmosphere.",
    [switch]$GenerateTransitions
)

Write-Host "=== Grok Superflow ==="
Write-Host "Folder              : $Folder"
Write-Host "Pattern             : $Pattern"
Write-Host "Output              : $Output"
Write-Host "GenerateTransitions : $GenerateTransitions"
Write-Host ""

# ---------- CONFIGURABLE API SETTINGS ----------
# TODO: Change this to the correct Grok Video / Imagine endpoint for your account.
# Check official xAI docs or your integration provider for the right URL and fields.
$VideoEndpoint = "https://YOUR-GROK-VIDEO-ENDPOINT-HERE"

# Name for the video model / mode if required by your API.
$VideoModel = "grok-imagine-video"  # EXAMPLE ONLY – replace with real model name if needed.

# Grab API key from environment variable
$ApiKey = $Env:XAI_API_KEY
if ([string]::IsNullOrWhiteSpace($ApiKey)) {
    Write-Host "ERROR: XAI_API_KEY environment variable is not set."
    Write-Host "Set it like this (example):"
    Write-Host '    setx XAI_API_KEY "your-real-xai-key-here"'
    Write-Host "Then open a NEW PowerShell window and run this script again."
    exit 1
}

# ---------- BASIC SANITY CHECKS ----------

if (!(Test-Path $Folder)) {
    Write-Host "ERROR: Folder not found: $Folder"
    exit 1
}

if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: ffmpeg is not on PATH."
    Write-Host "Install it (once) with:"
    Write-Host "    winget install --id Gyan.FFmpeg --source winget"
    Write-Host "Then open a NEW PowerShell window and run this script again."
    exit 1
}

Set-Location $Folder

$clips = Get-ChildItem -Filter $Pattern | Sort-Object Name
if ($clips.Count -eq 0) {
    Write-Host "ERROR: No clips found matching pattern '$Pattern' in $Folder"
    exit 1
}

Write-Host "Found $($clips.Count) clip(s)."
Write-Host ""

# Create working subfolder
$workDir = Join-Path $Folder "grok_superflow_work"
if (!(Test-Path $workDir)) {
    New-Item -ItemType Directory -Path $workDir | Out-Null
}

# Lists to track processed clips in order
$processedClips = New-Object System.Collections.Generic.List[string]
$transitionClips = New-Object System.Collections.Generic.List[string]

# ---------- HELPER: CALL GROK VIDEO API FOR A SINGLE CLIP ----------

function Invoke-GrokVideoClip {
    param(
        [string]$InputPath,
        [string]$OutputPath,
        [string]$Prompt
    )

    Write-Host "Calling Grok Video API for: $InputPath"
    Write-Host "  Output -> $OutputPath"

    # EXAMPLE multipart/form-data call.
    # You MUST adjust the form keys (file, prompt, model, etc.) and response handling
    # to match your actual Grok Imagine / Video API.
    $headers = @{
        "Authorization" = "Bearer $ApiKey"
    }

    # NOTE:
    # Many APIs accept multipart form with -Form:
    #   - file: binary file upload
    #   - prompt: text description
    #   - model / mode: which generator to use
    #
    # This is a *placeholder shape* – confirm against your real docs.
    $form = @{
        "file"   = Get-Item $InputPath
        "prompt" = $Prompt
        "model"  = $VideoModel
        "mode"   = "enhance"      # EXAMPLE – adjust or remove as needed
    }

    try {
        $response = Invoke-RestMethod -Method Post -Uri $VideoEndpoint -Headers $headers -Form $form

        # TODO: Adjust this to match your real response format.
        # Common patterns:
        #  - Direct file bytes (then you write them to disk)
        #  - JSON with a 'video_url' field you must download
        #  - JSON with a 'result' object, etc.

        if ($response -is [byte[]]) {
            # Direct binary response
            [System.IO.File]::WriteAllBytes($OutputPath, $response)
        }
        elseif ($response.video_url) {
            Write-Host "  Downloading from video_url: $($response.video_url)"
            Invoke-WebRequest -Uri $response.video_url -OutFile $OutputPath
        }
        else {
            Write-Host "WARNING: Unknown response shape from Grok Video API."
            Write-Host "Raw response:"
            $response | ConvertTo-Json -Depth 5
            Write-Host "No output written for this clip."
            return $null
        }

        if (Test-Path $OutputPath) {
            Write-Host "  Grok-processed clip saved: $OutputPath"
            return $OutputPath
        } else {
            Write-Host "  ERROR: Output file was not created."
            return $null
        }
    }
    catch {
        Write-Host "ERROR calling Grok Video API:"
        Write-Host $_
        return $null
    }
}

# ---------- HELPER: CALL GROK VIDEO API TO GENERATE A TRANSITION ----------

function Invoke-GrokTransitionClip {
    param(
        [string]$PrevClip,
        [string]$NextClip,
        [string]$OutputPath
    )

    $transitionPrompt = @"
Create a smooth cinematic transition that connects these two clips.
Match color, motion, and atmosphere so the cut feels natural.
Use visual motifs from both inputs and blend them.
"@

    Write-Host "Calling Grok Video API for transition:"
    Write-Host "  From: $PrevClip"
    Write-Host "  To  : $NextClip"
    Write-Host "  Out : $OutputPath"

    $headers = @{
        "Authorization" = "Bearer $ApiKey"
    }

    # EXAMPLE ONLY: assuming API can accept two files for a transition.
    # Real API shape may differ – check docs.
    $form = @{
        "prev_clip" = Get-Item $PrevClip
        "next_clip" = Get-Item $NextClip
        "prompt"    = $transitionPrompt
        "model"     = $VideoModel
        "mode"      = "transition"   # EXAMPLE – adjust or remove as needed
    }

    try {
        $response = Invoke-RestMethod -Method Post -Uri $VideoEndpoint -Headers $headers -Form $form

        if ($response -is [byte[]]) {
            [System.IO.File]::WriteAllBytes($OutputPath, $response)
        }
        elseif ($response.video_url) {
            Write-Host "  Downloading transition from video_url: $($response.video_url)"
            Invoke-WebRequest -Uri $response.video_url -OutFile $OutputPath
        }
        else {
            Write-Host "WARNING: Unknown response shape for transition."
            $response | ConvertTo-Json -Depth 5
            return $null
        }

        if (Test-Path $OutputPath) {
            Write-Host "  Transition clip saved: $OutputPath"
            return $OutputPath
        } else {
            Write-Host "  ERROR: Transition output file was not created."
            return $null
        }
    }
    catch {
        Write-Host "ERROR calling Grok Video API for transition:"
        Write-Host $_
        return $null
    }
}

# ---------- PHASE 1: PROCESS EACH CLIP THROUGH GROK VIDEO ----------

Write-Host ""
Write-Host "Phase 1: Processing each clip via Grok Video API..."
Write-Host ""

$index = 0
foreach ($clip in $clips) {
    $index++
    $percent = [int](($index / $clips.Count) * 100)
    Write-Progress -Activity "Grok processing clips" -Status "Clip $index of $($clips.Count): $($clip.Name)" -PercentComplete $percent

    $outName = [System.IO.Path]::GetFileNameWithoutExtension($clip.Name) + "_grok.mp4"
    $outPath = Join-Path $workDir $outName

    $result = Invoke-GrokVideoClip -InputPath $clip.FullName -OutputPath $outPath -Prompt $StylePrompt
    if ($null -ne $result) {
        $processedClips.Add($result) | Out-Null
    } else {
        # Fallback: use original clip if processing failed
        Write-Host "  WARNING: Using original clip due to Grok failure: $($clip.FullName)"
        $processedClips.Add($clip.FullName) | Out-Null
    }
}

Write-Progress -Activity "Grok processing clips" -Completed -Status "Done"
Write-Host ""
Write-Host "Phase 1 complete. $($processedClips.Count) clip(s) ready."
Write-Host ""

# ---------- PHASE 2: OPTIONAL TRANSITIONS ----------

if ($GenerateTransitions -and $processedClips.Count -gt 1) {
    Write-Host "Phase 2: Generating transition clips between processed clips..."
    Write-Host ""

    for ($i = 0; $i -lt $processedClips.Count - 1; $i++) {
        $fromClip = $processedClips[$i]
        $toClip   = $processedClips[$i + 1]
        $transName = "transition_{0:000}.mp4" -f $i
        $transPath = Join-Path $workDir $transName

        $percent = [int](($i / ($processedClips.Count - 1)) * 100)
        Write-Progress -Activity "Generating transitions" -Status "Between clip $($i+1) and $($i+2)" -PercentComplete $percent

        $tResult = Invoke-GrokTransitionClip -PrevClip $fromClip -NextClip $toClip -OutputPath $transPath
        if ($null -ne $tResult) {
            $transitionClips.Add($tResult) | Out-Null
        } else {
            Write-Host "  WARNING: Transition failed for pair $($i+1) -> $($i+2). Skipping."
        }
    }

    Write-Progress -Activity "Generating transitions" -Completed -Status "Done"
    Write-Host ""
    Write-Host "Phase 2 complete. $($transitionClips.Count) transition clip(s) generated."
    Write-Host ""
}
else {
    Write-Host "Phase 2: Transitions disabled or not needed (only one clip)."
    Write-Host ""
}

# ---------- PHASE 3: BUILD CONCAT LIST AND STITCH WITH FFMPEG ----------

Write-Host "Phase 3: Building concat list and stitching with ffmpeg..."
Write-Host ""

$listFile = Join-Path $workDir "clips_final.txt"

# Build final sequence:
# If transitions exist, order like:
#   clip1, t1, clip2, t2, clip3, ...
# Otherwise, just processed clips.
$lines = New-Object System.Collections.Generic.List[string]

if ($GenerateTransitions -and $transitionClips.Count -gt 0) {
    for ($i = 0; $i -lt $processedClips.Count; $i++) {
        $lines.Add(("file '{0}'" -f (Split-Path $processedClips[$i] -Leaf))) | Out-Null
        if ($i -lt $transitionClips.Count) {
            $lines.Add(("file '{0}'" -f (Split-Path $transitionClips[$i] -Leaf))) | Out-Null
        }
    }
} else {
    foreach ($pc in $processedClips) {
        $lines.Add(("file '{0}'" -f (Split-Path $pc -Leaf))) | Out-Null
    }
}

# Write concat list as ASCII (no BOM)
$lines | Set-Content -Path $listFile -Encoding ascii

Write-Host "Concat list written to: $listFile"
Write-Host ""

# Run ffmpeg concat
Write-Host ("Executing ffmpeg concat to create: {0}" -f $Output)
Write-Host ("ffmpeg -f concat -safe 0 -i `"{0}`" -c copy `"{1}`"" -f $listFile, $Output)
Write-Host ""

ffmpeg -f concat -safe 0 -i $listFile -c copy $Output

Write-Host ""
Write-Host "=== Grok Superflow complete ==="
Write-Host ("Final video: {0}\{1}" -f $Folder, $Output)
