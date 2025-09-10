# OneOffRender - Advanced Audio-Reactive Video Generator

A sophisticated command-line application that creates stunning audio-reactive videos using GLSL shaders, featuring intelligent multi-shader cycling, priority-based transition selection, and high-performance rendering.

## Features

### 🎬 **Advanced Multi-Shader System**
- **Dynamic Shader Cycling**: Automatically switches between multiple shaders during rendering
- **Intelligent Randomization**: Weighted selection ensuring fair distribution across all shaders
- **Smart History Avoidance**: Prevents repetition of recently used shaders
- **Seamless Transitions**: Smooth blending between shader segments with 100+ transition effects

### 🎯 **Priority-Based Transition Selection**
- **Quality-First Algorithm**: Uses preference + status scoring to prioritize best transitions
- **Intelligent Progression**: Exhausts high-quality transitions before using lower-tier ones
- **Broken Transition Avoidance**: Automatically excludes non-functional transitions
- **Metadata-Driven**: Centralized transition configuration with quality tracking

### 🎵 **Advanced Audio Processing**
- **Real-Time Audio Analysis**: Bass and treble frequency extraction with STFT
- **Audio-Reactive Visuals**: Shaders respond dynamically to music frequencies
- **Batch Processing**: Automatically processes multiple audio files
- **Format Support**: MP3, WAV, FLAC, M4A, AAC, OGG, WMA

### ⚡ **High-Performance Rendering**
- **Fast Streaming Mode**: Raw video processing for 3-5x performance improvement
- **Memory Optimized**: Minimal temporary file usage
- **GPU Accelerated**: OpenGL 3.3+ with ModernGL for maximum performance
- **Production Quality**: H.264/AAC encoding with configurable quality settings

## Quick Start

1. **Run the application**:
   ```bash
   RunMe.bat
   ```

2. **What happens automatically**:
   - Sets up Python virtual environment and dependencies
   - **Downloads and sets up FFmpeg/ffprobe automatically** (first-time only)
   - Verifies all components are working
   - Discovers all audio files in `Input_Audio/` folder
   - Discovers all shaders in `Shaders/` folder (19 working shaders included)
   - Analyzes audio for bass/treble frequency data with 1024-point FFT
   - Renders videos with dynamic shader cycling and intelligent transitions
   - Outputs high-quality H.264/AAC videos to `Output_Video/`

3. **Check your results**:
   - Videos appear in `Output_Video/` with names matching your audio files
   - Each video features multiple shaders with smooth transitions
   - Full audio length rendered with synchronized visuals

**Performance**: Fast streaming mode delivers optimal rendering speed with minimal memory usage.

### Manual Verification
If you want to verify your installation:
```bash
python verify_ffmpeg.py
```

## Directory Structure

```
OneOffRender/
├── Input_Audio/           # Place your audio files here (auto-discovered)
│   └── Molten Heart Music.mp3
├── Output_Video/          # Generated videos appear here
│   └── molten_heart_music.mp4
├── Shaders/              # GLSL shader files (19 working shaders included)
│   ├── MoltenHeart.glsl
│   ├── Celestial Cells.glsl
│   ├── Cellular Aurora Storm.glsl
│   ├── Ethereal Tides.glsl
│   ├── Chromatic Tide 3.glsl
│   ├── Cosmic Nebula2.glsl
│   ├── Luminous Nebulae.glsl
│   ├── Petal Drift.glsl
│   ├── sleeplessV3.glsl
│   ├── Colorful Columns.glsl
│   ├── Bubble Colors.glsl
│   ├── Xor Mashup 002.glsl
│   ├── gyroid art.glsl
│   └── ... (more shaders)
├── Transitions/          # Transition effects (100+ transitions)
│   ├── Fade.glsl
│   ├── Circle.glsl
│   ├── Transitions_Metadata.json  # Transition quality ratings
│   └── ... (100+ transition files)
├── config.json           # Main configuration file
├── render_shader.py      # Main application script
├── oneoff.py             # Single shader renderer
├── RunMe.bat            # One-click launcher
└── README.md            # This file
```

## Configuration (config.json)

