# Architecture Overview

## System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     User Interfaces                          │
├──────────────────────┬──────────────────────┬────────────────┤
│  WinForms GUI        │   Web GUI (SPA)      │   CLI Menu     │
│  pipeline-gui.ps1    │  web-gui/            │ cli-menu.ps1   │
│  - 3 Tabs            │  - 4 Tabs            │ - 14 Options   │
│  - File Dialogs      │  - Responsive        │ - Interactive  │
│  - Real-time Logs    │  - localStorage      │ - Lightweight  │
└──────────────────────┴──────────────────────┴────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│              Orchestration Layer                             │
│  orchestrator.ps1 (Master Controller)                        │
├─────────────────────────────────────────────────────────────┤
│  • Configuration Management (pipeline.config.json)           │
│  • Prerequisite Validation (FFmpeg, Python, APIs)           │
│  • Logging & Error Handling                                 │
│  • Provider Selection & Failover                            │
│  • Batch Job Management                                      │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌──────────────────────────────────────────────────────────────┐
│         Core Processing Layer                                │
├──────────────┬──────────────────────────┬──────────────────┤
│ FFmpeg Utils │   AI Core Module         │  Video Processor │
│ffmpeg-utils  │  unified_ai_core.ps1     │ video_processor  │
│ .ps1          │  • Provider Detection    │ .py              │
├──────────────┼──────────────────────────┼──────────────────┤
│ Functions:   │ • Initialization         │ Functions:       │
│ • Extract    │ • Dispatch Logic         │ • Extract Frames │
│ • Convert    │ • Fallback Handling      │ • Stitch Frames  │
│ • Upscale    │ • Validation             │ • Convert Video  │
│ • Concat     │                          │ • Upscale Video  │
│ • GetInfo    │                          │ • Concat Videos  │
└──────────────┴──────────────────────────┴──────────────────┘
                              ↓
┌──────────────────────────────────────────────────────────────┐
│         Provider Integration Layer                            │
├──────────────┬──────────────────────────┬──────────────────┤
│   Grok       │   Midjourney             │   ComfyUI        │
│  (xAI API)   │   (API Integration)      │   (Local HTTP)   │
├──────────────┼──────────────────────────┼──────────────────┤
│ Process:     │ Process:                 │ Process:         │
│ • Image Gen  │ • Image Generation       │ • Local Models   │
│ • Upscaling  │ • Style Transfer         │ • GPU Inference  │
│ • Enhancement│ • Batch Processing       │ • Workflow Exec  │
│ • API Calls  │ • Queue Management       │ • HTTP Requests  │
└──────────────┴──────────────────────────┴──────────────────┘
                              ↓
