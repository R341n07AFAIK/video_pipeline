# setup-environment.ps1
# Configure environment for video pipeline

param(
    [string]$GrokAPIKey,
    [string]$MidjourneyAPIKey,
    [string]$ComfyUIServer = "http://localhost:8188"
)

Write-Host "=== Pipeline Environment Configuration ===" -ForegroundColor Cyan
Write-Host ""

# Function to set environment variable
function Set-EnvVar {
    param(
        [string]$VarName,
        [string]$Value,
        [ValidateSet("User", "System")]
        [string]$Scope = "User"
    )
    
    if ([string]::IsNullOrWhiteSpace($Value)) {
        Write-Host "Skipping $VarName (empty)" -ForegroundColor Yellow
        return
    }
    
    try {
        [Environment]::SetEnvironmentVariable($VarName, $Value, $Scope)
        Write-Host " $VarName set for $Scope" -ForegroundColor Green
    } catch {
        Write-Host " Failed to set $VarName : $_" -ForegroundColor Red
    }
}

# Set API Keys
Write-Host "Setting API Keys:" -ForegroundColor Cyan
if (-not [string]::IsNullOrWhiteSpace($GrokAPIKey)) {
    Set-EnvVar -VarName "XAI_API_KEY" -Value $GrokAPIKey
}

if (-not [string]::IsNullOrWhiteSpace($MidjourneyAPIKey)) {
    Set-EnvVar -VarName "MIDJOURNEY_API_KEY" -Value $MidjourneyAPIKey
}

Write-Host ""
Write-Host "Environment Configuration Complete" -ForegroundColor Green
Write-Host "Note: Restart PowerShell to use environment variables" -ForegroundColor Yellow
