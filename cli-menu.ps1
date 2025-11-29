# cli-menu.ps1
# Interactive command-line menu for video pipeline

$ErrorActionPreference = "Continue"

function Show-Menu {
    Clear-Host
    Write-Host "" -ForegroundColor Cyan
    Write-Host "║           VIDEO PIPELINE - Interactive Menu                   ║" -ForegroundColor Cyan
    Write-Host "════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "MAIN OPERATIONS:" -ForegroundColor Yellow
    Write-Host "  1. Extract Frames from Video"
    Write-Host "  2. Create Video from Frames"
    Write-Host "  3. Convert Video Format"
    Write-Host "  4. Upscale Video"
    Write-Host "  5. Batch Process Videos"
    Write-Host ""
    Write-Host "AI PROCESSING:" -ForegroundColor Yellow
    Write-Host "  6. Process with Grok"
    Write-Host "  7. Process with Midjourney"
    Write-Host "  8. Process with ComfyUI"
    Write-Host "  9. Generate AI Images"
    Write-Host ""
    Write-Host "UTILITIES:" -ForegroundColor Yellow
    Write-Host " 10. Get Video Information"
    Write-Host " 11. Configure Environment"
    Write-Host " 12. Validate System"
    Write-Host " 13. Launch GUI"
    Write-Host ""
    Write-Host "  0. Exit"
    Write-Host ""
}

function Extract-FramesMenu {
    Clear-Host
    Write-Host "=== Extract Frames from Video ===" -ForegroundColor Cyan
    $videoPath = Read-Host "Enter video file path"
    
    if (-not (Test-Path $videoPath)) {
        Write-Host "ERROR: File not found" -ForegroundColor Red
        Read-Host "Press Enter to continue"
        return
    }
    
    $outputFolder = Read-Host "Enter output folder (default: frames)"
    if ([string]::IsNullOrWhiteSpace($outputFolder)) { $outputFolder = "frames" }
    
    $fps = Read-Host "Enter FPS (default: 24)"
    if ([string]::IsNullOrWhiteSpace($fps)) { $fps = 24 }
    
    Write-Host "Starting frame extraction..." -ForegroundColor Green
    & ".\extract_frames.ps1" -VideoPath $videoPath -OutputFolder $outputFolder -FPS $fps
    
    Write-Host ""
    Write-Host "Frames extracted to: $outputFolder" -ForegroundColor Green
    Read-Host "Press Enter to continue"
}

function ConvertVideoMenu {
    Clear-Host
    Write-Host "=== Convert Video ===" -ForegroundColor Cyan
    
    $inputFile = Read-Host "Enter input video file"
    if (-not (Test-Path $inputFile)) {
        Write-Host "ERROR: File not found" -ForegroundColor Red
        Read-Host "Press Enter to continue"
        return
    }
    
    $outputFile = Read-Host "Enter output video file"
    $fps = Read-Host "Enter FPS (default: 24)"
    if ([string]::IsNullOrWhiteSpace($fps)) { $fps = 24 }
    
    Write-Host "Converting video..." -ForegroundColor Green
    if (Get-Command ffmpeg -ErrorAction SilentlyContinue) {
        ffmpeg -i $inputFile -r $fps -c:v libx264 -preset medium -c:a aac -y $outputFile
        Write-Host "Video converted: $outputFile" -ForegroundColor Green
    } else {
        Write-Host "ERROR: ffmpeg not found" -ForegroundColor Red
    }
    
    Read-Host "Press Enter to continue"
}

function BatchProcessMenu {
    Clear-Host
    Write-Host "=== Batch Process Videos ===" -ForegroundColor Cyan
    
    $inputFolder = Read-Host "Enter input folder"
    if (-not (Test-Path $inputFolder)) {
        Write-Host "ERROR: Folder not found" -ForegroundColor Red
        Read-Host "Press Enter to continue"
        return
    }
    
    $outputFolder = Read-Host "Enter output folder"
    New-Item -ItemType Directory -Path $outputFolder -Force | Out-Null
    
    Write-Host "Processing batch..." -ForegroundColor Green
    & ".\orchestrator.ps1" -InputFolder $inputFolder -OutputFolder $outputFolder -Mode process
    
    Write-Host "Batch processing complete" -ForegroundColor Green
    Read-Host "Press Enter to continue"
}

function ValidateSystemMenu {
    Clear-Host
    Write-Host "=== System Validation ===" -ForegroundColor Cyan
    Write-Host ""
    
    & ".\orchestrator.ps1" -Mode validate
    
    Read-Host "Press Enter to continue"
}