### Multi-Shader System
```json
"shader_settings": {
  "multi_shader": true,           # Enable dynamic shader cycling
  "switch_interval": 10.0,        # Seconds between shader switches
  "randomization": {
    "algorithm": "weighted",      # Smart distribution algorithm
    "history_size": 3,           # Avoid recent shader repeats
    "distribution_weight": 2.0   # Favor less-used shaders
  }
}
```

### Transition System
```json
"transitions": {
  "enabled": true,                # Enable smooth transitions
  "duration": 1.6,               # Transition duration in seconds
  "folder": "Transitions",       # 100+ transition effects
  "config_file": "Transitions/Transitions_Metadata.json",
  "randomization": {
    "algorithm": "weighted",     # Priority-based selection
    "history_size": 2,          # Avoid recent transitions
    "distribution_weight": 1.5  # Quality-weighted selection
  }
}
```

### Batch Processing
```json
"batch_settings": {
  "enabled": true,              # Process all audio files automatically
  "overwrite_existing": false   # Skip existing output videos
}
```

### Output Settings
```json
"output": {
  "resolution": {
    "width": 1920,              # Full HD rendering
    "height": 1080
  },
  "frame_rate": 30
}
```

### Duration Control
```json
"duration_override": {
  "enabled": false,           # Render full audio length
  "cutoff_time": "01:30"     # Or limit to specific time (MM:SS)
}
```

### Quality Settings
```json
"rendering": {
  "streaming": true,          # Fast streaming mode (recommended)
  "quality": {
    "crf": 18,               # Video quality (0-51, lower = better)
    "preset": "medium"       # Encoding speed vs quality
  }
}
```

## Priority-Based Transition System

The application features an advanced transition selection system that prioritizes quality:

### Scoring Algorithm
```
Score = Preference Level + Working Status

Preference Levels:          Working Status:
- Highly Desired: 1 point   - Fully Working: 1 point
- Mid: 2 points            - Minor Adjustments: 2 points
- Low: 3 points            - Broken: 3 points (excluded)
```

### Quality Tiers
- **Score 2** (15 transitions): Highly Desired + Fully Working - **Used First**
- **Score 3** (21 transitions): Mixed high-quality combinations
- **Score 4** (20 transitions): Medium-quality transitions
- **Score 5** (38 transitions): Lower-priority transitions
- **Score 6** (0 transitions): Broken transitions - **Never Used**

### Selection Behavior
1. **Exhaust Score 2 transitions** with random, non-repeating selection
2. **Progress to Score 3** only when all Score 2 transitions used equally
3. **Continue through Score 4 and 5** as needed
4. **Reset to Score 2** for new music files

## Multi-Shader System

The application automatically discovers and cycles through multiple shaders:

### Included Shaders (19 Working)
- **MoltenHeart.glsl** - Flowing organic patterns
- **Celestial Cells.glsl** - Cosmic cellular structures
- **Cellular Aurora Storm.glsl** - Aurora-like veils with cellular wavelet patterns and curl-driven motion
- **Ethereal Tides.glsl** - Flowing wave patterns
- **Chromatic Tide 3.glsl** - Radial tides with chromatic interference patterns
- **Cosmic Nebula2.glsl** - Deep space gas clouds with stellar formation
- **Luminous Nebulae.glsl** - Audio-reactive nebulae with dynamic color palettes
- **Petal Drift.glsl** - Drifting Gaussian petals with gentle lighting
- **sleeplessV3.glsl** - Audio-reactive orb effects with optimized GPU-compatible rendering
- **Colorful Columns.glsl** - Audio-reactive 3D columns with frequency-based height and vibrant colors
- **Bubble Colors.glsl** - Compact audio-reactive bubble effects with gentle pulsing and color shifts
- **Xor Mashup 002.glsl** - Complex raymarched fractal with sophisticated audio reactivity and spiral backgrounds
- **gyroid art.glsl** - Raymarched gyroid with intelligent camera traversing tubes, exiting, and looping back
- **Flowing Mathematical Patterns2.glsl** - Mathematical visualizations
- **Harmonic Fractal Storm.glsl** - Complex fractal animations
- **Iridescent Breathing Orbs.glsl** - Pulsing sphere effects
- **SDF Bloom Tapestry.glsl** - Geometric bloom effects
- **Silk Flow.glsl** - Smooth flowing textures
- **Trippy Audio Hippy.glsl** - Psychedelic audio-reactive patterns

