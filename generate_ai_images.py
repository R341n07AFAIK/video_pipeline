#!/usr/bin/env python3
"""Generate AI images from text prompts using various providers."""

import argparse
import os
import sys
from pathlib import Path

def generate_with_grok(prompt, output_path, api_key=None):
    """Generate image using Grok API."""
    if api_key is None:
        api_key = os.getenv("XAI_API_KEY")
    
    if not api_key:
        print("ERROR: XAI_API_KEY not set")
        return False
    
    print(f"Generating image with Grok: {prompt}")
    print(f"Output: {output_path}")
    # Placeholder for actual Grok API call
    return True

def generate_with_midjourney(prompt, output_path):
    """Generate image using Midjourney API."""
    print(f"Generating image with Midjourney: {prompt}")
    print(f"Output: {output_path}")
    # Placeholder for actual Midjourney API call
    return True

def main():
    parser = argparse.ArgumentParser(description="Generate AI images from prompts")
    parser.add_argument("prompt", help="Text prompt for image generation")
    parser.add_argument("-o", "--output", default="generated_image.png", help="Output file path")
    parser.add_argument("-p", "--provider", choices=["grok", "midjourney"], default="grok", help="AI provider")
    parser.add_argument("-k", "--api-key", help="API key (or set XAI_API_KEY env var)")
    
    args = parser.parse_args()
    
    print("=== AI Image Generator ===")
    print(f"Provider: {args.provider}")
    print(f"Prompt: {args.prompt}")
    print()
    
    output_path = Path(args.output)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    
    if args.provider == "grok":
        success = generate_with_grok(args.prompt, str(output_path), args.api_key)
    elif args.provider == "midjourney":
        success = generate_with_midjourney(args.prompt, str(output_path))
    else:
        print(f"ERROR: Unknown provider: {args.provider}")
        return 1
    
    if success:
        print(f"\nImage generation requested: {output_path}")
        return 0
    else:
        return 1

if __name__ == "__main__":
    sys.exit(main())
