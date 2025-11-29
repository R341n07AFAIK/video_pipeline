#!/usr/bin/env python3
"""Generate creative Midjourney prompts for video processing."""

import argparse
import random
from pathlib import Path

STYLES = [
    "cinematic", "dramatic", "ethereal", "vibrant", "dark", "light",
    "atmospheric", "minimalist", "surreal", "abstract"
]

MOODS = [
    "intense", "calm", "energetic", "mysterious", "joyful", "contemplative",
    "dynamic", "serene", "chaotic", "harmonious"
]

EFFECTS = [
    "particle effects", "neon glow", "bokeh", "motion blur",
    "lens flare", "volumetric lighting", "chromatic aberration",
    "film grain", "color grading", "depth of field"
]

def generate_prompt(base_prompt, count=1, style=None, mood=None):
    """Generate creative Midjourney prompts."""
    prompts = []
    
    for _ in range(count):
        prompt_parts = [base_prompt]
        
        if style:
            prompt_parts.append(f"style: {style}")
        else:
            prompt_parts.append(f"style: {random.choice(STYLES)}")
        
        if mood:
            prompt_parts.append(f"mood: {mood}")
        else:
            prompt_parts.append(f"mood: {random.choice(MOODS)}")
        
        prompt_parts.append(f"with {random.choice(EFFECTS)}")
        
        prompts.append(", ".join(prompt_parts))
    
    return prompts

def main():
    parser = argparse.ArgumentParser(description="Generate Midjourney prompts")
    parser.add_argument("base_prompt", help="Base prompt to enhance")
    parser.add_argument("-c", "--count", type=int, default=5, help="Number of prompts to generate")
    parser.add_argument("-s", "--style", help="Specific style to use")
    parser.add_argument("-m", "--mood", help="Specific mood to use")
    parser.add_argument("-o", "--output", help="Save prompts to file")
    
    args = parser.parse_args()
    
    print("=== Midjourney Prompt Generator ===")
    print(f"Base Prompt: {args.base_prompt}")
    print(f"Generating: {args.count} prompt(s)")
    print()
    
    prompts = generate_prompt(args.base_prompt, args.count, args.style, args.mood)
    
    for i, prompt in enumerate(prompts, 1):
        print(f"[{i}] {prompt}")
    
    if args.output:
        output_path = Path(args.output)
        output_path.parent.mkdir(parents=True, exist_ok=True)
        with open(output_path, "w") as f:
            f.write("\n".join(prompts))
        print(f"\nPrompts saved to: {output_path}")

if __name__ == "__main__":
    main()
