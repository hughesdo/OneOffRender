# OneOffRender - Advanced Audio-Reactive Video Generator

A sophisticated video creation system that creates stunning audio-reactive videos using GLSL shaders. Choose from three powerful workflows:

- **🎨 Web Editor** (RECOMMENDED): Professional browser-based timeline editor with drag-and-drop interface
- **🔧 OneOff Renderer**: Quick command-line tool for testing individual shaders
- **⚡ Batch Processor**: Automated rendering with random shader cycling


Here’s a demo video showing how it works:

[![Video Demo](https://img.youtube.com/vi/5goL8kGSU3M/0.jpg)](https://youtu.be/5goL8kGSU3M)

Watch the video on YouTube: [OneOffRender for recording audio reactive shaders](https://youtu.be/5goL8kGSU3M)


---

## 📦 Installation & Setup

### Prerequisites
Before you begin, ensure you have:
- **Python 3.7+**: [Download from python.org](https://www.python.org/downloads/)
  - ✅ Add Python to PATH during installation
  - ✅ Verify: Run `python --version` in command prompt
- **OpenGL 3.3+ Compatible GPU**: Most modern graphics cards (2010+)
  - ✅ Update graphics drivers to latest version
- **4GB+ RAM**: Recommended for smooth rendering
- **Internet Connection**: For first-time FFmpeg download (one-time setup)
- **Windows 10/11**: Primary supported platform

### Quick Installation

**Option 1: Web Editor (Recommended)**
```bash
# 1. Clone or download the repository
# 2. Double-click StartWebEditor.bat
StartWebEditor.bat

# The script will automatically:
# - Create Python virtual environment
# - Install all dependencies (Flask, librosa, moderngl, etc.)
# - Download FFmpeg/ffprobe (first-time only)
# - Launch the web editor on http://localhost:5000
```

**Option 2: Batch Processor**
```bash
# 1. Clone or download the repository
# 2. Double-click RunMe.bat
RunMe.bat

# The script will automatically:
# - Create Python virtual environment
# - Install all dependencies
# - Download FFmpeg/ffprobe (first-time only)
# - Process all audio files in Input_Audio/
```

**Option 3: Manual Installation**
```bash
# 1. Create virtual environment
python -m venv venv

# 2. Activate virtual environment
venv\Scripts\activate

# 3. Install dependencies
pip install -r requirements.txt

# 4. Verify installation
python verify_installation.py
python verify_ffmpeg.py
```

### First-Time Setup
1. **Add Audio Files**: Place MP3, WAV, or other audio files in `Input_Audio/` folder
2. **Add Video Files** (optional): Place green screen videos in `Input_Video/` folder
3. **Launch**: Run `StartWebEditor.bat` or `RunMe.bat`
4. **Create**: Start making audio-reactive videos!

### Verify Installation
```bash
# Check all components
python verify_installation.py

# Check FFmpeg specifically
python verify_ffmpeg.py
```

### Dependencies (Automatically Installed)
- **Core Rendering**: numpy, Pillow, moderngl, scipy
- **Audio Processing**: librosa, ffmpeg-python
- **Web Editor**: Flask, flask-cors

---

## 🎨 Web Editor (Primary Workflow - RECOMMENDED)

The **Web Editor** is the most comprehensive and user-friendly way to create videos. It provides a professional, visual editing experience with complete control over every aspect of your video.

### ✨ Key Features

#### Professional Timeline Editor
- **Adobe After Effects-style interface**: Multi-layer timeline with precise timing control
- **Visual feedback**: See exactly what you're creating as you build
- **Zoom controls**: Timeline zoom with dynamic tick marks for precise editing
- **Audio waveform visualization**: Visual representation of your music

#### Drag & Drop Interface
- **Shaders**: Drag audio-reactive GLSL shaders onto the timeline
- **Transitions**: Add smooth transitions between shader segments
- **Videos**: Layer green screen videos with automatic chroma keying
- **Precise positioning**: Move, resize, and arrange all elements visually

#### Asset Management
- **Shader browser**: Browse 35+ included shaders with preview images
- **Star ratings**: Rate shaders for easy organization (1-3 stars)
- **Audio reactivity indicators**: See which shaders respond to music
- **Descriptions**: Detailed information about each shader's visual style

#### Multi-Layer Compositing
- **Shader layers**: Multiple audio-reactive shader segments
- **Transition layers**: Smooth blending between shaders
- **Video layers**: Green screen video overlays with chroma key support
- **Music layer**: Audio track with waveform visualization

#### Green Screen Video Features
- **Drag & drop green screen videos**: Layer videos with automatic chroma keying
- **Preview toggle**: Right-click to enable/disable preview without affecting render
- **Pre-render preview**: See green screen videos synced with audio before rendering
- **Advanced chroma key**: Single-pass compositing with precise color matching (rgb(0, 214, 0))
- **Auto-management**: Preview automatically disabled after render, re-enabled before next render
- **Visual indicators**: Ghostly appearance (50% opacity, diagonal stripes) when preview disabled

#### Advanced Controls
- **Undo/Redo**: Full history support for all edits
- **Timeline controls**: Play, pause, scrub through your composition
- **Real-time preview**: See changes immediately
- **Export settings**: Configure resolution, quality, and output format

### 🚀 Quick Start - Web Editor

**Launch the editor:**
```bash
# Double-click to launch
StartWebEditor.bat

# Or run manually
cd web_editor
python app.py
```

**Open in browser:**
Navigate to **http://localhost:5000**

**Create your first video:**
1. **Select Music**: Click an audio file from the left panel
2. **Add Shaders**: Drag shaders from the right panel onto the timeline
3. **Add Transitions**: Drag transitions between shader segments
4. **Adjust Timing**: Resize and move elements to match your music
5. **Render**: Click "Render Video" and wait for processing

### 📚 Web Editor Documentation
- **User Guide**: `Documentation/WEB_EDITOR_README.md`
- **Quick Start Tutorial**: `Documentation/QUICK_START.md`
- **Technical Architecture**: `Documentation/ARCHITECTURE.md`
- **Complete Specification**: `Documentation/WEB_EDITOR_SPEC.md`

### 🎯 Why Use the Web Editor?
- ✅ **Visual control**: See exactly what you're creating
- ✅ **Precise timing**: Frame-accurate positioning
- ✅ **Easy to learn**: Intuitive drag-and-drop interface
- ✅ **Professional results**: Multi-layer compositing with transitions
- ✅ **Flexible workflow**: Mix shaders, videos, and effects freely
- ✅ **No coding required**: Everything is visual and interactive

---

## 🔧 OneOff Renderer (Quick Testing Tool)

The **OneOff Renderer** is a command-line tool for quickly testing and rendering individual shaders. Perfect for shader developers or when you want to preview a single shader without setting up a full timeline.

### 🎯 Purpose
- **Quick testing**: Render any shader in seconds
- **Shader development**: Test new shaders before adding to projects
- **Preview generation**: Create quick previews of shader effects
- **Simple workflow**: No timeline setup required

### 📝 Usage

**Basic syntax:**
```bash
python oneoff.py <shader_name> <duration>
```

**Parameters:**
- `shader_name`: Name of shader file (with or without .glsl extension)
- `duration`: Duration in seconds (e.g., `30`) or MM:SS format (e.g., `01:30`)

**Examples:**
```bash
# Render for 5 seconds
python oneoff.py "MoltenHeart.glsl" 5

# Render for 30 seconds
python oneoff.py "Cosmic Nebula2.glsl" 30

# Render for 1 minute 30 seconds
python oneoff.py "Bubble Colors" 01:30

# Extension is optional
python oneoff.py Gyroid Art 45
```

### ⚙️ How It Works
- **Automatic audio**: Uses the first audio file found in `Input_Audio/` directory
- **Config settings**: Respects all `config.json` settings (resolution, quality, etc.)
- **Single shader**: Disables multi-shader cycling and transitions
- **Output naming**: Creates `{shader_name}_{duration}s.mp4` in `Output_Video/`
- **Full audio reactivity**: Complete frequency analysis and audio texture support

### 🎵 Audio Reactivity
All shaders receive real-time audio data:
- **FFT spectrum**: 512-bin frequency analysis
- **Waveform data**: High-resolution audio waveform
- **Bass/treble**: Automatic frequency band extraction
- **Synchronized**: Perfect sync between audio and visuals

### 💡 Use Cases
- **Testing new shaders**: Quick preview before adding to web editor
- **Shader development**: Iterate rapidly on shader code
- **Content creation**: Generate simple single-shader videos
- **Quality checking**: Verify shader behavior with different audio

---

## ⚡ Batch Processor (Automated Workflow)

The **Batch Processor** is the original automated system for generating videos with random shader cycling. It processes multiple audio files automatically with minimal user intervention.

### 🎯 Purpose
- **Automated generation**: Create videos without manual editing
- **Random variety**: Different shader combinations each time
- **Batch processing**: Handle multiple audio files automatically
- **Quick results**: Fast video generation with minimal setup

### 🚀 Quick Start - Batch Processor

**Launch the processor:**
```bash
# Double-click to launch
RunMe.bat
```

**What happens automatically:**
1. **Setup**: Creates Python virtual environment and installs dependencies
2. **FFmpeg**: Downloads and configures FFmpeg/ffprobe (first-time only)
3. **Discovery**: Finds all audio files in `Input_Audio/` and shaders in `Shaders/`
4. **Analysis**: Processes audio for frequency data with 1024-point FFT
5. **Rendering**: Creates videos with random shader cycling and transitions
6. **Output**: Saves videos to `Output_Video/` with names matching audio files

### ⚙️ How It Works

### ✨ Batch Processor Features

#### 🎬 Advanced Multi-Shader System
- **Dynamic shader cycling**: Automatically switches between shaders during rendering
- **Intelligent randomization**: Weighted selection for fair distribution
- **Smart history avoidance**: Prevents repetition of recently used shaders
- **Seamless transitions**: Smooth blending with 100+ transition effects

#### 🎯 Priority-Based Transition Selection
- **Quality-first algorithm**: Prioritizes best transitions using preference + status scoring
- **Intelligent progression**: Uses high-quality transitions first
- **Broken transition avoidance**: Automatically excludes non-functional transitions
- **Metadata-driven**: Centralized configuration with quality tracking

#### 🎵 Advanced Audio Processing
- **Real-time audio analysis**: 1024-point FFT with 512-bin spectrum
- **Audio-reactive visuals**: Shaders respond dynamically to music
- **Batch processing**: Handles multiple audio files automatically
- **Format support**: MP3, WAV, FLAC, M4A, AAC, OGG, WMA

#### ⚡ High-Performance Rendering
- **Fast streaming mode**: 3-5x performance improvement over frame-by-frame
- **Memory optimized**: Minimal temporary file usage
- **GPU accelerated**: OpenGL 3.3+ with ModernGL
- **Production quality**: H.264/AAC encoding with configurable settings

### 📊 Results
- **Output location**: `Output_Video/` directory
- **Naming**: Videos named to match source audio files
- **Content**: Multiple shaders with smooth transitions
- **Duration**: Full audio length with synchronized visuals

### 🔧 Manual Verification
Verify your installation:
```bash
python verify_ffmpeg.py
python verify_installation.py
```

---

## 📁 Directory Structure

```
OneOffRender/
├── Documentation/                # 📚 All project documentation
│   ├── WEB_EDITOR_README.md    # Web editor user guide
│   ├── QUICK_START.md          # 5-minute web editor tutorial
│   ├── ARCHITECTURE.md         # Technical architecture docs
│   ├── WEB_EDITOR_SPEC.md      # Complete web editor specification
│   ├── SETUP_GUIDE.md          # Installation and setup guide
│   ├── PROJECT_SUMMARY.md      # Project overview
│   └── *.md                    # Additional documentation files
├── web_editor/                   # � Web-based timeline editor
│   ├── app.py                  # Flask backend server
│   ├── templates/              # HTML templates
│   │   └── editor.html        # Main editor interface
│   ├── static/                 # Frontend assets
│   │   ├── css/editor.css     # Styling
│   │   └── js/                # JavaScript modules
│   │       ├── api.js         # API communication
│   │       ├── timeline.js    # Timeline logic
│   │       └── editor.js      # Main controller
│   └── requirements.txt        # Web editor dependencies
├── Input_Audio/                  # 🎵 Place your audio files here
│   └── *.mp3, *.wav, *.flac, etc.
├── Input_Video/                  # � Video clips for compositing
│   ├── *.mp4, *.mov, etc.
│   └── thumbnails/             # Auto-generated video thumbnails
├── Output_Video/                 # ✅ Generated videos appear here
│   └── *.mp4
├── Shaders/                      # 🌈 GLSL shader files (35+ shaders)
│   ├── *.glsl                  # Shader source files
│   ├── *.JPG                   # Preview images
│   └── metadata.json           # Shader ratings & descriptions
├── Transitions/                  # ✨ Transition effects (100+ transitions)
│   ├── *.glsl                  # Transition shader files
│   └── Transitions_Metadata.json # Transition quality ratings
├── config.json                   # ⚙️ Batch processor configuration
├── render_shader.py              # Batch rendering engine
├── render_timeline.py            # Timeline rendering engine
├── oneoff.py                     # 🔧 Single shader renderer
├── RunMe.bat                     # ⚡ Batch processor launcher
├── StartWebEditor.bat           # � Web editor launcher
├── requirements.txt              # Python dependencies
└── README.md                     # This file
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

## 🎯 Priority-Based Transition System

The application features an advanced transition selection system that prioritizes quality:

### Scoring Algorithm
```
Score = Preference Level + Working Status

Preference Levels:          Working Status:
- Highly Desired: 1 point   - Fully Working: 1 point
- Mid: 2 points            - Minor Adjustments: 2 points
- Low: 3 points            - Broken: 3 points (excluded)
```

### Quality Tiers (94 Working Transitions)
- **Highly Desired** (21 transitions): Premium quality - **Used First**
- **Mid Quality** (26 transitions): Solid, reliable transitions
- **Low Priority** (47 transitions): Additional variety
- **Broken** (6 transitions): Automatically excluded from selection

### Selection Behavior
1. **Prioritize Highly Desired**: Uses best transitions first
2. **Progress to Mid Quality**: When high-quality transitions exhausted
3. **Use Low Priority**: For additional variety as needed
4. **Avoid Repetition**: History tracking prevents recent repeats
5. **Reset for New Files**: Each audio file starts fresh with best transitions

### Web Editor Integration
- Transitions displayed in preference groups with star ratings
- Visual indicators: *** (Highly Desired), ** (Mid), * (Low)
- Drag-and-drop interface for manual transition placement
- Automatic filtering of broken transitions

## 🌈 Included Shaders & Transitions

### Shader Library (35+ Shaders)

The application includes a diverse collection of professionally crafted GLSL shaders:

#### Audio-Reactive Shaders (28 shaders)
These shaders respond dynamically to music frequencies:
- **MoltenHeart.glsl** - Flowing organic lava patterns
- **Cosmic Nebula2.glsl** - Deep space gas clouds with stellar formation
- **Luminous Nebulae.glsl** - Dynamic nebulae with color palettes
- **Bubble Colors.glsl** - Pulsing bubble effects with color shifts
- **Colorful Columns.glsl** - 3D columns with frequency-based height
- **Colorful Columns_V2.glsl** - Enhanced column visualization
- **Base Vortex.glsl** - Rotating tunnel vortex effects
- **Cosmic Energy Streams1.glsl** - Flowing energy patterns
- **Flowing Mathematical Patterns2.glsl** - Mathematical visualizations
- **Fork Bass Vorte PAEz 125.1.glsl** - Bass-reactive vortex
- **Iridescent Breathing Orbs.glsl** - Pulsing sphere effects
- **Petal Drift.glsl** - Drifting Gaussian petals
- **Sonic Nebula.glsl** - Audio-driven nebula effects
- **Volumetric Glow2.glsl** - Volumetric lighting effects
- **Xor Mashup 002.glsl** - Complex raymarched fractals
- And 13 more audio-reactive shaders...

#### Static Shaders (7 shaders)
Beautiful visualizations without audio reactivity:
- **Gyroid Art.glsl** - Mathematical gyroid surfaces
- **Funky Flight.GLSL** - Smooth camera flight paths
- And 5 more static shaders...

### Smart Shader Management
- **Automatic discovery**: Place .glsl files in Shaders/ folder
- **Weighted selection**: Fair distribution across all shaders
- **History avoidance**: Prevents recent shader repetition
- **Pre-compilation**: All shaders compiled at startup for performance
- **Metadata system**: Ratings, descriptions, and audio reactivity flags

### Transition Library (100+ Transitions)

Over 100 professionally crafted transition effects:

#### Quality Tiers
- **Highly Desired (21 transitions)**: Premium quality, used first
- **Mid Quality (26 transitions)**: Solid, reliable transitions
- **Low Priority (47 transitions)**: Additional variety
- **Broken (6 transitions)**: Automatically excluded

#### Transition Categories
- **Fade effects**: Crossfade, color fade, grayscale fade
- **Geometric**: Circles, squares, polygons, grids
- **Distortion**: Ripples, warps, morphs, displacement
- **Creative**: Film burns, kaleidoscopes, swirls, glitches
- **3D effects**: Cube, doorway, page flip, rotation

#### Intelligent Selection
- **Priority-based**: Uses best transitions first
- **Quality scoring**: Preference + status algorithm
- **History tracking**: Avoids recent repetition
- **Metadata-driven**: Centralized quality configuration

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

## 🎵 Supported Audio Formats

All workflows support a wide range of audio formats:
- **MP3** - Most common format
- **WAV** - Uncompressed audio
- **FLAC** - Lossless compression
- **M4A** - Apple audio format
- **AAC** - Advanced audio coding
- **OGG** - Open-source format
- **WMA** - Windows media audio

**Features:**
- Automatic format detection
- Full-length rendering (or custom duration limits)
- High-quality audio preservation in output

---

## 🛠️ Customization

### Adding Custom Shaders

**For Web Editor:**
1. Place `.glsl` file in `Shaders/` folder
2. Add preview image as `{shader_name}.JPG`
3. Add metadata entry to `Shaders/metadata.json`:
   ```json
   {
     "name": "YourShader.glsl",
     "preview_image": "YourShader.JPG",
     "stars": 3,
     "buffer": null,
     "texture": null,
     "description": "Your shader description",
     "audio_reactive": true
   }
   ```
4. Restart web editor to see new shader

**For Batch Processor:**
1. Place `.glsl` file in `Shaders/` folder
2. Shader automatically discovered and included in rotation
3. Must follow standard fragment shader format with audio texture support

### Adding Custom Transitions

1. Place transition `.glsl` file in `Transitions/` folder
2. Add metadata entry to `Transitions/Transitions_Metadata.json`:
   ```json
   "YourTransition.glsl": {
     "preference": "Highly Desired",
     "status": "Fully Working"
   }
   ```
3. Transition automatically available in web editor and batch processor

### Performance Tuning

**For faster rendering or testing**, edit `config.json`:

```json
{
  "duration_override": {
    "enabled": true,
    "cutoff_time": "00:30"  // 30-second test render
  },
  "output": {
    "resolution": {
      "width": 1280,        // Lower resolution for speed
      "height": 720
    }
  },
  "rendering": {
    "quality": {
      "crf": 23,           // Higher = smaller files, lower quality
      "preset": "fast"     // fast, medium, slow
    }
  }
}
```

---

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

### 🔧 Troubleshooting

#### Setup Issues
- **Permission errors**: Run `RunMe.bat` or `StartWebEditor.bat` as Administrator
- **Antivirus blocking**: Ensure antivirus isn't blocking Python or FFmpeg installation
- **Missing audio files**: Check that `Input_Audio/` folder contains supported audio files
- **Python not found**: Ensure Python 3.7+ is installed and in system PATH
- **Virtual environment issues**: Delete `venv/` folder and run setup again

#### Web Editor Issues
- **Port already in use**: Close other applications using port 5000, or edit `web_editor/app.py` to use a different port
- **Browser not loading**: Check console for errors, ensure Flask server started successfully
- **Assets not loading**: Verify `Input_Audio/`, `Input_Video/`, and `Shaders/` folders exist
- **Render fails**: Check console output for specific error messages
- **Timeline not responding**: Refresh browser page, check browser console for JavaScript errors

#### Rendering Issues
- **OpenGL errors**: Update graphics drivers to latest version
- **Shader compilation fails**: Check shader syntax, ensure it follows GLSL 3.3+ standards
- **Slow performance**: Try lower resolution in `config.json`, close other GPU-intensive applications
- **Out of memory**: Reduce resolution, close other applications, ensure 4GB+ RAM available
- **FFmpeg errors**: Run `python verify_ffmpeg.py` to check FFmpeg installation

#### Quality Issues
- **File size too large**: Increase CRF value (18-23) in `config.json`
- **Quality too low**: Decrease CRF value (15-18) for higher quality
- **Choppy video**: Ensure frame rate is set to 30fps, check GPU performance
- **Audio sync issues**: Verify audio file is not corrupted, try different audio format

#### Getting Help
- **Check logs**: Look at console output for detailed error messages
- **Verify installation**: Run `python verify_installation.py`
- **Test FFmpeg**: Run `python verify_ffmpeg.py`
- **Check documentation**: See `Documentation/` folder for detailed guides

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

## 🎯 Which Workflow Should I Use?

### 🎨 Use the **Web Editor** if you want:
- ✅ **Visual control**: See exactly what you're creating
- ✅ **Precise timing**: Frame-accurate positioning of all elements
- ✅ **Professional workflow**: Adobe After Effects-style timeline
- ✅ **Multi-layer compositing**: Mix shaders, videos, and transitions
- ✅ **Easy to learn**: Intuitive drag-and-drop interface
- ✅ **Preview capabilities**: Rate and preview shaders before using
- ✅ **Complex compositions**: Create sophisticated multi-layer videos

**Best for:** Anyone who wants manual control and professional results

### 🔧 Use **OneOff Renderer** if you want:
- ✅ **Quick testing**: Render a single shader in seconds
- ✅ **Shader development**: Test new shaders rapidly
- ✅ **Simple workflow**: No timeline setup required
- ✅ **Command-line**: Fast, scriptable rendering
- ✅ **Preview generation**: Create quick shader previews

**Best for:** Shader developers and quick testing

### ⚡ Use the **Batch Processor** if you want:
- ✅ **Automated generation**: No manual editing required
- ✅ **Random variety**: Different combinations each time
- ✅ **Batch processing**: Handle multiple audio files automatically
- ✅ **Quick results**: Fast video generation
- ✅ **Command-line**: Fully automated workflow

**Best for:** Automated content generation and batch processing

---

## 📚 Documentation

### 📖 Complete Documentation Library

All documentation is now organized in the `Documentation/` folder:

#### Web Editor Documentation
- **User Guide**: `Documentation/WEB_EDITOR_README.md` - Complete web editor manual
- **Quick Start**: `Documentation/QUICK_START.md` - 5-minute tutorial
- **Architecture**: `Documentation/ARCHITECTURE.md` - Technical architecture
- **Specification**: `Documentation/WEB_EDITOR_SPEC.md` - Complete specification

#### General Documentation
- **Setup Guide**: `Documentation/SETUP_GUIDE.md` - Installation instructions
- **Project Summary**: `Documentation/PROJECT_SUMMARY.md` - Project overview
- **STFT Compatibility**: `Documentation/README STFT COMPATABILITY.md` - Audio system details

#### Implementation Guides
- **Render Pipeline**: `Documentation/RENDER_PIPELINE_IMPLEMENTATION.md`
- **Layer System**: `Documentation/SHADERS_TRANSITIONS_LAYER_IMPLEMENTATION.md`
- **Green Screen**: `Documentation/GREEN_SCREEN_VIDEOS_LAYER_IMPLEMENTATION.md`
- **Green Screen Preview Toggle**: `Documentation/GREEN_SCREEN_PREVIEW_TOGGLE.md`
- **Chroma Key Implementation**: `Documentation/chromakey note.md`

#### Additional Resources
- **Bug Fixes**: Multiple bug fix documentation files
- **Feature Guides**: Layer swap, music layer, timeline functionality
- **Task Lists**: Development tasks and todos

### 📝 This README
This file provides:
- Overview of all three workflows
- Quick start guides for each system
- Configuration reference
- Audio system documentation
- Troubleshooting tips

---

## License

This project is shared under the [Creative Commons Attribution–NonCommercial 4.0 International License (CC BY-NC 4.0)](https://creativecommons.org/licenses/by-nc/4.0/).

You are free to share and adapt this work for non-commercial purposes, provided you give appropriate credit to the original author.

While the Python rendering system in this project is my own work, I frequently borrow and build upon shaders created by others. Attribution is very important to me. I've included an `attributions.txt` file in the project root to acknowledge those works.

If I have unintentionally missed crediting your work, please reach out here or on X at [@OneHung](https://x.com/OneHung). My sincere apologies — I'll make sure to correct any omissions promptly.
