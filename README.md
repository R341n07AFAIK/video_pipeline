# Video Pipeline - Unified AI Video Processing

A comprehensive, modular video processing pipeline with support for multiple AI providers (Grok, Midjourney, ComfyUI) and professional video processing capabilities.

## Features

-  **Video Processing**: Frame extraction, compositing, stitching, upscaling
-  **Multi-Provider AI**: Support for Grok, Midjourney, Claude, and ComfyUI
-  **Orchestration**: PowerShell-based pipeline orchestration
-  **FFmpeg Integration**: Professional-grade video processing
-  **Python Modules**: AI client, video processing utilities
-  **Modular Design**: Easy to extend and customize

## System Requirements

- Windows PowerShell 5.1+ (or PowerShell 7+)
- FFmpeg 8.0+
- Python 3.12+
- Minimum 4GB RAM, 10GB free disk space

## Installation

### 1. Install FFmpeg
```powershell
winget install --id Gyan.FFmpeg --source winget
```

### 2. Verify Installation
```powershell
.\orchestrator.ps1 -Mode validate
```

### 3. Set API Keys (Optional)
```powershell
setx XAI_API_KEY "your-grok-key"
setx MIDJOURNEY_API_KEY "your-midjourney-key"
```

## Quick Start

### Process Videos with Grok
```powershell
.\one_click_ai_pipeline.ps1 -InputFolder "C:\videos" -OutputFolder "output" -Provider grok
```

### Extract Frames
```powershell
.\extract_frames.ps1 -VideoPath "input.mp4" -OutputFolder "frames" -FPS 24
```

### Stitch Frames to Video
```powershell
.\stitch_all_images.ps1 -SourceFolder "frames" -OutputVideo "output.mp4" -FPS 24
```

### Run Full Pipeline
```powershell
.\orchestrator.ps1 -InputFolder input -OutputFolder output -Providers @("grok", "comfyui")
```

## Project Structure

```
video_pipeline/
├── orchestrator.ps1              # Main pipeline orchestrator
├── ffmpeg-utils.ps1              # FFmpeg utility functions
├── unified_ai_core.ps1           # Core AI functions
├── pipeline.config.json          # Pipeline configuration
 providers/                    # Provider-specific scripts
    process-grok.ps1
    process-midjourney.ps1
    process-comfyui.ps1
 python_modules/               # Python integration
    ai_client.py              # Unified AI client
    video_processor.py        # Video processing utilities
 Full Pipelines/
    one_click_ai_pipeline.ps1
    full_ai_pipeline.ps1
    full_ai_pipeline_with_audio.ps1
    full_ai_pipeline_with_video.ps1
 Utilities/
     extract_frames.ps1
     composite_video_from_images.ps1
     stitch_all_images.ps1
     ... more utilities
```

## Usage Examples

### Example 1: Simple Frame Extraction
```powershell
.\extract_frames.ps1 -VideoPath "movie.mp4" -OutputFolder "frames" -FPS 30
```

### Example 2: Composite Processing
```powershell
.\composite_images_pipeline.ps1 -VideoPath "input.mp4" -OutputVideo "output.mp4" -FPS 24
```

### Example 3: Multi-Provider Processing
```powershell
.\full_multi_ai_pipeline.ps1 -InputFolder "input" -Providers @("grok", "comfyui")
```

### Example 4: ComfyUI Integration
```powershell
.\full_multi_ai_pipeline_comfyui.ps1 -InputFolder "input" -ComfyUIServer "http://localhost:8188"
```

### Example 5: Live Streaming Capture
```powershell
.\unified_ai_pipeline_live.ps1 -StreamURL "rtmp://localhost/live/stream" -Provider "grok"
```

## API Integration

### Grok API
- Requires: `XAI_API_KEY` environment variable
- Supports: Video processing, image generation
- Endpoint: `https://api.x.ai/video/process`

### Midjourney
- Requires: `MIDJOURNEY_API_KEY` environment variable
- Supports: Image generation from prompts
- Automatic fallback to local processing

### ComfyUI
- Local-only processing (no API key needed)
- Default: `http://localhost:8188`
- Requires: ComfyUI running locally

## Configuration

Edit `pipeline.config.json` to customize:

```json
{
  "video": {
    "fps": 24,
    "codec": "libx264",
    "preset": "medium",
    "quality": 23
  },
  "providers": {
    "enabled": ["grok", "comfyui"]
  }
}
```

## FFmpeg Utilities

The `ffmpeg-utils.ps1` module provides:

- `Get-VideoInfo` - Extract video metadata
- `Convert-Video` - Change codec/resolution
- `Extract-Frames` - Frame extraction
- `Stitch-Frames` - Create video from frames
- `Upscale-Video` - 2x/4x upscaling
- `Concat-Videos` - Merge multiple videos

Usage:
```powershell
. .\ffmpeg-utils.ps1
Get-VideoInfo -VideoPath "input.mp4"
Convert-Video -InputFile "input.mp4" -OutputFile "output.mp4" -FPS 60
```

## Python Modules

### ai_client.py
Unified AI client supporting multiple providers:

```python
from python_modules.ai_client import get_client

client = get_client("grok")
client.process_video("video.mp4", "Enhance and upscale")
client.generate_image("A sunset", "output.png")
```

### video_processor.py
Video processing utilities:

```python
from python_modules.video_processor import VideoProcessor

processor = VideoProcessor()
processor.extract_frames("input.mp4", "frames", fps=30)
processor.upscale_video("input.mp4", "output_2x.mp4", scale_factor=2)
```

## Troubleshooting

### FFmpeg Not Found
```powershell
winget install --id Gyan.FFmpeg --source winget
# Then restart PowerShell
```

### API Key Issues
```powershell
# Verify environment variable is set
$env:XAI_API_KEY
setx XAI_API_KEY "your-actual-key"
```

### ComfyUI Connection Failed
Ensure ComfyUI is running:
```bash
python main.py
```

## Logging

Logs are saved to `logs/` directory with timestamp:
```
logs/pipeline_20241129_143052.log
```

## Performance Tips

1. **Batch Processing**: Process multiple videos in sequence
2. **GPU Acceleration**: FFmpeg uses NVIDIA/AMD GPU when available
3. **Resolution**: Lower resolution = faster processing
4. **Codec**: Use `libx264` for compatibility, `libx265` for compression

## Advanced Features

### Custom Workflows
Create custom PowerShell scripts:

```powershell
. .\ffmpeg-utils.ps1
. .\unified_ai_core.ps1

$config = @{fps=30; codec="libx265"}
Process-WithAI -InputPath "input.mp4" -OutputPath "output.mp4" -Prompt "Enhance quality"
```

### Chaining Operations
```powershell
.\extract_frames.ps1 -VideoPath "input.mp4" -OutputFolder "frames"
# ... process frames with external tool ...
.\stitch_all_images.ps1 -SourceFolder "frames" -OutputVideo "output.mp4"
```

## Contributing

To add a new provider:

1. Create `providers/process-newprovider.ps1`
2. Update `orchestrator.ps1` to include new provider
3. Add Python module to `python_modules/`

## License

See LICENSE file for details.

## Support

For issues and questions:
- Check logs in `logs/` directory
- Review configuration in `pipeline.config.json`
- Validate prerequisites with: `.\orchestrator.ps1 -Mode validate`
