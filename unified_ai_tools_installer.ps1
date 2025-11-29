# unified_ai_tools_installer.ps1
# One-shot installer for free, local AI video tools.
# Installs:
#   - Python 3.x (via winget, if needed)
#   - Git
#   - FFmpeg
#   - 7zip
#   - RIFE (portable)
#   - FILM (Google frame interpolation)
#   - Stable Video Diffusion (SVD)
#   - Real-ESRGAN
#   - ComfyUI
#
# All AI tools go under:
#   C:\AItools\
#
# This script does NOT rely on 'python' being on PATH.
# It searches for python.exe directly and then uses:
#   <python.exe> -m pip ...
#
# Usage (PowerShell):
#   powershell -ExecutionPolicy Bypass -File .\unified_ai_tools_installer.ps1

param(
    [string]$Root = "C:\AItools"
)

Write-Host "=== Unified AI Tools Installer ==="
Write-Host "Root directory: $Root"
Write-Host ""

# Ensure root directory
New-Item -ItemType Directory -Force -Path $Root | Out-Null

function Run-WingetInstall {
    param(
        [string]$Id
    )
    Write-Host "-> Installing via winget: $Id"
    winget install --id $Id --source winget --accept-package-agreements --accept-source-agreements
}

function Ensure-Git {
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Host "Git not found on PATH. Installing Git..."
        Run-WingetInstall -Id "Git.Git"
    } else {
        Write-Host "Git already available on PATH."
    }
}

function Ensure-FFmpeg {
    if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
        Write-Host "FFmpeg not found on PATH. Installing FFmpeg..."
        Run-WingetInstall -Id "Gyan.FFmpeg"
    } else {
        Write-Host "FFmpeg already available on PATH."
    }
}

function Ensure-7zip {
    if (-not (Get-Command 7z -ErrorAction SilentlyContinue)) {
        Write-Host "7zip not found on PATH. Installing 7zip..."
        Run-WingetInstall -Id "7zip.7zip"
    } else {
        Write-Host "7zip already available on PATH (or equivalent)."
    }
}

function Ensure-PythonInstalled {
    # If any python.exe is already on disk in standard locations, we won't force winget again.
    $pythonFound = $false

    $candidates = @(
        Join-Path $Env:LOCALAPPDATA "Programs\Python",
        "C:\Program Files",
        "C:\Program Files (x86)"
    )

    foreach ($base in $candidates) {
        if (Test-Path $base) {
            $pyDirs = Get-ChildItem $base -Directory -ErrorAction SilentlyContinue | Where-Object {
                $_.Name -like "Python*"
            }
            if ($pyDirs.Count -gt 0) {
                $pythonFound = $true
                break
            }
        }
    }

    if (-not $pythonFound) {
        Write-Host "Python not found in standard locations. Installing Python 3.12..."
        Run-WingetInstall -Id "Python.Python.3.12"
    } else {
        Write-Host "Python installation detected on disk (one or more Python* directories)."
    }
}

function Find-PythonExe {
    # Try to find a real python.exe in common install locations, ignoring Store alias.
    $pathsToCheck = @()

    $pathsToCheck += Join-Path $Env:LOCALAPPDATA "Programs\Python"
    $pathsToCheck += "C:\Program Files"
    $pathsToCheck += "C:\Program Files (x86)"

    foreach ($base in $pathsToCheck) {
        if (Test-Path $base) {
            $pyDirs = Get-ChildItem $base -Directory -ErrorAction SilentlyContinue | Where-Object {
                $_.Name -like "Python*"
            }
            foreach ($dir in $pyDirs) {
                $candidate = Join-Path $dir.FullName "python.exe"
                if (Test-Path $candidate) {
                    return $candidate
                }
            }
        }
    }

    # Fallback: try Get-Command python, but beware of Store alias
    $cmd = Get-Command python -ErrorAction SilentlyContinue
    if ($cmd -and $cmd.Source -and ($cmd.Source -notlike "*WindowsApps\python.exe")) {
        return $cmd.Source
    }

    return $null
}

function Pip-InstallRequirements {
    param(
        [string]$PythonExe,
        [string]$RequirementsPath
    )

    if (-not (Test-Path $RequirementsPath)) {
        Write-Host "  [pip] requirements.txt not found at $RequirementsPath, skipping."
        return
    }

    Write-Host "  [pip] Installing requirements from: $RequirementsPath"
    & $PythonExe -m pip install --upgrade pip
    & $PythonExe -m pip install -r $RequirementsPath
}


