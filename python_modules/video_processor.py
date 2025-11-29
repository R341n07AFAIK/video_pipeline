#!/usr/bin/env python3
"""Video processing utilities using ffmpeg-python"""

import os
import json
import subprocess
from pathlib import Path
from typing import Dict, List, Optional, Tuple
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class VideoProcessor:
    """Video processing utilities"""
    
    @staticmethod
    def get_video_info(video_path: str) -> Dict:
        """Get video metadata using ffprobe"""
        try:
            cmd = [
                "ffprobe",
                "-v", "error",
                "-print_format", "json",
                "-show_format",
                "-show_streams",
                video_path
            ]
            
            result = subprocess.run(cmd, capture_output=True, text=True, check=True)
            data = json.loads(result.stdout)
            
            stream = data["streams"][0]
            return {
                "duration": data["format"]["duration"],
                "size": data["format"]["size"],
                "width": stream.get("width"),
                "height": stream.get("height"),
                "fps": stream.get("r_frame_rate"),
                "codec": stream.get("codec_name")
            }
        except Exception as e:
            logger.error(f"Failed to get video info: {e}")
            return {}
    
    @staticmethod
    def extract_frames(video_path: str, output_folder: str, fps: int = 24) -> bool:
        """Extract frames from video"""
        try:
            Path(output_folder).mkdir(parents=True, exist_ok=True)
            
            frame_pattern = os.path.join(output_folder, "frame_%06d.png")
            cmd = [
                "ffmpeg",
                "-i", video_path,
                "-vf", f"fps={fps}",
                "-y",
                frame_pattern
            ]
            
            subprocess.run(cmd, check=True)
            logger.info(f"Frames extracted to: {output_folder}")
            return True
        except Exception as e:
            logger.error(f"Frame extraction failed: {e}")
            return False
    
    @staticmethod
    def stitch_frames(frame_folder: str, output_video: str, fps: int = 24) -> bool:
        """Create video from frame sequence"""
        try:
            frame_pattern = os.path.join(frame_folder, "frame_%06d.png")
            cmd = [
                "ffmpeg",
                "-framerate", str(fps),
                "-i", frame_pattern,
                "-c:v", "libx264",
                "-preset", "medium",
                "-pix_fmt", "yuv420p",
                "-y",
                output_video
            ]
            
            subprocess.run(cmd, check=True)
            logger.info(f"Video created: {output_video}")
            return True
        except Exception as e:
            logger.error(f"Video stitching failed: {e}")
            return False
    
    @staticmethod
    def convert_video(input_path: str, output_path: str, fps: int = 24, 
                     codec: str = "libx264", preset: str = "medium") -> bool:
        """Convert video with ffmpeg"""
        try:
            cmd = [
                "ffmpeg",
                "-i", input_path,
                "-r", str(fps),
                "-c:v", codec,
                "-preset", preset,
                "-c:a", "aac",
                "-y",
                output_path
            ]
            
            subprocess.run(cmd, check=True)
            logger.info(f"Video converted: {output_path}")
            return True
        except Exception as e:
            logger.error(f"Video conversion failed: {e}")
            return False
    
    @staticmethod
    def upscale_video(input_path: str, output_path: str, scale_factor: int = 2) -> bool:
        """Upscale video resolution"""
        try:
            width = f"iw*{scale_factor}"
            height = f"ih*{scale_factor}"
            
            cmd = [
                "ffmpeg",
                "-i", input_path,
                "-vf", f"scale={width}:{height}",
                "-c:v", "libx264",
                "-preset", "slow",
                "-crf", "18",
                "-y",
                output_path
            ]
            
            subprocess.run(cmd, check=True)
            logger.info(f"Video upscaled: {output_path}")
            return True
        except Exception as e:
            logger.error(f"Video upscaling failed: {e}")
            return False
    
    @staticmethod
    def concat_videos(video_files: List[str], output_path: str) -> bool:
        """Concatenate multiple videos"""
        try:
            concat_file = "concat_list.txt"
            with open(concat_file, "w") as f:
                for video in video_files:
                    f.write(f"file '{os.path.abspath(video)}'\n")
            
            cmd = [
                "ffmpeg",
                "-f", "concat",
                "-safe", "0",
                "-i", concat_file,
                "-c", "copy",
                "-y",
                output_path
            ]
            
            subprocess.run(cmd, check=True)
            os.remove(concat_file)
            logger.info(f"Videos concatenated: {output_path}")
            return True
        except Exception as e:
            logger.error(f"Video concatenation failed: {e}")
            return False

if __name__ == "__main__":
    # Example usage
    processor = VideoProcessor()
    info = processor.get_video_info("input.mp4")
    print(f"Video info: {info}")
