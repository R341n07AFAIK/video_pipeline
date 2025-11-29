# package_ai_pipeline_autorun.ps1
# Package the pipeline for distribution and auto-run capability

param(
    [string]$OutputPackage = "ai_pipeline.zip",
    [string]$LaunchScript = "one_click_ai_pipeline.ps1"
)

Write-Host "=== Package AI Pipeline ==="
Write-Host "Creating distributable package..."
Write-Host ""

if (-not (Get-Command Compress-Archive -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: PowerShell compression not available"
    exit 1
}

# Gather pipeline files
$pipelineFiles = @(
    "*.ps1",
    "*.py",
    "README.md"
)

Write-Host "Packaging files..."
Compress-Archive -Path $pipelineFiles -DestinationPath $OutputPackage -Force

if (Test-Path $OutputPackage) {
    $sizeMB = [math]::Round((Get-Item $OutputPackage).Length / 1MB, 2)
    Write-Host "Package created: $OutputPackage ($sizeMB MB)"
    Write-Host ""
    Write-Host "To use:"
    Write-Host "  1. Extract $OutputPackage"
    Write-Host "  2. Run: powershell -ExecutionPolicy Bypass -File $LaunchScript"
} else {
    Write-Host "ERROR: Failed to create package"
    exit 1
}
