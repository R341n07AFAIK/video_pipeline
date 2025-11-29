# start-gui.ps1
# Launch the appropriate GUI for the video pipeline

param(
    [ValidateSet("winforms", "web", "interactive")]
    [string]$GUI = "interactive"
)

Write-Host "" -ForegroundColor Cyan
Write-Host "  Video Pipeline - GUI Launcher                           ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

if ($GUI -eq "interactive") {
    Write-Host "Select GUI Option:" -ForegroundColor Yellow
    Write-Host "  1. WinForms GUI (Windows Desktop)"
    Write-Host "  2. Web GUI (Browser)"
    Write-Host "  3. CLI Menu"
    Write-Host ""
    
    $choice = Read-Host "Enter choice (1-3)"
    
    switch ($choice) {
        "1" { $GUI = "winforms" }
        "2" { $GUI = "web" }
        "3" { $GUI = "cli" }
        default { 
            Write-Host "Invalid choice" -ForegroundColor Red
            exit 1
        }
    }
}

switch ($GUI) {
    "winforms" {
        Write-Host "Launching WinForms GUI..." -ForegroundColor Green
        powershell -ExecutionPolicy Bypass -File ".\pipeline-gui.ps1"
    }
    
    "web" {
        Write-Host "Launching Web Server..." -ForegroundColor Green
        Write-Host "Open browser to: http://localhost:8000" -ForegroundColor Cyan
        Write-Host "Press Ctrl+C to stop server" -ForegroundColor Yellow
        Write-Host ""
        
        # Start simple HTTP server
        $pythonCode = @"
import http.server
import socketserver
import os
from pathlib import Path

os.chdir('web-gui')

PORT = 8000
Handler = http.server.SimpleHTTPRequestHandler

with socketserver.TCPServer(("", PORT), Handler) as httpd:
    print(f"Server running at http://localhost:{PORT}/")
    print("Press Ctrl+C to stop")
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nServer stopped")
"@
        
        if (Get-Command python -ErrorAction SilentlyContinue) {
            python -c $pythonCode
        } else {
            Write-Host "Python not found. Cannot start web server." -ForegroundColor Red
            exit 1
        }
    }
    
    "cli" {
        Write-Host "CLI Menu not yet implemented" -ForegroundColor Yellow
    }
}
