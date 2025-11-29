# API Keys Configuration Guide

## Overview

This guide explains how to configure API keys for different AI providers supported by the video pipeline.

## Supported Providers

### 1. Grok (xAI)

**Description**: Advanced image generation and video understanding AI

**Getting an API Key**:
1. Visit [xAI Console](https://console.x.ai/)
2. Sign in or create account
3. Navigate to API Keys section
4. Click "Create New Key"
5. Copy the key immediately (you won't see it again)

**Configuration**:

```powershell
# Using setup script
.\setup-environment.ps1

# Or manually
$env:XAI_API_KEY = "xai-xxxxxxxxxxxxx"
$env:XAI_ENDPOINT = "https://api.x.ai/v1"

# Or in .env file
XAI_API_KEY=xai-xxxxxxxxxxxxx
XAI_ENDPOINT=https://api.x.ai/v1
```

**Testing**:
```powershell
# Test connection
python -c "import os; print('Grok API Key:', 'SET' if os.getenv('XAI_API_KEY') else 'NOT SET')"
```

**Pricing**: Check xAI website for current rates

**Rate Limits**: Refer to xAI API documentation

### 2. Midjourney

**Description**: Premium image generation AI with high-quality artistic output

**Getting an API Key**:
1. Visit [Midjourney Discord](https://discord.gg/midjourney)
2. Subscribe to Midjourney service
3. Visit [Midjourney API Dashboard](https://www.midjourney.com/api/)
4. Generate API key
5. Copy and store securely

**Configuration**:

```powershell
# Using setup script
.\setup-environment.ps1

# Or manually
$env:MIDJOURNEY_API_KEY = "mj_xxxxxxxxxxxxx"
$env:MIDJOURNEY_ENDPOINT = "https://api.midjourney.com/v1"

# Or in .env file
MIDJOURNEY_API_KEY=mj_xxxxxxxxxxxxx
MIDJOURNEY_ENDPOINT=https://api.midjourney.com/v1
```

**Testing**:
```powershell
# Verify key is set
$env:MIDJOURNEY_API_KEY
```

**Pricing**: Premium subscription required (pay-as-you-go or monthly)

**Rate Limits**: Typically 60 requests/minute

### 3. ComfyUI (Local)

**Description**: Free, open-source AI model inference locally on your machine

**Installation**:
```powershell
# Automatic installation
.\install-prerequisites.ps1

# Manual installation
git clone https://github.com/comfyanonymous/ComfyUI.git
cd ComfyUI
pip install -r requirements.txt
python main.py
```

**Configuration**:

```json
{
  "comfyui_host": "127.0.0.1",
  "comfyui_port": 8188,
  "comfyui_secure": false
}
```

**Usage**:
```powershell
# No API key required - runs locally!
# Just ensure ComfyUI server is running:
python ComfyUI/main.py

# Or use Docker:
docker-compose up -d comfyui
```

**Cost**: Free (only GPU/CPU resources)

**Advantages**:
- No API costs
- No rate limits
- Complete privacy
- Works offline

### 4. Claude (Anthropic) - Future Support

**Description**: Advanced language model for text processing (planned)

**When Available**:
1. Visit [Anthropic Console](https://console.anthropic.com/)
2. Create account or sign in
3. Go to API Keys section
4. Generate new key
5. Store securely

**Configuration** (when implemented):
```powershell
$env:ANTHROPIC_API_KEY = "sk-ant-xxxxxxxxxxxxx"
```

## Environment Variables

### Setting Permanently (Windows)

**Method 1: GUI**
1. Press `Win + X` → Select "System"
2. Click "Advanced system settings"
3. Click "Environment Variables"
4. Click "New" under User variables
5. Add variable name and value
6. Restart PowerShell

**Method 2: PowerShell (Admin)**
```powershell
[Environment]::SetEnvironmentVariable("XAI_API_KEY", "your_key_here", "User")
```

**Method 3: Using .env file**
```powershell
# Copy template
Copy-Item .env.example .env

# Edit with your keys
notepad .env
```

## Configuration Options

### Full Configuration in pipeline.config.json

```json
{
  "ai_providers": {
    "grok": {
      "enabled": true,
      "api_key": "xai-xxxxxxxxxxxxx",
      "endpoint": "https://api.x.ai/v1",
      "model": "grok-vision-beta",
      "timeout": 60,
      "retry_count": 3
    },
    "midjourney": {
      "enabled": true,
      "api_key": "mj_xxxxxxxxxxxxx",
      "endpoint": "https://api.midjourney.com/v1",
      "timeout": 120,
      "retry_count": 2
    },
    "comfyui": {
      "enabled": true,
      "host": "127.0.0.1",
      "port": 8188,
      "secure": false,
      "timeout": 300
    }
  },
  "api_defaults": {
    "delay_ms": 1000,
    "retry_strategy": "exponential",
    "fallback_provider": "comfyui",
    "timeout": 60
  }
}
```

## Best Practices

### Security

1. **Never commit API keys to version control**
   - Use .env file (already in .gitignore)
   - Use environment variables
   - Use .env.example as template

2. **Rotate keys regularly**
   - Monthly or after team changes
   - Immediately if compromised

3. **Use different keys for different environments**
   ```powershell
   # Development
   $env:XAI_API_KEY = "dev_key_xxx"
   
   # Production
   $env:XAI_API_KEY = "prod_key_xxx"
   ```

4. **Restrict API key permissions**
   - Use most restrictive permissions available
   - Create separate keys for different integrations
   - Monitor usage through provider dashboards

5. **Store keys securely**
   - Use Windows Credential Manager for sensitive keys
   - Consider using Azure Key Vault for production
   - Encrypt configuration files if needed

### Cost Optimization

1. **Use ComfyUI for testing**
   - Free alternative for development
   - No API costs
   - No rate limits

2. **Batch operations during off-hours**
   - Cheaper rates on some providers
   - Better performance

3. **Monitor usage**
   - Set up alerts in provider dashboards
   - Review bills regularly
   - Optimize batch sizes

4. **Implement caching**
   - Reuse generated images
   - Skip duplicate prompts
   - Store in output/ directory

### Rate Limit Management

1. **Implement delays between requests**
   ```json
   {
     "api_delay_ms": 2000
   }
   ```

2. **Batch processing**
   ```powershell
   # Process in smaller batches
   .\cli-menu.ps1  # Option 7: Batch Process
   ```

3. **Use fallback providers**
   - Configure ComfyUI as fallback
   - Automatic failover on rate limit

4. **Monitor rate limit headers**
   - Check response headers
   - Adjust request frequency

## Troubleshooting API Configuration

### "API Key Invalid"

```powershell
# Verify key is set
$env:XAI_API_KEY

# Test with curl
$headers = @{
  "Authorization" = "Bearer $($env:XAI_API_KEY)"
  "Content-Type" = "application/json"
}
Invoke-RestMethod -Uri "https://api.x.ai/v1/models" -Headers $headers
```

### "Connection Refused"

```powershell
# Check endpoint
Test-NetConnection -ComputerName api.x.ai -Port 443

# Verify firewall
Get-NetFirewallRule | ? {$_.Name -like "*443*"}
```

### "Rate Limit Exceeded"

```powershell
# Increase delay in config
$config = Get-Content pipeline.config.json | ConvertFrom-Json
$config.api_defaults.delay_ms = 5000
$config | ConvertTo-Json | Set-Content pipeline.config.json
```

## API Documentation Links

- **Grok**: https://docs.x.ai/
- **Midjourney**: https://docs.midjourney.com/docs/api-reference
- **ComfyUI**: https://github.com/comfyanonymous/ComfyUI#web-interface
- **Anthropic**: https://docs.anthropic.com/ (future)

## Support

- For API-specific issues, contact the provider support
- For pipeline integration issues, check TROUBLESHOOTING.md
- Enable verbose logging: `$VerbosePreference = "Continue"`