┌──────────────────────────────────────────────────────────────┐
│            System Dependencies                                │
├──────────────┬──────────────────────────┬──────────────────┤
│  FFmpeg      │   Python 3.12+           │  System Services │
│  8.0.1+      │   • requests             │  • Network       │
│  • Codecs    │   • Pillow               │  • Disk I/O      │
│  • Filters   │   • numpy                │  • GPU (opt)     │
│  • GPU Accel │   • ffmpeg-python        │  • Memory        │
└──────────────┴──────────────────────────┴──────────────────┘
```

## Component Responsibilities

### 1. Orchestrator (orchestrator.ps1)

**Role**: Master controller and orchestration engine

**Responsibilities**:
- Configuration loading and validation
- Prerequisite checking (FFmpeg, Python, API keys)
- Provider selection and routing
- Job queue management
- Logging and error handling
- Report generation

**Key Functions**:
- `Test-Prerequisites` - System validation
- `Load-Configuration` - Config file parsing
- `Process-Videos` - Main processing loop
- `Test-Provider` - Provider availability checking
- `Generate-Report` - Output summary

**Dependencies**: FFmpeg, Python, all providers

### 2. FFmpeg Utils (ffmpeg-utils.ps1)

**Role**: Video processing utilities wrapper

**Responsibilities**:
- Video format detection and validation
- Codec conversion and transcoding
- Frame extraction from videos
- Video composition from frames
- Video upscaling using AI
- Multi-file concatenation

**Key Functions**:
- `Get-VideoInfo` - Retrieve video metadata (duration, codec, resolution)
- `Convert-Video` - Transcode to different codecs/formats
- `Extract-Frames` - Export video frames as images
- `Stitch-Frames` - Compose images into video
- `Upscale-Video` - 2x/4x resolution upscaling
- `Concat-Videos` - Merge multiple video files

**Dependencies**: FFmpeg 8.0.1+

### 3. AI Core Module (unified_ai_core.ps1)

**Role**: AI provider abstraction and coordination

**Responsibilities**:
- Unified interface for all providers
- Provider initialization and detection
- Video validation before processing
- Error handling and fallback logic
- Dispatch to appropriate provider

**Key Functions**:
- `Initialize-AIEnvironment` - Setup and detect available providers
- `Test-VideoFile` - Validate video before processing
- `Get-VideoDuration` - Query video length
- `Process-WithAI` - Main dispatch function
- `Get-AvailableProviders` - List configured providers

**Dependencies**: ffmpeg-utils.ps1, all provider modules

### 4. Video Processor (python_modules/video_processor.py)

**Role**: Python-based video processing engine

**Responsibilities**:
- Cross-platform video operations
- FFmpeg subprocess management
- Image processing and composition
- Batch frame operations
- Error handling and logging

**Key Methods**:
- `extract_frames()` - Export video to frames
- `stitch_frames()` - Create video from images
- `convert_video()` - Transcode video
- `upscale_video()` - Scale video resolution
- `concat_videos()` - Merge video files
- `get_video_info()` - Retrieve metadata

**Dependencies**: FFmpeg, ffmpeg-python, Pillow

### 5. AI Client (python_modules/ai_client.py)

**Role**: Unified AI provider interface

**Responsibilities**:
- Multi-provider abstraction (Grok, Midjourney, ComfyUI, Claude)
- API request handling and retry logic
- Error handling and fallback management
- Response parsing and validation
- Logging and metrics

**Key Classes**:
- `AIClient` - Factory pattern provider abstraction
  - `process_video()` - Submit video for processing
  - `generate_image()` - Create images from prompts
  - `process_batch()` - Handle batch operations

**Dependencies**: requests, environment variables

### 6. Provider Modules (providers/process-*.ps1)

**Role**: Provider-specific implementations

#### process-grok.ps1
- Grok API integration (xAI)
- Image generation and enhancement
- API authentication and error handling
- Response parsing

#### process-midjourney.ps1
- Midjourney API integration
- Image generation with presets
- Queue management
- Webhook handling

#### process-comfyui.ps1
- Local ComfyUI HTTP interface
- Workflow execution
- Model management
- No API key required

## Data Flow

### Video Processing Pipeline

```
INPUT VIDEO
    ↓
[orchestrator.ps1]
    ↓
Config Load → Prerequisite Check → Provider Detection
    ↓
[ffmpeg-utils.ps1]
    ↓
Extract Frames → [Optional: Upscale Frames]
    ↓
[AI Provider]
    ↓
Process Each Frame → Generate Output
    ↓
[ffmpeg-utils.ps1]
    ↓
Stitch Frames → Convert Video → Optimize
    ↓
OUTPUT VIDEO
    ↓
Generate Report → Logging
```

### API Request Flow

```
USER INPUT
    ↓
[UI Layer]
    ↓
Configuration Validation
    ↓
[orchestrator.ps1]
    ↓
Select Provider
    ↓
[unified_ai_core.ps1]
    ↓
Dispatch to Provider
    ↓
[AI Client / Provider Module]
    ↓
API Request with Auth
    ↓
Error Handling & Retry
    ↓
Response Parsing
    ↓
[Back to orchestrator]
    ↓
Post-Processing (if needed)
    ↓
UI Update / File Output
```

## Configuration Management

### Configuration Hierarchy

```
1. pipeline.config.json (Default)
   ↓
2. .env file (Override)
   ↓
3. Environment Variables (Override)
   ↓
4. Command-line Arguments (Override)
```

### pipeline.config.json Structure

```json
{
  "video_defaults": {
    "codec": "h264",
    "bitrate": "8000k",
    "fps": 30,
    "resolution": "1920x1080"
  },
  "ai_providers": {
    "grok": { "enabled": true, "endpoint": "..." },
    "midjourney": { "enabled": true, "endpoint": "..." },
    "comfyui": { "enabled": true, "host": "127.0.0.1", "port": 8188 }
  },
  "paths": {
    "input": "./input",
    "output": "./output",
    "logs": "./logs",
    "temp": "./temp"
  },
  "api_defaults": {
    "timeout": 60,
    "retry_count": 3,
    "delay_ms": 1000
  }
}
```

## Error Handling Strategy

### Provider Fallback Chain

```
Primary Provider (User Selected)
    ↓ (if failed)
Secondary Provider (Configured)
    ↓ (if failed)
Local ComfyUI
    ↓ (if failed)
