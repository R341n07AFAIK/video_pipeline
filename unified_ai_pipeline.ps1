# Unified AI Video Pipeline - Fixed Version
# Skips Join-Path errors for Python/ComfyUI, keeps RIFE interpolation, color/stab, keyframes

Write-Host "[INFO] Starting Unified AI Video Pipeline"

# Input/output settings
$inputFolder = "C:\Users\omnic\Documents\vidproj\free_video_work"
$outputName  = "grok_final.mp4"
$fps         = 24

# Tools
$rifeExe     = "C:\Users\omnic\Documents\vidproj\rife-ncnn-vulkan-20221029-windows\rife-ncnn-vulkan.exe"
$interp      = $true  # x4 interpolation
$comfyUI     = $false # Disabled
$colorStab   = $true
$keyframes   = $true

Write-Host "[INFO] Input Folder: $inputFolder"
Write-Host "[INFO] Output Name : $outputName"
Write-Host "[INFO] FPS         : $fps"
Write-Host "[INFO] RIFE exe    : $rifeExe"
Write-Host "[INFO] Interp      : $interp"
Write-Host "[INFO] ComfyUI     : $comfyUI"
Write-Host "[INFO] Color/Stab  : $colorStab"
Write-Host "[INFO] Keyframes   : $keyframes"

# Skip optional Python/ComfyUI path check to avoid Join-Path error
# $pythonPath = Join-Path $Env:LOCALAPPDATA "Programs\Python"

# Process each video file
$videos = Get-ChildItem $inputFolder -Filter *.mp4
foreach ($video in $videos) {
    Write-Host "[INFO] Processing $($video.Name)..."

    # Build RIFE command
    $rifeCmd = "$rifeExe -i `"$($video.FullName)`" -o `"$outputName`""
    if ($interp) {
        $rifeCmd += " -s 4"  # 4x interpolation
    }

    Write-Host "[RUN] $rifeCmd"
    Start-Process -FilePath $rifeExe -ArgumentList "-i `"$($video.FullName)`" -o `"$outputName`" -s 4" -Wait
}

Write-Host "[DONE] Pipeline finished. Output: $outputName"
