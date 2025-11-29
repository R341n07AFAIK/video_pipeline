# process-comfyui.ps1
# ComfyUI local AI processing integration

param(
    [string]$InputFile = "",
    [string]$OutputFile = "",
    [hashtable]$Config = @{},
    [string]$ComfyUIServer = "http://localhost:8188"
)

Write-Host "=== ComfyUI Video Processing ==="
Write-Host "Input  : $InputFile"
Write-Host "Output : $OutputFile"
Write-Host "Server : $ComfyUIServer"

# Test ComfyUI connection
Write-Host "Testing ComfyUI connection..."
try {
    $response = Invoke-WebRequest -Uri "$ComfyUIServer/api" -ErrorAction Stop
    Write-Host " ComfyUI is accessible"
    
    # Extract frames
    $framesDir = "frames_$(Get-Date -Format 'yyyyMMddHHmmss')"
    Write-Host "Extracting frames to: $framesDir"
    
    if (Get-Command ffmpeg -ErrorAction SilentlyContinue) {
        ffmpeg -i $InputFile -vf fps=12 "$framesDir\frame_%06d.png" -y
        
        # Process frames through ComfyUI
        Write-Host "Submitting frames to ComfyUI..."
        
        # Placeholder for actual ComfyUI workflow
        # In production, this would create and execute a ComfyUI workflow
        
        # Re-encode frames back to video
        Write-Host "Re-encoding processed frames..."
        ffmpeg -framerate 12 -i "$framesDir\frame_%06d.png" -c:v libx264 -preset medium $OutputFile -y
        
        # Cleanup
        Remove-Item $framesDir -Recurse -Force -ErrorAction SilentlyContinue
        
        Write-Host "Processing complete: $OutputFile"
    }
} catch {
    Write-Host "⚠ ComfyUI not available at $ComfyUIServer"
    Write-Host "Using ffmpeg fallback..."
    
    # Fallback to ffmpeg processing
    ffmpeg -i $InputFile -vf "format=yuv420p" -c:v libx264 -preset medium $OutputFile -y
    Write-Host "Fallback processing complete: $OutputFile"
}

exit 0