Error Log & User Notification
```

### Retry Strategy

```
Initial Request
    ↓ (if timeout/transient error)
Exponential Backoff Retry
    ↓ (attempt 1: 1s, attempt 2: 2s, attempt 3: 4s)
Success / Max Retries Exceeded
```

## Performance Optimization

### GPU Acceleration

```
FFmpeg (NVIDIA NVENC/AMD VCE)
    ↓
Enable in pipeline.config.json:
"gpu_encode": true
"gpu_decode": true

ComfyUI (CUDA/ROCm)
    ↓
Automatically detected in docker-compose.yml
```

### Parallelization

```
Batch Processing:
- Parallel frame extraction
- Concurrent API requests (with rate limit respect)
- Multi-threaded video encoding

Configuration:
"ffmpeg_threads": 8
"batch_size": 10
"concurrent_requests": 3
```

### Caching

```
Frame Cache: Reuse extracted frames
Result Cache: Skip reprocessing identical inputs
Configuration Cache: Loaded once at startup
API Response Cache: 1-hour TTL
```

## Security Architecture

### API Key Management

```
Environment Variables
    ↓
.env file (Git ignored)
    ↓
Windows Credential Manager (Optional)
    ↓
Never logged or displayed in UI
```

### Network Security

```
HTTPS for all external APIs
    ↓
Certificate validation
    ↓
Timeout protection
    ↓
Rate limiting
```

### File System Security

```
Input directory: Read-only option
Output directory: Write access
Temp directory: Auto-cleanup
Logs directory: Restricted access
```

## Deployment Architecture

### Standalone Deployment

```
Single machine installation
    ↓
PowerShell scripts + Python modules
    ↓
Local or cloud API usage
    ↓
Best for: Development, testing, small deployments
```

### Docker Deployment

```
docker-compose.yml
    ↓
ComfyUI Service (GPU-accelerated)
    ↓
FFmpeg Service (Containerized)
    ↓
Application Service
    ↓
Best for: Production, reproducibility, scaling
```

### Scalability Considerations

```
Horizontal Scaling:
- Multiple worker instances
- Shared job queue
- Load balancer
- Distributed logging

Vertical Scaling:
- GPU assignment
- Memory allocation
- CPU threading
- Disk I/O optimization
```

## Monitoring and Observability

### Logging System

```
Log File: logs/pipeline_TIMESTAMP.log
    ↓
Levels: ERROR, WARN, INFO, DEBUG, VERBOSE
    ↓
Rotation: Timestamp-based, daily
    ↓
Retention: Configurable
```

### Metrics Tracking

```
Processing Time: Per video, per operation
Resource Usage: CPU, Memory, GPU, Disk I/O
API Calls: Per provider, success/failure rates
Cache Hit Ratio: Frame cache effectiveness
Error Rates: By provider, by operation type
```

## Integration Points

### External Systems

```
AI Providers:
- Grok (xAI)
- Midjourney
- ComfyUI (Local HTTP)
- Claude (Planned)

Storage:
- Local filesystem
- Cloud storage (Planned)

Notification:
- Email alerts (Planned)
- Webhook callbacks (Planned)
- Slack integration (Planned)
```

### API Endpoints (Future Web API)

```
POST /api/process
  - Submit video for processing
  - Returns job ID

GET /api/status/{job_id}
  - Check processing status
  - Returns progress percentage

GET /api/output/{job_id}
  - Retrieve processed video
  - Streaming download

POST /api/batch
  - Submit batch job
  - Returns batch ID
```

## Technology Stack

| Layer | Technology | Version |
|-------|-----------|---------|
| Orchestration | PowerShell | 5.1+ |
| Video Processing | FFmpeg | 8.0.1+ |
| Python Runtime | Python | 3.12.10+ |
| Desktop GUI | Windows Forms | .NET 4.5+ |
| Web GUI | HTML5/CSS3/JS | Modern browsers |
| AI Providers | REST APIs | Latest |
| Containerization | Docker | 20.10+ |
| Task Scheduling | Windows Task Scheduler | Native |

## Future Architecture Enhancements

1. **Microservices**: Separate processing into independent services
2. **Message Queue**: Implement RabbitMQ/Kafka for job distribution
3. **Database**: Add PostgreSQL for job history and metrics
4. **API Gateway**: RESTful API for remote access
5. **WebSocket**: Real-time progress updates
6. **Authentication**: OAuth2/JWT for multi-user access
7. **Monitoring**: Prometheus + Grafana for metrics
8. **CI/CD**: GitHub Actions for automated testing
