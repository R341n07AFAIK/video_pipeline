# install_free_ai_tools.ps1
# Installs free, local AI video tools using Winget + Git + Python.
# Tools:
#   - FFmpeg
#   - Python 3.12
#   - Git
#   - 7zip
#   - RIFE (portable)
#   - FILM (Google frame interpolation)
#   - Stable Video Diffusion (SVD)
#   - Real-ESRGAN
#   - ComfyUI
#
# All AI tools are placed under:
#   C:\AItools\
#
# Python packages are installed using: python -m pip
# so it works even if 'pip' is not directly on PATH.

param(
    [string]$Root = "C:\AItools"
)

Write-Host "=== Free Local AI Tools Installer ==="
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

function Ensure-Python {
    if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
        Write-Host "Python not found on PATH. Installing Python 3.12..."
        Run-WingetInstall -Id "Python.Python.3.12"
    } else {
        Write-Host "Python already available on PATH."
    }

    # Verify
    $python = Get-Command python -ErrorAction SilentlyContinue
    if (-not $python) {
        Write-Host "ERROR: Python installation could not be verified. Please open a NEW PowerShell window and try again."
        exit 1
    }

    Write-Host "Python path: $($python.Source)"
    Write-Host "Python version:"
    python --version
}

function Ensure-Git {
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Host "Git not found on PATH. Installing Git..."
        Run-WingetInstall -Id "Git.Git"
    } else {
        Write-Host "Git already available on PATH."
    }

    $git = Get-Command git -ErrorAction SilentlyContinue
    if (-not $git) {
        Write-Host "ERROR: Git installation could not be verified."
        exit 1
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
        Write-Host "7zip / p7zip already on PATH (or equivalent)."
    }
}

function Pip-InstallRequirements {
    param(
        [string]$RequirementsPath
    )

    if (-not (Test-Path $RequirementsPath)) {
        Write-Host "  [pip] requirements.txt not found at $RequirementsPath, skipping."
        return
    }

    Write-Host "  [pip] Installing requirements from: $RequirementsPath"
    python -m pip install --upgrade pip
    python -m pip install -r $RequirementsPath
}

# 1) Core tools
Write-Host "[1/10] Ensuring Python..."
Ensure-Python
Write-Host ""

Write-Host "[2/10] Ensuring Git..."
Ensure-Git
Write-Host ""

Write-Host "[3/10] Ensuring FFmpeg..."
Ensure-FFmpeg
Write-Host ""

Write-Host "[4/10] Ensuring 7zip..."
Ensure-7zip
Write-Host ""

# 2) AI tools

# RIFE (portable)
Write-Host "[5/10] Installing RIFE (portable)..."
$rife = Join-Path $Root "rife"
New-Item -ItemType Directory -Force -Path $rife | Out-Null
$rifeZip = Join-Path $rife "rife.zip"
Invoke-WebRequest -Uri "https://github.com/nihui/rife-ncnn-vulkan/releases/latest/download/rife-ncnn-vulkan-20220709-windows.zip" -OutFile $rifeZip
Expand-Archive $rifeZip -DestinationPath $rife -Force
Remove-Item $rifeZip -Force

# FILM
Write-Host "[6/10] Installing FILM (Google Frame Interpolation)..."
$film = Join-Path $Root "film"
if (!(Test-Path $film)) {
    git clone https://github.com/google-research/frame-interpolation.git $film
} else {
    Write-Host "  FILM directory already exists, skipping clone."
}
Pip-InstallRequirements -RequirementsPath (Join-Path $film "requirements.txt")

# Stable Video Diffusion
Write-Host "[7/10] Installing Stable Video Diffusion..."
$svd = Join-Path $Root "svd"
if (!(Test-Path $svd)) {
    git clone https://github.com/Stability-AI/stable-video-diffusion.git $svd
} else {
    Write-Host "  SVD directory already exists, skipping clone."
}
Pip-InstallRequirements -RequirementsPath (Join-Path $svd "requirements.txt")

# Real-ESRGAN
Write-Host "[8/10] Installing Real-ESRGAN..."
$realsr = Join-Path $Root "realesrgan"
if (!(Test-Path $realsr)) {
    git clone https://github.com/xinntao/Real-ESRGAN.git $realsr
} else {
    Write-Host "  Real-ESRGAN directory already exists, skipping clone."
}
Pip-InstallRequirements -RequirementsPath (Join-Path $realsr "requirements.txt")

# ComfyUI
Write-Host "[9/10] Installing ComfyUI..."
$comfy = Join-Path $Root "comfyui"
if (!(Test-Path $comfy)) {
    git clone https://github.com/comfyanonymous/ComfyUI.git $comfy
} else {
    Write-Host "  ComfyUI directory already exists, skipping clone."
}
Pip-InstallRequirements -RequirementsPath (Join-Path $comfy "requirements.txt")

# PATH update
Write-Host "[10/10] Updating PATH for AI tools..."

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
Write-Host "You may need to open a NEW PowerShell window for PATH changes to take effect."