# 1) Core tools
Write-Host "[1/10] Ensuring Git..."
Ensure-Git
Write-Host ""

Write-Host "[2/10] Ensuring FFmpeg..."
Ensure-FFmpeg
Write-Host ""

Write-Host "[3/10] Ensuring 7zip..."
Ensure-7zip
Write-Host ""

Write-Host "[4/10] Ensuring Python is installed..."
Ensure-PythonInstalled
Write-Host ""

# 2) Locate Python executable
Write-Host "[5/10] Locating Python executable..."
$pythonExe = Find-PythonExe

if (-not $pythonExe) {
    Write-Host "ERROR: Could not find a real python.exe installation."
    Write-Host "Please ensure Python is installed (via winget or python.org), then re-run this script."
    exit 1
}

Write-Host "Using Python at: $pythonExe"
& $pythonExe --version
Write-Host ""

# 3) AI tools

# RIFE (portable)
Write-Host "[6/10] Installing RIFE (portable)..."
$rife = Join-Path $Root "rife"
New-Item -ItemType Directory -Force -Path $rife | Out-Null
$rifeZip = Join-Path $rife "rife.zip"

try {
    Invoke-WebRequest -Uri "https://github.com/nihui/rife-ncnn-vulkan/releases/download/20220714/rife-ncnn-vulkan-20220714-windows.zip" -OutFile $rifeZip
    Expand-Archive $rifeZip -DestinationPath $rife -Force
    Remove-Item $rifeZip -Force
    Write-Host "  RIFE installed to: $rife"
} catch {
    Write-Host "  WARNING: Failed to download or extract RIFE. You can install it manually later."
}

# FILM
Write-Host "[7/10] Installing FILM (Google Frame Interpolation)..."
$film = Join-Path $Root "film"
if (!(Test-Path $film)) {
    git clone https://github.com/google-research/frame-interpolation.git $film
} else {
    Write-Host "  FILM directory already exists, skipping clone."
}
Pip-InstallRequirements -PythonExe $pythonExe -RequirementsPath (Join-Path $film "requirements.txt")

# Stable Video Diffusion
Write-Host "[8/10] Installing Stable Video Diffusion..."
$svd = Join-Path $Root "svd"
if (!(Test-Path $svd)) {
    git clone https://github.com/Stability-AI/stable-video-diffusion $svd
} else {
    Write-Host "  SVD directory already exists, skipping clone."
}
Pip-InstallRequirements -PythonExe $pythonExe -RequirementsPath (Join-Path $svd "requirements.txt")

# Real-ESRGAN
Write-Host "[9/10] Installing Real-ESRGAN..."
$realsr = Join-Path $Root "realesrgan"
if (!(Test-Path $realsr)) {
    git clone https://github.com/xinntao/Real-ESRGAN.git $realsr
} else {
    Write-Host "  Real-ESRGAN directory already exists, skipping clone."
}
Pip-InstallRequirements -PythonExe $pythonExe -RequirementsPath (Join-Path $realsr "requirements.txt")

# ComfyUI
Write-Host "[10/10] Installing ComfyUI..."
$comfy = Join-Path $Root "comfyui"
if (!(Test-Path $comfy)) {
    git clone https://github.com/comfyanonymous/ComfyUI.git $comfy
} else {
    Write-Host "  ComfyUI directory already exists, skipping clone."
}
Pip-InstallRequirements -PythonExe $pythonExe -RequirementsPath (Join-Path $comfy "requirements.txt")

# PATH update (optional quality-of-life)
Write-Host ""
Write-Host "Updating PATH for convenience (user-level)..."
$currentPath = [System.Environment]::GetEnvironmentVariable("PATH", "User")
$pathsToAdd = @($rife, $film, $svd, $realsr, $comfy)

foreach ($p in $pathsToAdd) {
    if ($currentPath -notlike "*$p*") {
        $currentPath += ";" + $p
    }
}

[System.Environment]::SetEnvironmentVariable("PATH", $currentPath, "User")

Write-Host ""
Write-Host "=== Installation Complete ==="
Write-Host "Tools installed in: $Root"
Write-Host "Open a NEW PowerShell window for PATH changes to apply."
