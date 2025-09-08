#!/usr/bin/env python3
"""
Verify OneOffRender installation and dependencies.
Run this script to check if everything is set up correctly.
"""

import json
import sys
from pathlib import Path

def check_files():
    """Check if all required files exist."""
    print("=== File Structure Check ===")
    
    required_files = [
        "config.json",
        "render_shader.py", 
        "requirements.txt",
        "README.md",
        "RunMe.bat",
        "Shaders/MoltenHeart.glsl",
        "Input_Audio/Molten Heart Music.mp3"
    ]
    
    all_good = True
    for file_path in required_files:
        path = Path(file_path)
        if path.exists():
            print(f"✓ {file_path}")
        else:
            print(f"✗ {file_path} (MISSING)")
            all_good = False
            
    return all_good

def check_config():
    """Check configuration file."""
    print("\n=== Configuration Check ===")
    
    try:
        with open('config.json', 'r') as f:
            config = json.load(f)
            
        # Validate structure
        required_keys = ['input', 'output', 'duration_override', 'rendering', 'debug']
        for key in required_keys:
            if key in config:
                print(f"✓ {key} section")
            else:
                print(f"✗ {key} section (MISSING)")
                return False
                
        # Check paths
        shader_path = Path(config['input']['shader_file'])
        audio_path = Path(config['input']['audio_file'])
        
        if shader_path.exists():
            print(f"✓ Shader file: {shader_path}")
        else:
            print(f"✗ Shader file: {shader_path} (NOT FOUND)")
            return False
            
        if audio_path.exists():
            print(f"✓ Audio file: {audio_path}")
        else:
            print(f"✗ Audio file: {audio_path} (NOT FOUND)")
            return False
            
        return True
        
    except Exception as e:
        print(f"✗ Config error: {e}")
        return False

def check_dependencies():
    """Check Python dependencies."""
    print("\n=== Dependencies Check ===")
    
    dependencies = [
        ('numpy', 'numpy'),
        ('Pillow', 'PIL'),
        ('moderngl', 'moderngl'),
        ('librosa', 'librosa'),
        ('ffmpeg-python', 'ffmpeg'),
        ('scipy', 'scipy')
    ]
    
    all_good = True
    for package_name, import_name in dependencies:
        try:
            __import__(import_name)
            print(f"✓ {package_name}")
        except ImportError:
            print(f"✗ {package_name} (NOT INSTALLED)")
            all_good = False
            
    return all_good

def check_system():
    """Check system requirements."""
    print("\n=== System Check ===")
    
    print(f"✓ Python version: {sys.version.split()[0]}")
    
    # Check if FFmpeg is available
    import subprocess
    try:
        result = subprocess.run(['ffmpeg', '-version'], 
                              capture_output=True, text=True, timeout=5)
        if result.returncode == 0:
            version_line = result.stdout.split('\n')[0]
            print(f"✓ FFmpeg: {version_line}")
        else:
            print("✗ FFmpeg: Not working properly")
            return False
    except (subprocess.TimeoutExpired, FileNotFoundError):
        print("✗ FFmpeg: Not found in PATH")
        return False
        
    return True

def main():
    """Main verification function."""
    print("OneOffRender Installation Verification")
    print("=" * 40)
    
    files_ok = check_files()
    config_ok = check_config()
    deps_ok = check_dependencies()
    system_ok = check_system()
    
    print("\n" + "=" * 40)
    
    if files_ok and config_ok and deps_ok and system_ok:
        print("✅ All checks passed! OneOffRender is ready to use.")
        print("\nTo render a video:")
        print("  1. Run: RunMe.bat")
        print("  2. Or: python render_shader.py")
        print("\nFor custom settings:")
        print("  1. Edit config.json")
        print("  2. Run: python render_shader.py config.json")
        return True
    else:
        print("❌ Some issues found. Please fix the above errors.")
        if not deps_ok:
            print("\nTo install missing dependencies:")
            print("  pip install -r requirements.txt")
        return False

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
