# OneOffRender Setup Guide

## Automatic Setup (Recommended)

### For First-Time Users

1. **Download OneOffRender** to your desired folder
2. **Run `RunMe.bat`** - This handles everything automatically:
   - ✅ Creates Python virtual environment
   - ✅ Installs all Python dependencies from requirements.txt
   - ✅ **Downloads FFmpeg/ffprobe automatically** (if not found)
   - ✅ Verifies all components are working
   - ✅ Launches the shader renderer

### What Happens During First Run

```
OneOffRender - Shader Video Generator
========================================

✓ Python found and working
✓ Virtual environment created
✓ Python dependencies installed
✓ Checking for FFmpeg/ffprobe...

[If FFmpeg not found:]
  → Downloads FFmpeg for Windows (~100MB)
  → Extracts to local ffmpeg/ folder
  → Adds to PATH for the session
  → Verifies installation

✓ FFmpeg/ffprobe verification successful!
✓ All components ready!
```

## Manual Verification

### Test Your Installation
```bash
python test_setup.py
```

This comprehensive test checks:
- ✅ All Python packages (numpy, librosa, moderngl, etc.)
- ✅ FFmpeg and ffprobe availability
- ✅ Directory structure
- ✅ Configuration files
- ✅ Shader collection (23 working shaders)

### Quick FFmpeg Check
```bash
python verify_ffmpeg.py
```

## Troubleshooting

### FFmpeg Issues

**Problem**: "FFmpeg/ffprobe not found"
**Solution**: 
1. Run `RunMe.bat` - it will download FFmpeg automatically
2. If download fails, check your internet connection
3. Manual install: Download FFmpeg from https://ffmpeg.org/

**Problem**: "Failed to download FFmpeg"
**Solutions**:
1. Check internet connection
2. Try running as Administrator
3. Manual download and extract to `ffmpeg/` folder

### Python Issues

**Problem**: "Python is not installed or not in PATH"
**Solution**: Install Python 3.7+ from https://python.org/

**Problem**: "Failed to create virtual environment"
**Solutions**:
1. Run as Administrator
2. Check disk space
3. Ensure Python has venv module: `python -m pip install --upgrade pip`

### Permission Issues

**Problem**: Access denied errors
**Solution**: Run `RunMe.bat` as Administrator

## Directory Structure After Setup

```
OneOffRender/
├── ffmpeg/                    # Auto-downloaded FFmpeg (if needed)
│   └── bin/
│       ├── ffmpeg.exe
│       └── ffprobe.exe
├── venv/                      # Python virtual environment
├── Input_Audio/               # Your audio files
├── Output_Video/              # Generated videos
├── Shaders/                   # 23 working shaders
├── Transitions/               # 100+ transition effects
├── RunMe.bat                  # Main setup script
├── test_setup.py              # Comprehensive test
├── verify_ffmpeg.py           # FFmpeg verification
└── requirements.txt           # Python dependencies
```

## Advanced Setup

### Custom FFmpeg Location

If you have FFmpeg installed elsewhere, ensure it's in your system PATH:
```cmd
ffmpeg -version
ffprobe -version
```

### Development Setup

For developers who want to modify the code:
```bash
# Activate virtual environment
venv\Scripts\activate.bat

# Install in development mode
pip install -e .

# Run tests
python test_setup.py
```

## Performance Notes

- **First run**: Takes 2-5 minutes (downloads FFmpeg)
- **Subsequent runs**: Starts immediately
- **FFmpeg size**: ~100MB download (one-time)
- **Total disk usage**: ~500MB after full setup

## Support

If you encounter issues:
1. Run `python test_setup.py` to diagnose problems
2. Check the console output for specific error messages
3. Ensure you have admin rights if needed
4. Verify internet connection for first-time setup

The setup is designed to be completely automatic and user-friendly!
