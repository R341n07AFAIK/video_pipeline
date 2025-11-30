<#
Uninstall script for Video Pipeline
- Removes installed files
- Removes Start Menu shortcuts
- Removes uninstall registry entry

Usage: Run as Administrator
#>

param(
    [string]$InstallDir = "$env:ProgramFiles\\VideoPipeline",
    [switch]$Confirm
)

function Write-Log { param($m) Write-Host "[$((Get-Date).ToString('s'))] $m" }

function Assert-Elevated {
    if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Log "This operation requires elevation. Relaunching as administrator..."
        Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
        exit 0
    }
}

function Remove-StartMenuShortcuts {
    $startMenu = [Environment]::GetFolderPath('Programs')
    $folder = Join-Path $startMenu 'Video Pipeline'
    if (Test-Path $folder) {
        Remove-Item -Path $folder -Recurse -Force -ErrorAction SilentlyContinue
        Write-Log "Removed Start Menu shortcuts at $folder"
    }
}

function Remove-UninstallRegistry {
    $key = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\VideoPipeline"
    if (Test-Path $key) {
        Remove-Item -Path $key -Recurse -Force -ErrorAction SilentlyContinue
        Write-Log "Removed uninstall registry entry"
    }
}

function Remove-InstallFolder {
    if (Test-Path $InstallDir) {
        if ($Confirm) {
            $yn = Read-Host "Remove install folder $InstallDir ? (Y/N)"
            if ($yn -notin @('Y','y')) { Write-Log "Skipping folder removal."; return }
        }
        Remove-Item -Path $InstallDir -Recurse -Force -ErrorAction SilentlyContinue
        Write-Log "Removed folder: $InstallDir"
    }
    else { Write-Log "Install folder not found: $InstallDir" }
}

try {
    Assert-Elevated
    Remove-StartMenuShortcuts
    Remove-UninstallRegistry
    Remove-InstallFolder
    Write-Log "Uninstall completed."
}
catch {
    Write-Log "Uninstall failed: $_"
    exit 1
}
