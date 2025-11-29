# ffmpeg-utils.ps1
# Utility functions for ffmpeg operations

function Invoke-FFmpeg {
    param(
        [string[]]$Arguments
    )
    
    Write-Host "Running ffmpeg with arguments: $($Arguments -join ' ')"
    ffmpeg @Arguments
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: ffmpeg failed with exit code $LASTEXITCODE"
        return $false
    }
    return $true
}

function Get-VideoInfo {
    param([string]$VideoPath)
    
    if (-not (Get-Command ffprobe -ErrorAction SilentlyContinue)) {
        Write-Host "WARNING: ffprobe not found"
        return $null
    }
    
    $info = @{}
    
    # Get duration
    $duration = ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1:noescapes=1 $VideoPath
    $info.Duration = [double]$duration
    
    # Get resolution
    $width = ffprobe -v error -select_streams v:0 -show_entries stream=width -of default=noprint_wrappers=1:nokey=1:noescapes=1 $VideoPath
    $height = ffprobe -v error -select_streams v:0 -show_entries stream=height -of default=noprint_wrappers=1:nokey=1:noescapes=1 $VideoPath
    $info.Width = [int]$width
    $info.Height = [int]$height
    
    # Get FPS
    $fps = ffprobe -v error -select_streams v:0 -show_entries stream=r_frame_rate -of default=noprint_wrappers=1:nokey=1:noescapes=1 $VideoPath
    $info.FPS = $fps
    
    return $info
}

function Convert-Video {
    param(
        [string]$InputFile,
        [string]$OutputFile,
        [int]$FPS = 24,
        [string]$Codec = "libx264",
        [string]$Preset = "medium"
    )
    
    $args = @(
        "-i", $InputFile,
        "-r", $FPS,
        "-c:v", $Codec,
        "-preset", $Preset,
        "-c:a", "aac",
        "-y",
        $OutputFile
    )
    
    return Invoke-FFmpeg -Arguments $args
}

function Extract-Frames {
    param(
        [string]$VideoPath,
        [string]$OutputFolder,
        [int]$FPS = 24
    )
    
    if (-not (Test-Path $OutputFolder)) {
        New-Item -ItemType Directory -Path $OutputFolder | Out-Null
    }
    
    $framePattern = Join-Path $OutputFolder "frame_%06d.png"
    $args = @(
        "-i", $VideoPath,
        "-vf", "fps=$FPS",
        "-y",
        $framePattern
    )
    
    return Invoke-FFmpeg -Arguments $args
}

function Stitch-Frames {
    param(
        [string]$FrameFolder,
        [string]$OutputFile,
        [int]$FPS = 24
    )
    
    $framePattern = Join-Path $FrameFolder "frame_%06d.png"
    $args = @(
        "-framerate", $FPS,
        "-i", $framePattern,
        "-c:v", "libx264",
        "-preset", "medium",
        "-pix_fmt", "yuv420p",
        "-y",
        $OutputFile
    )
    
    return Invoke-FFmpeg -Arguments $args
}

function Upscale-Video {
    param(
        [string]$InputFile,
        [string]$OutputFile,
        [int]$ScaleFactor = 2
    )
    
    $newWidth = "iw*$ScaleFactor"
    $newHeight = "ih*$ScaleFactor"
    
    $args = @(
        "-i", $InputFile,
        "-vf", "scale=$newWidth`:$newHeight",
        "-c:v", "libx264",
        "-preset", "slow",
        "-crf", "18",
        "-y",
        $OutputFile
    )
    
    return Invoke-FFmpeg -Arguments $args
}

function Concat-Videos {
    param(
        [string[]]$VideoFiles,
        [string]$OutputFile
    )
    
    $listFile = "concat_list_$(Get-Random).txt"
    
    $VideoFiles | ForEach-Object { "file '$_'" } | Set-Content $listFile
    
    $args = @(
        "-f", "concat",
        "-safe", "0",
        "-i", $listFile,
        "-c", "copy",
        "-y",
        $OutputFile
    )
    
    $result = Invoke-FFmpeg -Arguments $args
    Remove-Item $listFile -Force -ErrorAction SilentlyContinue
    
    return $result
}

Export-ModuleMember -Function Get-VideoInfo, Convert-Video, Extract-Frames, Stitch-Frames, Upscale-Video, Concat-Videos, Invoke-FFmpeg
