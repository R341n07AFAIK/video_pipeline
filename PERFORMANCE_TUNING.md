# Performance Tuning Guide

## Overview

This guide provides optimization strategies for the video pipeline to achieve maximum performance, reduce resource consumption, and minimize processing time.

## Quick Performance Wins

### 1. Enable GPU Acceleration

**NVIDIA GPU (CUDA)**:
```powershell
# Edit pipeline.config.json
$config = Get-Content pipeline.config.json | ConvertFrom-Json
$config.ffmpeg_options = @{
  "hwaccel" = "cuda"
  "hwaccel_device" = "0"
}
$config | ConvertTo-Json | Set-Content pipeline.config.json
```

**AMD GPU (VCE)**:
```powershell
# Set environment variable
$env:FFMPEG_HWACCEL = "cuvid"  # or "videotoolbox" for Intel

# Or configure in pipeline.config.json
$config.ffmpeg_hwaccel = "cuvid"
```

**Performance Impact**: 5-10x faster encoding

### 2. Optimize FFmpeg Threading

```json
{
  "ffmpeg_options": {
    "threads": 8,
    "preset": "fast"
  }
}
```

**Settings**:
- `threads`: Number of CPU cores (default: detected)
- `preset`: ultrafast, superfast, veryfast, faster, fast, medium, slow, slower, veryslow

**Performance Impact**: 2-3x faster with optimal settings

### 3. Reduce Resolution for Testing

```powershell
# Process at lower resolution first
$env:PIPELINE_RESOLUTION = "1280x720"
$env:PIPELINE_QUALITY = "medium"
```

**Processing Time Reduction**: 50-75% faster

### 4. Enable Memory Caching

```json
{
  "cache": {
    "enabled": true,
    "frames_cache": true,
    "api_response_cache": true,
    "cache_ttl_minutes": 60,
    "max_cache_size_mb": 1024
  }
}
```

**Benefit**: Skip reprocessing identical inputs

## FFmpeg Optimization

### Codec Selection

**For Speed** (prioritize encoding speed):
```powershell
# MPEG4
ffmpeg -c:v mpeg4 -q 5

# ProRes (if available)
ffmpeg -c:v prores -profile:v 2
```

**For Compression** (prioritize file size):
```powershell
# H.265 (HEVC)
ffmpeg -c:v libx265 -crf 22

# VP9
ffmpeg -c:v libvpx-vp9 -crf 22
```

**For Speed + Quality Balance**:
```powershell
# H.264
ffmpeg -c:v libx264 -preset fast -crf 22
```

### Bitrate Optimization

```powershell
# Constant Quality (variable bitrate) - Best quality per file size
ffmpeg -c:v libx264 -crf 22 -c:a aac -q:a 5

# Target Bitrate (constant bitrate) - Predictable file size
ffmpeg -c:v libx264 -b:v 5000k -c:a aac -b:a 192k

# ABR (Average Bitrate) - Balance
ffmpeg -c:v libx264 -b:v 5000k -maxrate 6000k -bufsize 8000k
```

**Quality Guidelines**:
- 1080p: CRF 22-26 or 4000-8000k bitrate
- 720p: CRF 22-26 or 2000-4000k bitrate
- 480p: CRF 23-27 or 1000-2000k bitrate

### Parallel Processing

```powershell
# Process multiple videos in parallel
$videos = Get-ChildItem input/*.mp4
$videos | ForEach-Object -Parallel {
    ffmpeg -i $_.FullName -c:v libx264 -preset fast output/$_.Name
} -ThrottleLimit 4
```

**Throttle Limit**: Number of concurrent processes (typically: CPU cores / 2)

## Python Optimization

### Video Processor Optimization

```python
# Use NumPy for batch frame processing
import numpy as np

# Vectorized frame operations (faster)
frames = np.array([...])  # All frames
processed = frames * 0.9  # Brightness adjustment

# vs. loop-based (slower)
for frame in frames:
    frame = frame * 0.9
```

### Pillow Image Optimization

```python
# Resize with high-quality resampling
from PIL import Image

# Fast (lower quality)
img.resize((640, 480), Image.BILINEAR)

# Better quality (slower)
img.resize((640, 480), Image.LANCZOS)

# Batch convert images
from multiprocessing import Pool
with Pool(4) as p:
    results = p.map(process_image, image_list)
```