function ConfigureEnvironmentMenu {
    Clear-Host
    Write-Host "=== Configure Environment ===" -ForegroundColor Cyan
    Write-Host ""
    
    $grokKey = Read-Host "Enter Grok API Key (or press Enter to skip)"
    if (-not [string]::IsNullOrWhiteSpace($grokKey)) {
        [Environment]::SetEnvironmentVariable("XAI_API_KEY", $grokKey, "User")
        Write-Host " Grok API Key configured" -ForegroundColor Green
    }
    
    $mjKey = Read-Host "Enter Midjourney API Key (or press Enter to skip)"
    if (-not [string]::IsNullOrWhiteSpace($mjKey)) {
        [Environment]::SetEnvironmentVariable("MIDJOURNEY_API_KEY", $mjKey, "User")
        Write-Host " Midjourney API Key configured" -ForegroundColor Green
    }
    
    Write-Host ""
    Write-Host "Configuration complete. Restart PowerShell to apply changes." -ForegroundColor Yellow
    Read-Host "Press Enter to continue"
}

function LaunchGUIMenu {
    Write-Host ""
    Write-Host "Select GUI:" -ForegroundColor Yellow
    Write-Host "  1. WinForms Desktop GUI"
    Write-Host "  2. Web Browser GUI"
    Write-Host ""
    
    $guiChoice = Read-Host "Enter choice (1-2)"
    
    switch ($guiChoice) {
        "1" {
            Write-Host "Launching WinForms GUI..." -ForegroundColor Green
            & ".\pipeline-gui.ps1"
        }
        "2" {
            Write-Host "Launching Web GUI..." -ForegroundColor Green
            & ".\start-gui.ps1" -GUI web
        }
        default {
            Write-Host "Invalid choice" -ForegroundColor Red
        }
    }
}

# Main loop
do {
    Show-Menu
    $choice = Read-Host "Enter your choice"
    
    switch ($choice) {
        "1" { Extract-FramesMenu }
        "2" { 
            Write-Host "=== Create Video from Frames ===" -ForegroundColor Cyan
            & ".\stitch_all_images.ps1"
            Read-Host "Press Enter to continue"
        }
        "3" { ConvertVideoMenu }
        "4" {
            Write-Host "=== Upscale Video ===" -ForegroundColor Cyan
            $inputFile = Read-Host "Enter input video"
            $outputFile = Read-Host "Enter output file"
            $scale = Read-Host "Enter scale factor (1-4, default: 2)"
            if ([string]::IsNullOrWhiteSpace($scale)) { $scale = 2 }
            
            if (Get-Command ffmpeg -ErrorAction SilentlyContinue) {
                ffmpeg -i $inputFile -vf "scale=iw*$scale:ih*$scale" -c:v libx264 -preset slow -y $outputFile
                Write-Host "Video upscaled: $outputFile" -ForegroundColor Green
            }
            Read-Host "Press Enter to continue"
        }
        "5" { BatchProcessMenu }
        "6" {
            Write-Host "=== Process with Grok ===" -ForegroundColor Cyan
            $videoFile = Read-Host "Enter video file"
            & ".\providers\process-grok.ps1" -InputFile $videoFile -OutputFile "grok_output.mp4"
            Read-Host "Press Enter to continue"
        }
        "7" {
            Write-Host "=== Process with Midjourney ===" -ForegroundColor Cyan
            $videoFile = Read-Host "Enter video file"
            & ".\providers\process-midjourney.ps1" -InputFile $videoFile -OutputFile "midjourney_output.mp4"
            Read-Host "Press Enter to continue"
        }
        "8" {
            Write-Host "=== Process with ComfyUI ===" -ForegroundColor Cyan
            $videoFile = Read-Host "Enter video file"
            & ".\providers\process-comfyui.ps1" -InputFile $videoFile -OutputFile "comfyui_output.mp4"
            Read-Host "Press Enter to continue"
        }
        "9" {
            Write-Host "=== Generate AI Images ===" -ForegroundColor Cyan
            if (Get-Command python -ErrorAction SilentlyContinue) {
                $prompt = Read-Host "Enter image prompt"
                python ".\generate_ai_images.py" $prompt -o "ai_generated.png"
            }
            Read-Host "Press Enter to continue"
        }
        "10" {
            Write-Host "=== Get Video Information ===" -ForegroundColor Cyan
            $videoFile = Read-Host "Enter video file"
            if (Get-Command ffprobe -ErrorAction SilentlyContinue) {
                ffprobe -v error -show_format -show_streams $videoFile
            }
            Read-Host "Press Enter to continue"
        }
        "11" { ConfigureEnvironmentMenu }
        "12" { ValidateSystemMenu }
        "13" { LaunchGUIMenu }
        "0" { 
            Write-Host "Goodbye!" -ForegroundColor Green
            exit 0 
        }
        default { 
            Write-Host "Invalid choice" -ForegroundColor Red
            Start-Sleep -Seconds 2
        }
    }
} while ($true)