### Smart Randomization
- **Weighted Selection**: Ensures all shaders get fair representation
- **History Avoidance**: Prevents repeating recently used shaders
- **Usage Tracking**: Balances shader usage across the video
- **Seamless Switching**: Pre-compiled shaders for instant transitions

### Transition Effects (100+)
The system includes over 100 transition effects:
- **Fade transitions**: Various fade patterns and speeds
- **Geometric transitions**: Circles, squares, polygons
- **Distortion effects**: Ripples, warps, morphs
- **Creative effects**: Film burns, kaleidoscopes, swirls
- **Quality-rated**: Each transition rated for preference and functionality

## Audio-Reactive System

### High-Resolution Audio Analysis
- **1024-Point FFT**: Shadertoy-compatible frequency analysis with 512 usable bins
- **Real-Time Processing**: 60fps-capable audio analysis with 0.8 smoothing factor
- **Full Spectrum**: Complete frequency range from 0Hz to Nyquist frequency
- **Magnitude Spectrum**: Normalized floating-point values [0.0 - 1.0]
- **Frequency Resolution**: Sample rate / 1024 Hz per bin (e.g., 43Hz per bin at 44.1kHz)

### Audio Texture Format
Shaders receive high-resolution audio data via a 512x256 texture:
```glsl
uniform sampler2D iChannel0; // High-resolution audio texture (512x256)
uniform float iTime;         // Current time
uniform vec2 iResolution;    // Screen resolution

// Row 0 (Y=0.0): Full 512-bin FFT spectrum (Shadertoy-compatible)
// Get specific frequency bin (0-511)
float freq_bin_100 = texture(iChannel0, vec2(100.5/512.0, 0.0)).r;

// Get normalized frequency (0.0 = 0Hz, 1.0 = Nyquist)
float mid_freq = texture(iChannel0, vec2(0.5, 0.0)).r;

// Legacy compatibility - bass and treble ranges
float bass = texture(iChannel0, vec2(0.1, 0.0)).r;    // Low frequencies
float treble = texture(iChannel0, vec2(0.9, 0.0)).r;  // High frequencies

// Rows 2-255: High-resolution waveform data (512 samples wide)
float waveform = texture(iChannel0, vec2(x_coord, y_coord)).r;
```

### Advanced Audio Functions
```glsl
// Get frequency range average
float getFrequencyRange(float start_freq, float end_freq) {
    float sum = 0.0;
    int samples = 16;
    for (int i = 0; i < samples; i++) {
        float freq = mix(start_freq, end_freq, float(i) / float(samples - 1));
        sum += texture(iChannel0, vec2(freq, 0.0)).r;
    }
    return sum / float(samples);
}

// Specific frequency bands (at 44.1kHz sample rate)
float sub_bass = getFrequencyRange(0.0, 0.05);      // 0-1kHz
float bass = getFrequencyRange(0.05, 0.15);         // 1-3kHz
float mids = getFrequencyRange(0.15, 0.5);          // 3-11kHz
float treble = getFrequencyRange(0.5, 1.0);         // 11-22kHz
```

### Shader Compatibility
- **OpenGL 3.3+**: Modern OpenGL with ModernGL
- **Fragment Shaders**: Standard GLSL fragment shader format
- **Automatic Discovery**: Place .glsl files in Shaders/ folder
- **Pre-compilation**: All shaders compiled at startup for performance

## Usage

### Automatic Multi-Shader Operation
The system is designed for minimal user intervention:

1. **Add Audio Files**: Place any audio files in `Input_Audio/` folder
2. **Run Application**: Execute `RunMe.bat`
3. **Get Results**: Videos appear in `Output_Video/` with matching names

### Single Shader Rendering (oneoff.py)
For testing individual shaders or creating focused content:

```bash
python oneoff.py <shader_name> <duration>
```

**Parameters:**
- `shader_name`: Name of shader file (with or without .glsl extension)
- `duration`: Duration in seconds (30) or MM:SS format (01:30)