## API Optimization

### Rate Limiting and Batching

```json
{
  "api_defaults": {
    "batch_size": 10,
    "concurrent_requests": 3,
    "delay_ms": 500,
    "request_timeout": 120
  }
}
```

**Parameters**:
- `batch_size`: Images to process per API call
- `concurrent_requests`: Parallel API requests
- `delay_ms`: Wait between requests (respects rate limits)
- `request_timeout`: Seconds to wait for response

### ComfyUI Local Processing

**Best for performance** - No API calls, runs locally:

```powershell
# Pre-load models in ComfyUI
python ComfyUI/main.py --load-checkpoints

# Configuration for batch processing
$config.comfyui_batch_size = 20
$config.comfyui_queue_size = 50
```

**Performance**: 10-100x faster than cloud APIs for local processing

## Memory Management

### Reduce Memory Usage

```json
{
  "memory_options": {
    "max_frames_in_memory": 100,
    "streaming_mode": true,
    "temp_cleanup": true,
    "clear_cache_interval": 3600
  }
}
```

### Monitor Memory Usage

```powershell
# Check memory before processing
Get-Process | Where-Object {$_.Name -eq "ffmpeg"} | Select-Object WorkingSet

# Monitor during batch processing
while ($true) {
    Get-Process ffmpeg | Select-Object @{n="Memory(MB)";e={$_.WorkingSet/1MB}} | Format-Table
    Start-Sleep -Seconds 5
}
```

### Out of Memory Solutions

1. **Reduce frame batch size**:
   ```json
   { "batch_size": 5 }
   ```

2. **Process smaller video segments**:
   ```powershell
   # Split video before processing
   ffmpeg -i input.mp4 -c copy -segment_time 60 -f segment output_%03d.mp4
   ```

3. **Enable streaming mode**:
   ```json
   { "streaming_mode": true }
   ```

4. **Increase virtual memory** (temporary):
   ```powershell
   # Windows: System Properties > Advanced > Virtual Memory
   # Or use PowerShell script to modify registry
   ```

## Disk I/O Optimization

### SSD vs HDD

**Optimal Configuration**:
```
Input: HDD (read speed sufficient)
Output: SSD (faster write)
Temp: SSD (fastest operations)
```

### Buffer Size Optimization

```json
{
  "ffmpeg_buffer_size": 4096,
  "write_buffer_size": 65536,
  "read_buffer_size": 32768
}
```

### Reduce Temporary Files

```json
{
  "pipeline_options": {
    "use_pipes": true,
    "min_temp_storage": true,
    "cleanup_on_complete": true
  }
}
```

## Network Optimization

### API Connection Performance

```json
{
  "network": {
    "connection_pooling": true,
    "keep_alive": true,
    "compression": true,
    "dns_cache": true
  }
}
```

### Upload/Download Optimization

```powershell
# Use multiple connections for large files
$parallelism = 4
$fileSize = (Get-Item input.mp4).Length
$chunkSize = $fileSize / $parallelism

# Upload in chunks
1..$parallelism | % {
    Start-Job -ScriptBlock {
        # Parallel upload chunk
    }
}
```

## Database and Caching (Future)

### Redis Cache for API Responses

```json
{
  "cache_backend": "redis",
  "redis_host": "127.0.0.1",
  "redis_port": 6379,
  "cache_ttl": 3600
}
```

### Query Result Caching

```python
# Cache video info queries
import functools

@functools.lru_cache(maxsize=128)
def get_video_info(video_path):
    # Cached results for identical queries
    return ffprobe_data
```

## Batch Processing Performance

### Optimal Batch Configuration

```json
{
  "batch_processing": {
    "max_parallel_videos": 4,
    "queue_size": 50,
    "priority_queue": true,
    "estimated_time_per_video": 300
  }
}
```

### Batch Processing Example

```powershell
# Process 100 videos efficiently
$videos = Get-ChildItem input/*.mp4 | Select-Object -First 100

# Group by duration to balance load
$grouped = $videos | Group-Object {(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 $_.FullName) -as [int] / 60}

# Process each group in parallel
$grouped | ForEach-Object {
    $_.Group | ForEach-Object -Parallel {
        .\orchestrator.ps1 -InputFile $_.FullName
    } -ThrottleLimit 2
}
```

