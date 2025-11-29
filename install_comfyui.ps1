# ComfyUI Installer Script for Windows
$ErrorActionPreference = "Stop"

$installDir = "C:\Users\omnic\Documents\vidproj\generators\comfyui"

# Create directory if it doesn't exist
if (-not (Test-Path $installDir)) {
    New-Item -ItemType Directory -Path $installDir -Force
}

Write-Host "Installing ComfyUI into $installDir..."

# Clone ComfyUI repository
if (-not (Test-Path "$installDir\.git")) {
    git clone https://github.com/comfyanonymous/ComfyUI.git $installDir
} else {
    Write-Host "ComfyUI repository already exists, pulling latest changes..."
    git -C $installDir pull
}

# Install Python dependencies
$pythonExe = "python"  # ensure python is in PATH
Write-Host "Installing Python requirements..."
& $pythonExe -m pip install --upgrade pip
& $pythonExe -m pip install -r "$installDir\requirements.txt"

Write-Host "ComfyUI installation complete!"
