# run_pipeline_from_zip.ps1
# Extract and run pipeline directly from a zip package

param(
    [string]$ZipFile = "ai_pipeline.zip",
    [string]$ExtractPath = "pipeline_extracted"
)

if (!(Test-Path $ZipFile)) {
    Write-Host "ERROR: Zip file not found: $ZipFile"
    exit 1
}

Write-Host "=== Run Pipeline from Zip ==="
Write-Host "Extracting: $ZipFile"
Write-Host "Into      : $ExtractPath"
Write-Host ""

if (-not (Get-Command Expand-Archive -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: PowerShell extraction not available"
    exit 1
}

if (!(Test-Path $ExtractPath)) {
    New-Item -ItemType Directory -Path $ExtractPath | Out-Null
}

Expand-Archive -Path $ZipFile -DestinationPath $ExtractPath -Force

Write-Host "Extraction complete!"
Write-Host ""
Write-Host "Available scripts:"
Get-ChildItem $ExtractPath -Filter "*.ps1" | ForEach-Object {
    Write-Host "  - $($_.Name)"
}

Write-Host ""
Write-Host "To run a script, use:"
Write-Host "  powershell -ExecutionPolicy Bypass -File '$ExtractPath\script_name.ps1'"
