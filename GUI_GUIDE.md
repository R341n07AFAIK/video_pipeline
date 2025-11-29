# Video Pipeline - GUI Guide

## Overview

The video pipeline provides **3 interface options** for easy video processing:

1. **WinForms GUI** - Professional Windows desktop application
2. **Web GUI** - Browser-based interface (modern, responsive)
3. **CLI Menu** - Command-line interactive menu

---

## 1. WinForms Desktop GUI

### Launch
```powershell
.\pipeline-gui.ps1
```

### Features
- **Tabbed Interface** with 3 tabs
- **File Browse Dialogs** for easy file/folder selection
- **Real-time Log Display** (color-coded terminal)
- **Status Indicators** for processing

### Tabs

#### Tab 1: Process Video
Process a single video file with customizable options:

**Options:**
- Input Video (browse dialog)
- Output Video (save dialog)
- AI Provider (grok, midjourney, comfyui, none)
- FPS (12-120)
- Codec (libx264, libx265, libvpx)

**Actions:**
- Process Video button starts conversion
- Log output shows real-time progress
- Success message on completion

#### Tab 2: Batch Process
Process multiple videos from a folder:

**Options:**
- Input Folder (directory browse)
- Output Folder (directory browse)
- AI Provider selection

**Actions:**
- Process Batch button
- Processes all videos in folder
- Detailed log output

#### Tab 3: Settings
Configure API keys and defaults:

**API Configuration:**
- Grok API Key (password field with Save button)
- Midjourney API Key (password field with Save button)
- Environment variables saved to Windows registry

**Usage:**
- Save button stores credentials
- Credentials persist after PowerShell restart

### Keyboard Shortcuts
- `Tab` - Navigate between controls
- `Enter` - Activate buttons
- `Ctrl+C` - Close application

### System Requirements
- Windows 7 or later
- .NET Framework 4.5+
- PowerShell 5.1+

---

## 2. Web GUI

### Launch
```powershell
.\start-gui.ps1 -GUI web
```

Or automatic server selection:
```powershell
.\start-gui.ps1
# Select option 2: Web GUI
```

### Access
Open browser: **http://localhost:8000**

### Features
- Modern, responsive design
- Works on mobile and desktop
- Real-time log updates
- Persistent settings (localStorage)
- No server required (client-side processing)

### Tabs

#### Tab 1: Process Video
Single video processing:
- File path input
- Output filename
- AI Provider selector (dropdown)
- FPS slider (12-120)
- Codec selector
- Live log display with timestamps
- Process/Clear buttons

#### Tab 2: Batch Process
Batch folder processing:
- Input folder path
- Output folder path
- Provider selection
- Batch log with progress
- Status updates

#### Tab 3: Settings
Persistent configuration:
- Grok API Key input
- Midjourney API Key input
- ComfyUI Server configuration
- Default FPS and codec
- All settings saved to browser localStorage

#### Tab 4: Status
System health dashboard:
- PowerShell status
- FFmpeg availability
- Python version
- Grok API configuration
- Midjourney API configuration
- ComfyUI server status
- Refresh button for live updates

### Browser Compatibility
- Chrome 90+
- Firefox 88+
- Safari 14+
- Edge 90+

### Features
- **Responsive Design** - Adapts to screen size
- **Color-Coded Logs** - Green text on dark background
- **Gradient UI** - Modern purple gradient theme
- **Mobile Friendly** - Touch-optimized buttons

### Settings Persistence
Settings saved in browser:
- `grokKey` - Grok API key
- `mjKey` - Midjourney API key
- `comfyuiServer` - ComfyUI server URL
- `defaultFPS` - Default FPS value
- `defaultCodec` - Default codec choice

---

## 3. CLI Interactive Menu

### Launch
```powershell
.\cli-menu.ps1
```

### Main Menu Options

**Operations:**
1. Extract Frames from Video
2. Create Video from Frames
3. Convert Video Format
4. Upscale Video
5. Batch Process Videos

**AI Processing:**
6. Process with Grok
7. Process with Midjourney
8. Process with ComfyUI
9. Generate AI Images

**Utilities:**
10. Get Video Information
11. Configure Environment
12. Validate System
13. Launch GUI

**Exit:**
0. Exit

### Usage Examples

#### Extract Frames
```
Menu > 1
Enter video file path: C:\videos\sample.mp4
Enter output folder (default: frames): my_frames
Enter FPS (default: 24): 30
```

#### Convert Video
```
Menu > 3
Enter input video file: input.mp4
Enter output video file: output.mp4
Enter FPS (default: 24): 60
```

#### Batch Process
```
Menu > 5
Enter input folder: C:\videos
Enter output folder: C:\videos_output
```

#### Configure Environment
```
Menu > 11
Enter Grok API Key: sk-...
Enter Midjourney API Key: ...
```

#### Validate System
```
Menu > 12
Checks PowerShell, FFmpeg, Python, Git
Shows compatibility status
```

---

## 4. Launcher Script

### start-gui.ps1

**Usage:**
```powershell
# Interactive selection
.\start-gui.ps1

# Direct launch
.\start-gui.ps1 -GUI winforms
.\start-gui.ps1 -GUI web
.\start-gui.ps1 -GUI cli
```