## Profiling and Benchmarking

### Profile Video Processing

```powershell
# Time each operation
$timer = [System.Diagnostics.Stopwatch]::StartNew()
ffmpeg -i input.mp4 output.mp4
$timer.Stop()
Write-Host "Encoding time: $($timer.ElapsedMilliseconds) ms"

# Profile CPU usage
$cpu = Get-CimInstance -ClassName Win32_PerfFormattedData_PerfProc_Process | 
       Where-Object {$_.Name -like "ffmpeg*"} | 
       Select-Object -ExpandProperty PercentProcessorTime
```

### Benchmark Different Settings

```powershell
# Compare codec performance
@(
    @{codec="libx264"; preset="fast"},
    @{codec="libx265"; preset="fast"},
    @{codec="mpeg4"}
) | % {
    $timer = [System.Diagnostics.Stopwatch]::StartNew()
    ffmpeg -i input.mp4 -c:v $_.codec -preset $_.preset test_$($_.codec).mp4
    $timer.Stop()
    Write-Host "Codec: $($_.codec), Time: $($timer.TotalSeconds)s"
}
```

## Performance Monitoring

### Real-time Monitoring Dashboard

```powershell
# Continuous monitoring script
while ($true) {
    Clear-Host
    Write-Host "=== Video Pipeline Performance ===" -ForegroundColor Cyan
    
    # CPU and Memory
    $cpuUsage = Get-CimInstance Win32_PerfFormattedData_PerfOS_Processor | 
                Select-Object -ExpandProperty PercentProcessorTime
    $memUsage = (Get-CimInstance Win32_OperatingSystem | 
                 Select-Object -ExpandProperty TotalVisibleMemorySize) -
                (Get-CimInstance Win32_OperatingSystem | 
                 Select-Object -ExpandProperty FreePhysicalMemory)
    
    Write-Host "CPU Usage: ${cpuUsage}%"
    Write-Host "Memory: $($memUsage/1024) MB"
    
    # FFmpeg processes
    Get-Process ffmpeg -ErrorAction SilentlyContinue | 
        Select-Object ID, Name, @{n="Memory(MB)";e={$_.WorkingSet/1MB}}, CPU
    
    Start-Sleep -Seconds 5
}
```

## Optimization Checklist

- [ ] Enable GPU acceleration (if available)
- [ ] Set FFmpeg threads to CPU core count
- [ ] Use fast preset for initial processing
- [ ] Choose appropriate codec for use case
- [ ] Enable frame caching
- [ ] Configure batch processing for multiple videos
- [ ] Monitor memory usage during processing
- [ ] Use SSD for output files
- [ ] Enable API response caching
- [ ] Configure connection pooling
- [ ] Run benchmarks on your hardware
- [ ] Monitor and log performance metrics
- [ ] Clean up temporary files regularly
- [ ] Update FFmpeg to latest version
- [ ] Review and optimize long-running pipelines

## Expected Performance

### Baseline (Single Video Processing)

| Operation | Duration | Hardware |
|-----------|----------|----------|
| Frame extraction | 30-60s | CPU Intel i7, 1080p video |
| API processing | 60-300s | Network dependent |
| Video stitching | 30-60s | CPU Intel i7 |
| Total | 2-5 min | Moderate hardware |

### Optimized (With GPU)

| Operation | Duration | Hardware |
|-----------|----------|----------|
| Frame extraction | 5-10s | NVIDIA RTX 3080, 1080p video |
| API processing | 60-300s | Network dependent |
| Video stitching | 5-10s | NVIDIA RTX 3080 |
| Total | 1-5 min | High-end GPU |

### Scaling (Batch Processing)

| Videos | Duration | Configuration |
|--------|----------|----------------|
| 10 | 10-15 min | 4 parallel workers |
| 50 | 40-60 min | 4 parallel workers |
| 100 | 80-120 min | 4 parallel workers, optimized |

## Support and Tuning Services

For specific performance optimization needs:
1. Profile your workload
2. Collect baseline metrics
3. Identify bottlenecks
4. Test configuration changes
5. Validate improvements

Use `.\orchestrator.ps1 -Mode benchmark` for automatic profiling
