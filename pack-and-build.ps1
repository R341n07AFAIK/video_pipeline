<#
pack-and-build.ps1

Automates packaging and optional build steps:
- Runs packager.ps1 to prepare ./dist
- Optionally compiles installer.ps1 into bootstrap EXE (ps2exe)
- Generates Inno Setup script via generate_iss.ps1
- Optionally runs ISCC to build final installer

Usage:
  .\pack-and-build.ps1 [-Clean] [-CompileBootstrap] [-RunISCC] [-WhatIf]

Requirements:
- ps2exe (Install-Module -Name ps2exe) if compiling bootstrap
- Inno Setup (ISCC.exe) in PATH if running ISCC
#>
param(
    [switch]$Clean,
    [switch]$CompileBootstrap,
    [switch]$RunISCC,
    [switch]$WhatIf
)

function Write-Log { param($m) Write-Host "[$((Get-Date).ToString('s'))] $m" }

$repoRoot = (Split-Path -Parent $PSCommandPath)
Push-Location $repoRoot

try {
    Write-Log "Starting pack-and-build workflow"

    # 1) Prepare distribution folder
    $dist = Join-Path $repoRoot 'dist'
    $packArgs = @('-SourceDir', $repoRoot, '-OutDir', $dist)
    if ($Clean) { $packArgs += '-Clean' }
    if ($WhatIf) { Write-Log "WhatIf: would run packager with args: $packArgs" } else { & "$repoRoot\packager.ps1" @packArgs }

    # 2) Optionally compile installer.ps1 to EXE
    $bootstrapExe = Join-Path $dist 'video_pipeline_installer_bootstrap.exe'
    if ($CompileBootstrap) {
        Write-Log "Compiling installer bootstrap to EXE (ps2exe)"
        if (-not (Get-Module -ListAvailable -Name ps2exe)) {
            Write-Log "ps2exe module not found. Installing..."
            Install-Module -Name ps2exe -Scope CurrentUser -Force
        }
        if ($WhatIf) { Write-Log "WhatIf: would compile installer.ps1 -> $bootstrapExe" }
        else {
            Invoke-ps2exe "$repoRoot\installer.ps1" $bootstrapExe -noConsole -title "Video Pipeline Installer"
            Write-Log "Compiled bootstrap: $bootstrapExe"
        }
    }

    # 3) Generate Inno Setup script
    $generatedIss = Join-Path $repoRoot 'video_pipeline_installer_generated.iss'
    if ($WhatIf) { Write-Log "WhatIf: would generate ISS to $generatedIss" }
    else { & "$repoRoot\generate_iss.ps1" -Settings "$repoRoot\installer_settings.json" -Out $generatedIss }

    # 4) Optionally run ISCC (Inno Setup Compiler)
    if ($RunISCC) {
        $iscc = Get-Command ISCC.exe -ErrorAction SilentlyContinue
        if (-not $iscc) {
            Write-Log "ISCC.exe not found in PATH. Please install Inno Setup or add ISCC.exe to PATH."; exit 1
        }
        if ($WhatIf) { Write-Log "WhatIf: would run ISCC on $generatedIss" }
        else {
            & $iscc.Path $generatedIss
            Write-Log "ISCC run complete. Check output in current directory." 
        }
    }

    Write-Log "pack-and-build workflow complete"
}
catch {
    Write-Log "pack-and-build failed: $_"
    exit 1
}
finally { Pop-Location }
