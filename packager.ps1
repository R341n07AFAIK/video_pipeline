<#
packager.ps1

Prepares a clean distribution folder according to installer_settings.json
- Reads includePatterns and excludePatterns
- Copies matching files to ./dist
- Preserves directory structure

Usage:
  .\packager.ps1 -SourceDir . -OutDir .\dist -Clean
#>

param(
    [string]$SourceDir = (Split-Path -Parent $PSCommandPath),
    [string]$OutDir = "./dist",
    [switch]$Clean
)

function Write-Log { param($m) Write-Host "[$((Get-Date).ToString('s'))] $m" }

$settingsPath = Join-Path $SourceDir 'installer_settings.json'
if (-not (Test-Path $settingsPath)) { Write-Log "installer_settings.json not found in $SourceDir. Using defaults."; $cfg = $null }
else { $cfg = Get-Content $settingsPath -Raw | ConvertFrom-Json }

# Determine include/exclude lists
$include = @('**/*')
$exclude = @('logs/**','temp/**','input/**','output/**','**/*.mp4','**/*.mkv','**/*.zip')
if ($cfg) {
    if ($cfg.includePatterns) { $include = $cfg.includePatterns }
    if ($cfg.excludePatterns) { $exclude = $cfg.excludePatterns }
}

# Prepare out dir
$fullOut = (Resolve-Path -Path $OutDir -ErrorAction SilentlyContinue)
if ($Clean -and $fullOut) { Remove-Item -Path $OutDir -Recurse -Force -ErrorAction SilentlyContinue }
if (-not (Test-Path $OutDir)) { New-Item -ItemType Directory -Path $OutDir -Force | Out-Null }

Write-Log "Packaging from $SourceDir to $OutDir"

# Convert glob patterns to simple -like patterns for evaluation
function GlobToLike([string]$g) {
    $s = $g -replace '^\*\*/?','*'
    $s = $s -replace '\*\*/','*'
    return $s
}

# Collect files recursively
$all = Get-ChildItem -Path $SourceDir -Recurse -File -Force

foreach ($file in $all) {
    $rel = $file.FullName.Substring($SourceDir.Length).TrimStart('\')
    # Skip files in .git, dist
    if ($rel -like '.git/*' -or $rel -like 'dist/*' ) { continue }

    # Determine excluded
    $isExcluded = $false
    foreach ($pattern in $exclude) {
        $like = GlobToLike $pattern
        if ($rel -like $like) { $isExcluded = $true; break }
        # also check file name patterns
        if ($file.Name -like $like) { $isExcluded = $true; break }
    }
    if ($isExcluded) { continue }

    # Determine included (if include patterns specified)
    $isIncluded = $false
    foreach ($pattern in $include) {
        $like = GlobToLike $pattern
        if ($rel -like $like) { $isIncluded = $true; break }
        if ($file.Name -like $like) { $isIncluded = $true; break }
    }
    if (-not $isIncluded) { continue }

    # Copy
    $dest = Join-Path $OutDir $rel
    $destDir = Split-Path $dest -Parent
    if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }
    Copy-Item -Path $file.FullName -Destination $dest -Force
}

Write-Log "Packaging complete. Output: $OutDir"
