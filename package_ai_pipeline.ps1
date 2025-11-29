# Path to project folder
$projectFolder = "C:\Users\omnic\Documents\vidproj"
# Name of the output ZIP
$outputZip = "$projectFolder\AI_Video_Pipeline_Bundle.zip"

# Files and folders to include
$itemsToZip = @(
    "rife-ncnn-vulkan-20221029-windows.zip",
    "install_comfyui.ps1",
    "unified_ai_pipeline.ps1",
    "unified_ai_tools_installer.ps1",
    "free_local_video_pipeline.ps1",
    "ultra_local_video_pipeline.ps1",
    "mj_video_pipeline.ps1",
    "grok_stitch.ps1",
    "grok_stitch_clean.ps1",
    "grok_stitch_full.ps1",
    "grok_stitch_simple.ps1",
    "grok_superflow.ps1",
    "clips.txt"
)

# Convert to full paths
$fullPaths = $itemsToZip | ForEach-Object { Join-Path $projectFolder $_ }

# Remove ZIP if it already exists
if (Test-Path $outputZip) {
    Remove-Item $outputZip -Force
}

# Create the ZIP
Compress-Archive -Path $fullPaths -DestinationPath $outputZip -Force

Write-Host "✅ AI pipeline bundled successfully into: $outputZip"
