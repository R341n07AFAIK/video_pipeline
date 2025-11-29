# package_ai_pipeline_fixed.ps1
# Packages the AI video pipeline into a downloadable ZIP

# Destination ZIP
$outputZip = "C:\Users\omnic\Documents\vidproj\Unified_AIPipeline_Package.zip"

# List of files/folders to include
$itemsToInclude = @(
    "C:\Users\omnic\Documents\vidproj\unified_ai_pipeline_fixed.ps1",
    "C:\Users\omnic\Documents\vidproj\rife-ncnn-vulkan-20221029-windows",
    "C:\Users\omnic\Documents\vidproj\free_video_work",
    "C:\Users\omnic\Documents\vidproj\install_comfyui.ps1",
    "C:\Users\omnic\Documents\vidproj\grok_superflow.ps1",
    "C:\Users\omnic\Documents\vidproj\ultra_local_video_pipeline.ps1",
    "C:\Users\omnic\Documents\vidproj\mj_video_pipeline.ps1"
)

# Remove old ZIP if exists
if (Test-Path $outputZip) { Remove-Item $outputZip -Force }

# Create ZIP
Compress-Archive -Path $itemsToInclude -DestinationPath $outputZip -Force

Write-Host "[DONE] Package created: $outputZip"