**Examples:**
```bash
python oneoff.py sleeplessV3.glsl 30
python oneoff.py "Cosmic Nebula2.glsl" 01:30
python oneoff.py MoltenHeart 45
```

**Features:**
- Uses first audio file found in `Input_Audio/`
- Respects all config.json settings (resolution, quality, etc.)
- Disables transitions and multi-shader cycling
- Output named as `{shader_name}_{duration}s.mp4`
- Full audio reactivity and frequency analysis
- Comprehensive error handling and validation

### Supported Audio Formats
- MP3, WAV, FLAC, M4A, AAC, OGG, WMA
- Automatic format detection and processing
- Full-length audio rendering (or custom duration limits)

### Adding Custom Shaders
1. Place `.glsl` files in `Shaders/` folder
2. Shaders automatically discovered and included in rotation
3. Must follow standard fragment shader format with audio texture support

### Adding Custom Transitions
1. Place transition `.glsl` files in `Transitions/` folder
2. Add metadata entry to `Transitions/Transitions_Metadata.json`:
   ```json
   "YourTransition.glsl": {
     "preference": "Highly Desired",
     "status": "Fully Working"
   }
   ```

### Performance Tuning
For faster rendering or testing:
```json
"duration_override": {
  "enabled": true,
  "cutoff_time": "00:30"  # 30-second test render
},
"output": {
  "resolution": {
    "width": 1280,        # Lower resolution for speed
    "height": 720
  }
}
```

## System Requirements

### Prerequisites
- **Python 3.7+**: Must be installed and in PATH
- **Internet connection**: For first-time FFmpeg download (one-time setup)
- **OpenGL 3.3+**: For GPU-accelerated shader rendering
- **Windows**: Tested on Windows 10/11 (primary support)
- **4GB+ RAM**: Recommended for smooth rendering

### Automatic Dependencies
RunMe.bat handles these automatically:
- **FFmpeg/ffprobe**: Downloaded and configured automatically
- **Python packages**: All requirements.txt dependencies installed
- **Virtual environment**: Created and managed automatically

### Performance
- **Fast Streaming Mode**: 3-5x faster than traditional frame-by-frame rendering
- **Memory Efficient**: Minimal temporary file usage
- **GPU Accelerated**: Utilizes graphics card for shader processing
- **Batch Processing**: Handles multiple audio files automatically

### Troubleshooting

**Setup Issues**:
- Run `RunMe.bat` as Administrator if permission errors occur
- Ensure antivirus isn't blocking Python installation
- Check that Input_Audio folder contains supported audio files

**Rendering Issues**:
- Verify graphics drivers are up to date for OpenGL support
- Check console output for specific error messages
- Try lower resolution settings if performance is poor

**Quality Issues**:
- Increase CRF value (18-23) for smaller file sizes
- Decrease CRF value (15-18) for higher quality
- Adjust resolution based on your needs and performance

## Technical Architecture

### Core Technologies
- **Rendering Engine**: ModernGL (OpenGL 3.3+) for GPU-accelerated shader processing
- **Audio Analysis**: librosa with 1024-point FFT for high-resolution frequency extraction
- **Video Encoding**: FFmpeg with H.264/AAC for production-quality output
- **Shader Management**: Runtime discovery, pre-compilation, and seamless switching
- **FFT Processing**: Shadertoy-compatible 512-bin magnitude spectrum with 0.8 smoothing

### Performance Features
- **Fast Streaming Mode**: Raw video data processing (3-5x faster than frame-by-frame)
- **High-Resolution FFT**: 1024-point FFT processing at 60fps with real-time smoothing
- **Memory Optimization**: Minimal temporary file usage with efficient spectrum caching
- **GPU Acceleration**: Hardware-accelerated shader rendering with 512x256 audio textures
- **Batch Processing**: Automatic multi-file processing with progress tracking

### Quality Assurance
- **Priority-Based Selection**: Quality-first transition and shader selection
- **Comprehensive Error Handling**: Robust error recovery and user feedback
- **Production Testing**: Verified with multiple audio formats and shader types
- **Automatic Validation**: Built-in system verification and dependency checking

---

## License

This is a standalone application derived from the DISCO GLSL Video Processor project.
