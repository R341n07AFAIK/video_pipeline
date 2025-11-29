# full_multi_ai_pipeline.ps1
# Multi-provider AI pipeline (supports Grok, Claude, Midjourney)

param(
    [string]$InputFolder = ".",
    [string]$Pattern = "*.mp4",
    [string]$OutputFolder = "output_multi",
    [array]$Providers = @("grok"),
    [string]$Prompt = "Process this video"
)

Write-Host "=== Multi-Provider AI Pipeline ==="
Write-Host "Input       : $InputFolder"
Write-Host "Providers   : $($Providers -join ', ')"
Write-Host "Output      : $OutputFolder"
Write-Host ""

if (!(Test-Path $InputFolder)) {
    Write-Host "ERROR: Input folder not found"
    exit 1
}

if (!(Test-Path $OutputFolder)) {
    New-Item -ItemType Directory -Path $OutputFolder | Out-Null
}

# Import core
. ".\unified_ai_core.ps1"

$videos = Get-ChildItem $InputFolder -Filter $Pattern

foreach ($video in $videos) {
    Write-Host "Processing: $($video.Name)"
    
    foreach ($provider in $Providers) {
        Write-Host "  Provider: $provider"
        
        $outputFile = Join-Path $OutputFolder "$($video.BaseName)_${provider}.mp4"
        
        if (Initialize-AIEnvironment -Provider $provider) {
            Process-WithAI -InputPath $video.FullName -OutputPath $outputFile -Prompt $Prompt
        } else {
            Write-Host "    SKIPPED: $provider not available"
        }
    }
}

Write-Host ""
Write-Host "Multi-provider processing complete!"
