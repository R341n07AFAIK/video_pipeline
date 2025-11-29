<#
.SYNOPSIS
Generate processing report from logs

.DESCRIPTION
Analyzes log files and generates comprehensive reports about:
- Processing statistics
- Success/failure rates
- Performance metrics
- Error summary
- Provider usage

.PARAMETER LogDirectory
Directory containing log files

.PARAMETER OutputFormat
Output format: HTML, CSV, or JSON

.EXAMPLE
.\generate-report.ps1 -LogDirectory logs -OutputFormat HTML
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$LogDirectory = "logs",
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("HTML", "CSV", "JSON")]
    [string]$OutputFormat = "HTML"
)

Write-Host "Generating report from logs..." -ForegroundColor Cyan

if (-not (Test-Path $LogDirectory)) {
    Write-Host "Log directory not found: $LogDirectory" -ForegroundColor Red
    exit 1
}

# Collect log files
$logFiles = Get-ChildItem -Path $LogDirectory -Filter "pipeline_*.log" | Sort-Object LastWriteTime -Descending
$reportTimestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

# Parse logs
$stats = @{
    TotalProcessed = 0
    Successful = 0
    Failed = 0
    Warnings = 0
    Errors = @()
    Providers = @{}
    ProcessingTimes = @()
}

foreach ($logFile in $logFiles) {
    $content = Get-Content $logFile.FullName
    
    foreach ($line in $content) {
        if ($line -match "ERROR") { 
            $stats.Errors += $line
            $stats.Failed++
        }
        if ($line -match "WARN") { $stats.Warnings++ }
        if ($line -match "Processing.*success|SUCCESS") { $stats.Successful++ }
        
        # Extract provider usage
        foreach ($provider in @("Grok", "Midjourney", "ComfyUI")) {
            if ($line -match $provider) {
                if (-not $stats.Providers.ContainsKey($provider)) {
                    $stats.Providers[$provider] = 0
                }
                $stats.Providers[$provider]++
            }
        }
    }
}

# Format output
switch ($OutputFormat) {
    "HTML" {
        $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Video Pipeline Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background-color: #f5f5f5; }
        .header { background-color: #0078d4; color: white; padding: 20px; border-radius: 5px; }
        .section { background-color: white; margin: 20px 0; padding: 20px; border-radius: 5px; }
        table { width: 100%; border-collapse: collapse; }
        th, td { padding: 10px; text-align: left; border-bottom: 1px solid #ddd; }
        th { background-color: #0078d4; color: white; }
        .success { color: green; }
        .error { color: red; }
        .warning { color: orange; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Video Pipeline Processing Report</h1>
        <p>Generated: $reportTimestamp</p>
    </div>
    
    <div class="section">
        <h2>Summary Statistics</h2>
        <table>
            <tr><th>Metric</th><th>Count</th></tr>
            <tr><td>Successful</td><td class="success">$($stats.Successful)</td></tr>
            <tr><td>Failed</td><td class="error">$($stats.Failed)</td></tr>
            <tr><td>Warnings</td><td class="warning">$($stats.Warnings)</td></tr>
        </table>
    </div>
    
    <div class="section">
        <h2>Provider Usage</h2>
        <table>
            <tr><th>Provider</th><th>Count</th></tr>
            $(foreach ($provider in $stats.Providers.GetEnumerator()) {
                "<tr><td>$($provider.Name)</td><td>$($provider.Value)</td></tr>"
            })
        </table>
    </div>
    
    <div class="section">
        <h2>Errors</h2>
        <ul>
        $(foreach ($error in $stats.Errors | Select-Object -First 10) {
            "<li>$error</li>"
        })
        </ul>
    </div>
</body>
</html>
"@
        $reportFile = "report_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"
        $html | Out-File -FilePath $reportFile -Encoding UTF8
        Write-Host "Report generated: $reportFile" -ForegroundColor Green
    }
    
    "CSV" {
        $csv = @"
Metric,Value
Successful,$($stats.Successful)
Failed,$($stats.Failed)
Warnings,$($stats.Warnings)
"@
        $reportFile = "report_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
        $csv | Out-File -FilePath $reportFile -Encoding UTF8
        Write-Host "Report generated: $reportFile" -ForegroundColor Green
    }
    
    "JSON" {
        $json = $stats | ConvertTo-Json
        $reportFile = "report_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
        $json | Out-File -FilePath $reportFile -Encoding UTF8
        Write-Host "Report generated: $reportFile" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "Statistics:" -ForegroundColor Yellow
Write-Host "  Successful: $($stats.Successful)"
Write-Host "  Failed: $($stats.Failed)"
Write-Host "  Warnings: $($stats.Warnings)"
