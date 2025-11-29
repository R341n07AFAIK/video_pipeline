<#
Video Pipeline Installer Bootstrap

This script performs an elevated install of the current repository into
"Program Files\VideoPipeline" (by default). It checks prerequisites,
copies files, creates Start Menu shortcuts, registers an uninstall entry,
and optionally launches the main GUI.

Usage:
  - Run from the distribution folder (where this script sits).
  - Recommended to compile to EXE (ps2exe) and bundle with Inno Setup.

Note: This script requires elevation to write to Program Files and the registry.
#>

param(
    [string]$InstallDir = "$env:ProgramFiles\\VideoPipeline",
    [switch]$Force,
    [switch]$NoLaunch
)

# Load installer settings if present (installer_settings.json)
$settingsPath = Join-Path (Split-Path -Parent $PSCommandPath) 'installer_settings.json'
if (Test-Path $settingsPath) {
    try {
        $raw = Get-Content $settingsPath -Raw -ErrorAction Stop
        $cfg = $raw | ConvertFrom-Json -ErrorAction Stop

        if ($cfg.installDir) { $InstallDir = $cfg.installDir }
        if ($cfg.force -eq $true) { $Force = $true }
        if ($cfg.noLaunch -eq $true) { $NoLaunch = $true }

        # Additional settings are available in $cfg during runtime
        Write-Log "Loaded installer settings from $settingsPath"
    }
    catch {
        Write-Log "Failed to parse installer_settings.json: $_";
    }
}

function Write-Log {
    param([string]$Msg)
    $ts = (Get-Date).ToString('s')
    Write-Host "[$ts] $Msg"
}

function Ensure-Elevated {
    if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Log "Not elevated. Relaunching with elevation..."
        $args = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
        if ($Force) { $args += " -Force" }
        if ($NoLaunch) { $args += " -NoLaunch" }
        Start-Process -FilePath "powershell.exe" -ArgumentList $args -Verb RunAs
        exit 0
    }
}

function Test-PrerequisitesLocal {
    Write-Log "Testing prerequisites..."
    $issues = @()

    # FFmpeg
    if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
        $issues += 'FFmpeg (not found on PATH)'
    }

    # Python
    if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
        $issues += 'Python (not found on PATH)'
    }

    if ($issues.Count -gt 0) {
        Write-Log "Prerequisite issues found: $($issues -join ', ')"
        return @{ Ok = $false; Issues = $issues }
    }
    else {
        Write-Log "All quick prerequisites present (FFmpeg, Python may be available)."
        return @{ Ok = $true }
    }
}

function Compare-Version {
    param(
        [string]$have,
        [string]$need
    )
    try {
        $hv = [version]($have -replace '[^0-9\.].*','')
        $nv = [version]($need -replace '[^0-9\.].*','')
        return ($hv -ge $nv)
    }
    catch {
        return $false
    }
}

function Get-FFmpeg-Version {
    try {
        $out = ffmpeg -version 2>&1 | Select-Object -First 1
        if ($out -match 'ffmpeg version ([0-9\.]+)') { return $Matches[1] }
        return $null
    }
    catch { return $null }
}

function Get-Python-Version {
    try {
        $out = python --version 2>&1
        if ($out -match 'Python ([0-9\.]+)') { return $Matches[1] }
        return $null
    }
    catch { return $null }
}

function Test-PrerequisitesWithVersions {
    param([object]$cfg)
    $issues = @()
    if (-not $cfg) { return @{ Ok = $true } }

    if ($cfg.prerequisites) {
        if ($cfg.prerequisites.ffmpeg -and $cfg.prerequisites.ffmpeg.required) {
            $min = $cfg.prerequisites.ffmpeg.minVersion
            $have = Get-FFmpeg-Version
            if (-not $have) { $issues += "FFmpeg (not found)" }
            elseif (-not (Compare-Version $have $min)) { $issues += "FFmpeg version $have < required $min" }
        }

        if ($cfg.prerequisites.python -and $cfg.prerequisites.python.required) {
            $min = $cfg.prerequisites.python.minVersion
            $have = Get-Python-Version
            if (-not $have) { $issues += "Python (not found)" }
            elseif (-not (Compare-Version $have $min)) { $issues += "Python version $have < required $min" }
        }
    }

    if ($issues.Count -gt 0) { return @{ Ok = $false; Issues = $issues } }
    return @{ Ok = $true }
}

