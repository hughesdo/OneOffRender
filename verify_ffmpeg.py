#!/usr/bin/env python3
"""
FFmpeg/ffprobe Verification Script
Verifies that FFmpeg and ffprobe are properly installed and accessible.
"""

import subprocess
import sys
import os
from pathlib import Path

def check_command(command, description):
    """Check if a command is available and working."""
    try:
        result = subprocess.run([command, '-version'], 
                              capture_output=True, 
                              text=True, 
                              timeout=10)
        if result.returncode == 0:
            # Extract version info from first line
            version_line = result.stdout.split('\n')[0]
            print(f"✓ {description}: {version_line}")
            return True
        else:
            print(f"✗ {description}: Command failed (return code {result.returncode})")
            return False
    except subprocess.TimeoutExpired:
        print(f"✗ {description}: Command timed out")
        return False
    except FileNotFoundError:
        print(f"✗ {description}: Command not found")
        return False
    except Exception as e:
        print(f"✗ {description}: Error - {e}")
        return False

def check_local_ffmpeg():
    """Check if local FFmpeg installation exists."""
    local_ffmpeg = Path("ffmpeg/bin/ffmpeg.exe")
    local_ffprobe = Path("ffmpeg/bin/ffprobe.exe")
    
    if local_ffmpeg.exists() and local_ffprobe.exists():
        print(f"✓ Local FFmpeg found: {local_ffmpeg.absolute()}")
        print(f"✓ Local ffprobe found: {local_ffprobe.absolute()}")
        return True
    else:
        print("✗ Local FFmpeg installation not found")
        return False

def main():
    print("FFmpeg/ffprobe Verification")
    print("=" * 40)
    
    # Check system PATH first
    ffmpeg_ok = check_command('ffmpeg', 'FFmpeg (system)')
    ffprobe_ok = check_command('ffprobe', 'ffprobe (system)')
    
    if not (ffmpeg_ok and ffprobe_ok):
        print("\nSystem FFmpeg not found, checking local installation...")
        local_ok = check_local_ffmpeg()
        
        if local_ok:
            # Add local FFmpeg to PATH and test again
            local_bin = str(Path("ffmpeg/bin").absolute())
            os.environ['PATH'] = local_bin + os.pathsep + os.environ['PATH']
            
            print("\nTesting local FFmpeg after adding to PATH...")
            ffmpeg_ok = check_command('ffmpeg', 'FFmpeg (local)')
            ffprobe_ok = check_command('ffprobe', 'ffprobe (local)')
    
    print("\n" + "=" * 40)
    if ffmpeg_ok and ffprobe_ok:
        print("✓ All FFmpeg components are working correctly!")
        print("✓ OneOffRender should work properly.")
        return 0
    else:
        print("✗ FFmpeg installation is incomplete or not working.")
        print("✗ Please run RunMe.bat to set up dependencies.")
        return 1

if __name__ == "__main__":
    sys.exit(main())
