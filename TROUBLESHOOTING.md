# Troubleshooting Guide

## Common Issues and Solutions

### FFmpeg Issues

#### "ffmpeg not found" or "ffmpeg command not recognized"

**Cause**: FFmpeg is not installed or not in PATH

**Solutions**:
1. Run the installation script:
   ```powershell
   .\install-prerequisites.ps1
   ```

2. Verify installation:
   ```powershell
   ffmpeg -version
   ```

3. Manually add to PATH:
   - Go to System Properties > Environment Variables
   - Add FFmpeg bin directory to PATH
   - Restart PowerShell

#### "Invalid codec" errors

**Cause**: FFmpeg codec missing or encoding option incompatible

**Solutions**:
1. Check available codecs:
   ```powershell
   ffmpeg -codecs | findstr h264
   ```

2. Use fallback codec in pipeline.config.json:
   ```json
   {
     "video_codec": "mpeg4"
   }
   ```

3. Update FFmpeg to latest version

### Python Issues

#### "Python not found" error

**Cause**: Python not installed or not in PATH

**Solutions**:
1. Install via script:
   ```powershell
   .\install-prerequisites.ps1
   ```

2. Verify installation:
   ```powershell
   python --version
   ```

#### "ModuleNotFoundError: No module named 'requests'"

**Cause**: Required Python packages not installed

**Solutions**:
1. Install requirements:
   ```powershell
   pip install -r requirements.txt
   ```

2. Specify Python path in pipeline.config.json:
   ```json
   {
     "python_path": "C:\\Python312\\python.exe"
   }
   ```

### API Issues

#### "API key invalid" or "401 Unauthorized"

**Cause**: Incorrect or expired API key

**Solutions**:
1. Verify API key format:
   ```powershell
   echo $env:XAI_API_KEY
   ```

2. Run setup script:
   ```powershell
   .\setup-environment.ps1
   ```

3. Check API provider dashboard for valid keys

#### "Connection refused" or "Cannot reach API endpoint"

**Cause**: Network issue, server down, or incorrect endpoint

**Solutions**:
1. Test network connectivity:
   ```powershell
   Test-NetConnection api.x.ai -Port 443
   ```

2. Check endpoint in pipeline.config.json:
   ```json
   {
     "grok_endpoint": "https://api.x.ai/v1"
   }
   ```

3. Verify firewall/proxy settings

#### "Rate limit exceeded"

**Cause**: Too many API requests in short time

**Solutions**:
1. Increase delay between requests in pipeline.config.json:
   ```json
   {
     "api_delay_ms": 2000
   }
   ```

2. Reduce batch size

3. Use local ComfyUI processing instead

### ComfyUI Issues

#### "ComfyUI server not responding"

**Cause**: ComfyUI not running or port misconfigured

**Solutions**:
1. Start ComfyUI:
   ```powershell
   cd ComfyUI
   python main.py
   ```

2. Verify port in pipeline.config.json:
   ```json
   {
     "comfyui_port": 8188
   }
   ```

3. Check with docker-compose:
   ```powershell
   docker-compose up -d comfyui
   ```

### GUI Issues

#### WinForms GUI doesn't open

**Cause**: Missing .NET assemblies or invalid code

**Solutions**:
1. Verify .NET Framework 4.5+:
   ```powershell
   Get-ChildItem "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP"
   ```

2. Run in admin PowerShell:
   ```powershell
   Start-Process powershell -Verb runAs
   .\pipeline-gui.ps1
   ```

3. Check execution policy:
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

#### Web GUI shows blank page

**Cause**: Server not running or port in use

**Solutions**:
1. Check if port 8000 is available:
   ```powershell
   netstat -ano | findstr :8000
   ```

2. Kill process using port:
   ```powershell
   Get-Process | Where-Object {$_.Handles -eq 8000} | Stop-Process -Force
   ```

3. Use alternate port in start-gui.ps1

#### CLI menu not responding

**Cause**: Input buffering or encoding issue

**Solutions**:
1. Set console encoding:
   ```powershell
   [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
   ```

2. Run in Windows Terminal instead of legacy console

3. Restart PowerShell session

### Video Processing Issues

#### "Unsupported pixel format" error

**Cause**: Video codec incompatible with processing chain

**Solutions**:
1. Convert video first:
   ```powershell
   ffmpeg -i input.mp4 -c:v h264 -c:a aac output.mp4
   ```

2. Specify input format in pipeline.config.json:
   ```json
   {
     "input_format": "h264"
   }
   ```

#### "Frame extraction failed"

**Cause**: Video file corrupted or unsupported codec

**Solutions**:
1. Verify video file:
   ```powershell
   ffmpeg -i input.mp4 -f null NUL
   ```

2. Re-encode video:
   ```powershell
   ffmpeg -i input.mp4 -c:v libx264 -preset medium output.mp4
   ```

3. Check video format:
   ```powershell
   ffprobe -v error -show_format -show_streams input.mp4
   ```

#### "Output file larger than input"

**Cause**: Upscaling or codec settings increasing file size

**Solutions**:
1. Reduce bitrate in pipeline.config.json:
   ```json
   {
     "video_bitrate": "4000k"
   }
   ```

2. Use h265 codec (better compression):
   ```json
   {
     "video_codec": "hevc"
   }
   ```

3. Enable CRF quality mode (variable bitrate)

### Performance Issues

#### "Pipeline runs very slowly"

**Cause**: GPU not used, suboptimal settings, or system load

**Solutions**:
1. Enable GPU acceleration (NVIDIA):
   ```powershell
   $env:CUDA_VISIBLE_DEVICES = 0
   ```

2. Adjust thread count in pipeline.config.json:
   ```json
   {
     "ffmpeg_threads": 8
   }
   ```

3. Reduce output resolution for testing

#### "Out of memory" errors

**Cause**: Processing large videos or too many concurrent tasks

**Solutions**:
1. Process smaller segments:
   ```json
   {
     "segment_size": 60
   }
   ```

2. Reduce batch size

3. Close other applications

4. Increase system virtual memory

### Logging and Debugging

#### Enable verbose logging

```powershell
# In PowerShell
$DebugPreference = "Continue"
$VerbosePreference = "Continue"

.\orchestrator.ps1 -Mode validate -Verbose
```

#### Check log files

```powershell
# View latest log
Get-ChildItem logs\pipeline_*.log -Latest 1 | Get-Content -Tail 50

# Search for errors
Select-String -Path logs\*.log -Pattern "ERROR|WARN"
```

#### Validate system configuration

```powershell
.\orchestrator.ps1 -Mode validate
```

This will check:
- FFmpeg availability and version
- Python availability and required modules
- API key configuration
- File permissions
- Disk space

### Getting Help

If you encounter issues not covered here:

1. Check the detailed logs in `logs/` directory
2. Review INTEGRATION_SUMMARY.md for architecture details
3. Check API provider documentation for service status
4. Enable verbose logging and try again
5. Report issues with:
   - Error message
   - System information (OS version, FFmpeg version, Python version)
   - Steps to reproduce
   - Log file excerpt