# Optional GUI helpers (used when installer runs interactively)
try {
    Add-Type -AssemblyName System.Windows.Forms -ErrorAction SilentlyContinue | Out-Null
}
catch { }

function Copy-FilesToInstallDir {
    param([string]$SourceDir, [string]$TargetDir)

    Write-Log "Copying files from '$SourceDir' to '$TargetDir'..."
    if (-not (Test-Path $TargetDir)) {
        New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
    }

    # Exclude large media, logs, temp
    $exclude = @('logs','temp','input','output','cache',"*.log","*.mp4","*.mkv","*.zip")

    Get-ChildItem -Path $SourceDir -Recurse -Force | Where-Object {
        $rel = $_.FullName.Substring($SourceDir.Length).TrimStart('\')
        foreach ($e in $exclude) {
            if ($e -like '*.*') { if ($_.Name -like $e) { return $false } }
            elseif ($rel -like "$e*" ) { return $false }
        }
        return $true
    } | ForEach-Object {
        $dest = Join-Path $TargetDir ($_.FullName.Substring($SourceDir.Length).TrimStart('\'))
        if ($_.PSIsContainer) {
            if (-not (Test-Path $dest)) { New-Item -ItemType Directory -Path $dest -Force | Out-Null }
        }
        else {
            $destDir = Split-Path $dest -Parent
            if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }
            Copy-Item -Path $_.FullName -Destination $dest -Force
        }
    }

    Write-Log "Copy complete."
}

function Create-StartMenuShortcuts {
    param([string]$AppDir)

    Write-Log "Creating Start Menu shortcuts..."
    $wsh = New-Object -ComObject WScript.Shell
    $startMenu = [Environment]::GetFolderPath('Programs')
    $folder = Join-Path $startMenu 'Video Pipeline'
    if (-not (Test-Path $folder)) { New-Item -ItemType Directory -Path $folder -Force | Out-Null }

    # Shortcut to main GUI (pipeline-gui.ps1 compiled EXE recommended)
    $targetExe = Join-Path $AppDir 'pipeline-gui.ps1'
    if (Test-Path (Join-Path $AppDir 'pipeline-gui.exe')) {
        $targetExe = Join-Path $AppDir 'pipeline-gui.exe'
    }

    $lnk = $wsh.CreateShortcut((Join-Path $folder 'Video Pipeline.lnk'))
    $lnk.TargetPath = 'powershell.exe'
    $lnk.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$targetExe`""
    $lnk.IconLocation = Join-Path $AppDir 'web-gui\favicon.ico'
    $lnk.Save()

    # Shortcut to Uninstall
    $uninst = $wsh.CreateShortcut((Join-Path $folder 'Uninstall Video Pipeline.lnk'))
    $uninstallScript = Join-Path $AppDir 'uninstall.ps1'
    if (Test-Path $uninstallScript) {
        $uninst.TargetPath = 'powershell.exe'
        $uninst.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$uninstallScript`""
        $uninst.Save()
    }

    Write-Log "Shortcuts created in Start Menu -> Video Pipeline"
}

function Register-UninstallEntry {
    param([string]$AppDir, [string]$DisplayVersion = '1.0.0')

    Write-Log "Registering uninstall entry in registry..."
    $key = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\VideoPipeline"
    if (-not (Test-Path $key)) { New-Item -Path $key -Force | Out-Null }

    Set-ItemProperty -Path $key -Name DisplayName -Value "Video Pipeline"
    Set-ItemProperty -Path $key -Name DisplayVersion -Value $DisplayVersion
    Set-ItemProperty -Path $key -Name Publisher -Value "Video Pipeline Contributors"
    Set-ItemProperty -Path $key -Name InstallLocation -Value $AppDir
    Set-ItemProperty -Path $key -Name UninstallString -Value "powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$AppDir\\uninstall.ps1`""

    Write-Log "Uninstall entry registered."
}

function Write-InstallLog {
    param([string]$AppDir)
    $logDir = Join-Path $AppDir 'logs'
    if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
    $log = Join-Path $logDir "install_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
    "Installed to: $AppDir`nDate: $(Get-Date)" | Out-File -FilePath $log -Encoding UTF8
    Write-Log "Install log written: $log"
}

function Main {
    Ensure-Elevated

    $source = Split-Path -Parent $PSCommandPath
    Write-Log "Source folder: $source"
    Write-Log "Target folder: $InstallDir"

    if ((Test-Path $InstallDir) -and -not $Force) {
        $choice = Read-Host "Target folder exists. Overwrite? (Y/N)"
        if ($choice -notin @('Y','y')) { Write-Log "Aborting by user request."; exit 0 }
    }

    # Run advanced prerequisite checks using installer settings (if loaded)
    $pre = Test-PrerequisitesWithVersions $cfg
    if (-not $pre.Ok) {
        $issuesList = $pre.Issues -join "`n"
        Write-Log "Prerequisites missing or outdated:\n$issuesList"

        # If GUI available, show a friendly dialog with options
        $userChoice = $null
        if ([System.Environment]::UserInteractive -and (Get-Command -Name "[System.Windows.Forms.MessageBox]" -ErrorAction SilentlyContinue)) {
            $msg = "The following prerequisites are missing or out-of-date:`n`n$issuesList`n`nChoose an action: 'Install Prereqs' will run the bundled installer-prerequisites script (requires elevation). 'Continue' will proceed with installation anyway. 'Abort' cancels installation."
            $caption = "Prerequisites Required"
            $buttons = [System.Windows.Forms.MessageBoxButtons]::AbortRetryIgnore
            $icon = [System.Windows.Forms.MessageBoxIcon]::Warning
            $dialogResult = [System.Windows.Forms.MessageBox]::Show($msg, $caption, $buttons, $icon)
            $userChoice = $dialogResult.ToString()
        }
        else {
            Write-Host "The following prerequisites are missing or out-of-date:`n$issuesList`n" -ForegroundColor Yellow
            $resp = Read-Host "Type I to Install prerequisites, C to Continue anyway, A to Abort [I/C/A]"
            switch ($resp.ToUpper()) { 'I' { $userChoice = 'Retry' } 'C' { $userChoice = 'Ignore' } default { $userChoice = 'Abort' } }
        }

        switch ($userChoice) {
            'Retry' {
                Write-Log "User chose to install prerequisites. Launching installer-prerequisites.ps1..."
                $prepScript = Join-Path $source 'install-prerequisites.ps1'
                if (Test-Path $prepScript) {
                    Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$prepScript`"" -Verb RunAs
                    Write-Log "Launched prerequisites installer. Exiting installer to allow prerequisites to install."; exit 0
                }
                else {
                    Write-Log "Prerequisites installer not found: $prepScript. Aborting."; exit 1
                }
            }
            'Ignore' {
                Write-Log "User chose to continue despite missing prerequisites. Proceeding with installation."
            }
            default {
                Write-Log "User aborted installation due to missing prerequisites."; exit 1
            }
        }
    }

    Copy-FilesToInstallDir -SourceDir $source -TargetDir $InstallDir
    Create-StartMenuShortcuts -AppDir $InstallDir
    Register-UninstallEntry -AppDir $InstallDir -DisplayVersion '1.0.0'
    Write-InstallLog -AppDir $InstallDir

    Write-Log "Installation complete."

    if (-not $NoLaunch) {
        Write-Log "Launching main GUI..."
        Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$InstallDir\\pipeline-gui.ps1`"" -WindowStyle Normal
    }
}

try {
    Main
}
catch {
    Write-Log "Installer failed: $_"
    exit 1
}

