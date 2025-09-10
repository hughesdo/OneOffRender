#!/usr/bin/env python3
"""
Setup Test Script
Tests that all components are properly installed and working.
"""

import subprocess
import sys
import os
from pathlib import Path

def test_python_packages():
    """Test that all required Python packages are installed."""
    print("Testing Python packages...")
    
    required_packages = [
        'numpy',
        'PIL',  # Pillow
        'moderngl',
        'librosa',
        'ffmpeg',  # ffmpeg-python
        'scipy'
    ]
    
    missing_packages = []
    
    for package in required_packages:
        try:
            __import__(package)
            print(f"  ✓ {package}")
        except ImportError:
            print(f"  ✗ {package} - MISSING")
            missing_packages.append(package)
    
    return len(missing_packages) == 0

def test_ffmpeg():
    """Test FFmpeg and ffprobe."""
    print("\nTesting FFmpeg...")
    
    commands = ['ffmpeg', 'ffprobe']
    all_ok = True
    
    for cmd in commands:
        try:
            result = subprocess.run([cmd, '-version'], 
                                  capture_output=True, 
                                  text=True, 
                                  timeout=5)
            if result.returncode == 0:
                version = result.stdout.split('\n')[0]
                print(f"  ✓ {cmd}: {version}")
            else:
                print(f"  ✗ {cmd}: Failed")
                all_ok = False
        except Exception as e:
            print(f"  ✗ {cmd}: {e}")
            all_ok = False
    
    return all_ok

def test_directories():
    """Test that required directories exist."""
    print("\nTesting directory structure...")
    
    required_dirs = [
        'Input_Audio',
        'Output_Video', 
        'Shaders',
        'Transitions'
    ]
    
    all_ok = True
    
    for dir_name in required_dirs:
        dir_path = Path(dir_name)
        if dir_path.exists():
            print(f"  ✓ {dir_name}/")
        else:
            print(f"  ✗ {dir_name}/ - MISSING")
            all_ok = False
    
    return all_ok

def test_config_files():
    """Test that required config files exist."""
    print("\nTesting configuration files...")
    
    required_files = [
        'config.json',
        'requirements.txt',
        'render_shader.py',
        'oneoff.py'
    ]
    
    all_ok = True
    
    for file_name in required_files:
        file_path = Path(file_name)
        if file_path.exists():
            print(f"  ✓ {file_name}")
        else:
            print(f"  ✗ {file_name} - MISSING")
            all_ok = False
    
    return all_ok

def count_shaders():
    """Count available shaders."""
    print("\nCounting shaders...")
    
    shaders_dir = Path("Shaders")
    if not shaders_dir.exists():
        print("  ✗ Shaders directory not found")
        return False
    
    shader_files = list(shaders_dir.glob("*.glsl"))
    working_shaders = [s for s in shader_files if not s.name.endswith('.disable')]
    
    print(f"  ✓ Total shader files: {len(shader_files)}")
    print(f"  ✓ Working shaders: {len(working_shaders)}")
    
    return len(working_shaders) > 0

def main():
    print("OneOffRender Setup Test")
    print("=" * 50)
    
    tests = [
        ("Python Packages", test_python_packages),
        ("FFmpeg Components", test_ffmpeg),
        ("Directory Structure", test_directories),
        ("Configuration Files", test_config_files),
        ("Shader Collection", count_shaders)
    ]
    
    results = []
    
    for test_name, test_func in tests:
        try:
            result = test_func()
            results.append((test_name, result))
        except Exception as e:
            print(f"  ✗ {test_name}: Error - {e}")
            results.append((test_name, False))
    
    print("\n" + "=" * 50)
    print("SUMMARY:")
    
    all_passed = True
    for test_name, passed in results:
        status = "PASS" if passed else "FAIL"
        symbol = "✓" if passed else "✗"
        print(f"  {symbol} {test_name}: {status}")
        if not passed:
            all_passed = False
    
    print("\n" + "=" * 50)
    if all_passed:
        print("🎉 ALL TESTS PASSED!")
        print("OneOffRender is ready to use!")
        return 0
    else:
        print("❌ SOME TESTS FAILED")
        print("Please run RunMe.bat to set up missing components.")
        return 1

if __name__ == "__main__":
    sys.exit(main())