**Features:**
- Menu selection for GUI type
- Automatic setup for chosen interface
- Error handling and fallbacks

---

## Installation & Setup

### Prerequisites Check

Run validation:
```powershell
.\orchestrator.ps1 -Mode validate
```

### Install Requirements

Auto-install all prerequisites:
```powershell
.\install-prerequisites.ps1
```

Requires admin privileges. Will install:
- FFmpeg
- Python 3.12+
- Python dependencies (requests, Pillow, numpy)
- ComfyUI (optional)

### Configure APIs

Option 1 - Via GUI Settings Tab:
1. Launch GUI
2. Go to Settings tab
3. Enter API keys
4. Click Save

Option 2 - Via CLI:
```powershell
.\cli-menu.ps1
# Select 11: Configure Environment
# Enter API keys when prompted
```

Option 3 - Manual:
```powershell
setx XAI_API_KEY "your-grok-key"
setx MIDJOURNEY_API_KEY "your-midjourney-key"
```

---

## Troubleshooting

### GUI Won't Launch

**WinForms:**
```powershell
# Check PowerShell version
$PSVersionTable.PSVersion

# Ensure .NET Framework installed
dotnet --version
```

**Web GUI:**
```powershell
# Verify Python
python --version

# Check if port 8000 is available
netstat -ano | findstr :8000
```

### API Keys Not Working

1. Check environment variables:
```powershell
$env:XAI_API_KEY
$env:MIDJOURNEY_API_KEY
```

2. Restart PowerShell after setting variables

3. Verify in GUI Settings tab

### Processing Fails

1. Check system status:
```powershell
.\cli-menu.ps1
# Select 12: Validate System
```

2. Verify FFmpeg:
```powershell
ffmpeg -version
```

3. Check input file exists and is readable

---

## Keyboard Shortcuts

### WinForms GUI
- `Tab` - Move between controls
- `Shift+Tab` - Move backward
- `Enter` - Activate button
- `Alt+P` - Process button
- `Ctrl+C` - Close

### Web GUI
- `Ctrl+K` - Focus search (future)
- `Tab` - Navigate tabs
- `Enter` - Activate button

### CLI Menu
- Number keys (0-9) - Select option
- `Ctrl+C` - Exit menu
- `Enter` - Confirm input

---

## Performance Tips

1. **Use Local Processing** when possible (no API latency)
2. **Lower FPS** for faster processing (24 default is good)
3. **Use H.265 Codec** for smaller file sizes (slower encoding)
4. **Batch Processing** more efficient for multiple videos
5. **Close Other Apps** to maximize resources

---

## Common Workflows

### Workflow 1: Simple Video Conversion
```
CLI Menu > 3 (Convert Video)
Input: original.mp4
Output: converted.mp4
FPS: 30
```

### Workflow 2: Frame Extraction & Editing
```
CLI Menu > 1 (Extract Frames)
Input: video.mp4
Output: frames_folder
Edit frames externally
CLI Menu > 2 (Create Video from Frames)
Output: edited_video.mp4
```

### Workflow 3: AI Processing
```
WinForms GUI > Tab 1
Input: video.mp4
Provider: grok
Output: processed.mp4
Click Process Video
```

### Workflow 4: Batch Processing with API
```
Web GUI > Tab 2
Input Folder: videos/
Output Folder: processed/
Provider: midjourney
Click Process Batch
```

---

## API Integration

### Grok (xAI)
- Supports video processing and image generation
- Configure: Settings > Grok API Key
- Endpoint: `https://api.x.ai/video/process`

### Midjourney
- Supports image generation from prompts
- Configure: Settings > Midjourney API Key
- Automatic fallback to local processing if unavailable

### ComfyUI
- Local AI processing (no API key needed)
- Default: `http://localhost:8188`
- Configurable in Settings > ComfyUI Server

---

## Advanced Options

### Custom Configuration

Edit `pipeline.config.json`:
```json
{
  "video": {
    "fps": 24,
    "codec": "libx264",
    "preset": "medium"
  },
  "providers": {
    "enabled": ["grok", "comfyui"]
  }
}
```

### Command-Line Processing

Use scripts directly without GUI:
```powershell
.\extract_frames.ps1 -VideoPath video.mp4 -OutputFolder frames -FPS 30
.\composite_video_from_images.ps1 -FramesFolder frames -OutputVideo output.mp4 -FPS 30
.\orchestrator.ps1 -InputFolder input -OutputFolder output -Providers @("grok")
```

---

## Docker Setup

For containerized processing:
```bash
docker-compose up -d
```

Services:
- ComfyUI on port 8188
- FFmpeg container for processing

---

## Getting Help

1. **CLI Menu** > Select 12 (Validate System)
2. **Check Logs** in output window
3. **Review README.md** for detailed documentation
4. **Check INTEGRATION_SUMMARY.md** for technical details

---

## Summary

| Interface | Best For | Setup Time | Features |
|-----------|----------|-----------|----------|
| **WinForms GUI** | Windows users | 1 min | Professional, native, browse dialogs |
| **Web GUI** | Cross-platform | 2 min | Modern, responsive, mobile-friendly |
| **CLI Menu** | Scripting | Instant | Lightweight, no dependencies |

**Recommended:** Start with CLI Menu for validation, then use Web GUI for interactive processing.
