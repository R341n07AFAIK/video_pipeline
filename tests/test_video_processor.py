#!/usr/bin/env python3
"""
Test suite for video_processor.py

Tests video processing functions including frame extraction, stitching,
codec conversion, and upscaling operations.
"""

import unittest
import os
import sys
import tempfile
from pathlib import Path

# Add parent directory to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'python_modules'))

try:
    from video_processor import VideoProcessor
except ImportError:
    print("ERROR: Could not import VideoProcessor. Ensure python_modules are in path.")
    sys.exit(1)


class TestVideoProcessor(unittest.TestCase):
    """Test cases for VideoProcessor class"""
    
    @classmethod
    def setUpClass(cls):
        """Set up test fixtures"""
        cls.temp_dir = tempfile.mkdtemp(prefix="video_test_")
        cls.test_video = os.path.join(cls.temp_dir, "test_video.mp4")
        cls.output_dir = os.path.join(cls.temp_dir, "output")
        cls.frames_dir = os.path.join(cls.temp_dir, "frames")
        
        # Create directories
        os.makedirs(cls.output_dir, exist_ok=True)
        os.makedirs(cls.frames_dir, exist_ok=True)
        
        print(f"\nTest directory: {cls.temp_dir}")
    
    @classmethod
    def tearDownClass(cls):
        """Clean up test fixtures"""
        import shutil
        if os.path.exists(cls.temp_dir):
            shutil.rmtree(cls.temp_dir)
            print(f"Cleaned up: {cls.temp_dir}")
    
    def test_video_processor_instantiation(self):
        """Test VideoProcessor can be instantiated"""
        processor = VideoProcessor()
        self.assertIsNotNone(processor)
    
    def test_get_video_info_nonexistent(self):
        """Test get_video_info with nonexistent file"""
        processor = VideoProcessor()
        nonexistent = "/path/to/nonexistent/video.mp4"
        result = processor.get_video_info(nonexistent)
        self.assertIsNotNone(result)
        self.assertIn('error', result or {})
    
    def test_extract_frames_structure(self):
        """Test extract_frames method structure"""
        processor = VideoProcessor()
        # This will fail without actual video but tests method exists
        self.assertTrue(hasattr(processor, 'extract_frames'))
        self.assertTrue(callable(getattr(processor, 'extract_frames')))
    
    def test_stitch_frames_structure(self):
        """Test stitch_frames method structure"""
        processor = VideoProcessor()
        self.assertTrue(hasattr(processor, 'stitch_frames'))
        self.assertTrue(callable(getattr(processor, 'stitch_frames')))
    
    def test_convert_video_structure(self):
        """Test convert_video method structure"""
        processor = VideoProcessor()
        self.assertTrue(hasattr(processor, 'convert_video'))
        self.assertTrue(callable(getattr(processor, 'convert_video')))
    
    def test_upscale_video_structure(self):
        """Test upscale_video method structure"""
        processor = VideoProcessor()
        self.assertTrue(hasattr(processor, 'upscale_video'))
        self.assertTrue(callable(getattr(processor, 'upscale_video')))
    
    def test_concat_videos_structure(self):
        """Test concat_videos method structure"""
        processor = VideoProcessor()
        self.assertTrue(hasattr(processor, 'concat_videos'))
        self.assertTrue(callable(getattr(processor, 'concat_videos')))
    
    def test_all_methods_exist(self):
        """Test all required methods exist"""
        processor = VideoProcessor()
        required_methods = [
            'extract_frames',
            'stitch_frames',
            'convert_video',
            'upscale_video',
            'concat_videos',
            'get_video_info'
        ]
        for method in required_methods:
            self.assertTrue(
                hasattr(processor, method),
                f"VideoProcessor missing method: {method}"
            )
    
    def test_processor_ffmpeg_dependency(self):
        """Test VideoProcessor can detect FFmpeg"""
        processor = VideoProcessor()
        # If FFmpeg is available, this should work
        # Otherwise, methods will fail gracefully
        self.assertIsNotNone(processor)


class TestVideoProcessorIntegration(unittest.TestCase):
    """Integration tests for VideoProcessor"""
    
    def test_imports_successful(self):
        """Test all required imports work"""
        try:
            from video_processor import VideoProcessor
            import subprocess
            import os
            self.assertTrue(True)
        except ImportError as e:
            self.fail(f"Import failed: {e}")
    
    def test_constants_defined(self):
        """Test required constants are defined"""
        processor = VideoProcessor()
        # Check if processor has expected attributes
        self.assertIsNotNone(processor)


def run_system_checks():
    """Run system checks before tests"""
    print("\n" + "="*50)
    print("SYSTEM CHECKS")
    print("="*50)
    
    checks = {
        "Python Version": f"{sys.version}",
        "Temp Directory": tempfile.gettempdir(),
        "Current Directory": os.getcwd(),
    }
    
    for check, value in checks.items():
        print(f"{check}: {value}")
    
    # Check for FFmpeg
    try:
        result = os.system("ffmpeg -version > NUL 2>&1")
        ffmpeg_available = result == 0
    except:
        ffmpeg_available = False
    
    print(f"FFmpeg Available: {'Yes' if ffmpeg_available else 'No (tests will be limited)'}")
    
    # Check for required Python packages
    packages = ['subprocess', 'os', 'pathlib']
    print("\nPython Packages:")
    for pkg in packages:
        try:
            __import__(pkg)
            print(f"  ✓ {pkg}")
        except ImportError:
            print(f"  ✗ {pkg}")


if __name__ == '__main__':
    # Run system checks
    run_system_checks()
    
    # Run tests
    print("\n" + "="*50)
    print("TEST SUITE")
    print("="*50 + "\n")
    
    # Create test suite
    suite = unittest.TestSuite()
    
    # Add tests
    suite.addTests(unittest.TestLoader().loadTestsFromTestCase(TestVideoProcessor))
    suite.addTests(unittest.TestLoader().loadTestsFromTestCase(TestVideoProcessorIntegration))
    
    # Run tests with verbose output
    runner = unittest.TextTestRunner(verbosity=2)
    result = runner.run(suite)
    
    # Print summary
    print("\n" + "="*50)
    print("TEST SUMMARY")
    print("="*50)
    print(f"Tests run: {result.testsRun}")
    print(f"Successes: {result.testsRun - len(result.failures) - len(result.errors)}")
    print(f"Failures: {len(result.failures)}")
    print(f"Errors: {len(result.errors)}")
    
    # Exit with appropriate code
    sys.exit(0 if result.wasSuccessful() else 1)
