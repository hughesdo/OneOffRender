# Video Effects Implementation TODO

## 🎬 Overview

This document outlines the implementation plan for **streaming video effects** in OneOffRender. Instead of frame-by-frame processing, this approach uses OneOffRender's **fast streaming mode** to apply neural network and other shader effects to video input in real-time.

## 🎯 Goal

Create a `Video_Effects/` system that:
- ✅ **Streams video input** directly to GPU textures (no frame extraction)
- ✅ **Applies shader effects** in real-time using OneOffRender's streaming pipeline
- ✅ **Maintains audio reactivity** with synchronized FFT analysis
- ✅ **Preserves performance** using the 3-5x faster streaming mode
- ✅ **Supports multiple effects** through different shader configurations

## 📁 Proposed Folder Structure

```
Video_Effects/
├── README.md                           # Usage instructions
├── Shaders/                           # Video effect shaders
│   ├── neural_video_effect.glsl       # Neural network video effect (FIRST IMPLEMENTATION)
│   ├── glitch_video_effect.glsl       # Future: Glitch effects
│   ├── kaleidoscope_video_effect.glsl # Future: Kaleidoscope effects
│   └── color_shift_video_effect.glsl  # Future: Color manipulation
├── Configs/                           # Configuration files
│   ├── neural_config.json             # Config for neural effect
│   ├── glitch_config.json             # Future configs
│   └── template_config.json           # Template for new effects
├── Input_Videos/                      # Source video files
│   ├── test_video.mp4
│   ├── dance_sequence.mp4
│   └── nature_footage.mp4
├── Output_Videos/                     # Processed results
│   └── (generated files)
└── Scripts/                          # Helper scripts
    ├── process_video.py               # Main processing script
    └── batch_process.py               # Batch processing utility
```

## 🧠 First Implementation: Neural Video Effect

### Target Shader: `neural_image_shader.glsl`

**Location**: `Shaders/neural_image_shader.glsl`

**Why This Shader**:
- ✅ **Complete neural network** - Full 16-layer neural network (f0_0 through f16_3)
- ✅ **Audio reactive** - Strong response to bass, treble, and FFT spectrum
- ✅ **Recently fixed** - Coordinate system and upside-down issues resolved
- ✅ **Texture ready** - Already samples from `iChannel1` for image input
- ✅ **Proven effects** - Creates flowing, organic, "neural dream" transformations

### Required Modifications

**Current State**:
```glsl
// Sample the image texture
vec4 sampleImage(vec2 uv) {
    return texture(iChannel1, uv);  // Static image texture
}
```

**Needed Changes**:
```glsl
// Sample the video stream texture
vec4 sampleVideoFrame(vec2 uv) {
    return texture(iChannel1, uv);  // Video stream texture (updated each frame)
}
```

**The shader is already 95% ready!** It just needs:
1. Rename `sampleImage()` to `sampleVideoFrame()` for clarity
2. Update comments to reflect video input instead of static image
3. Test with streaming video texture binding

## ⚙️ Technical Implementation Plan

### Phase 1: Basic Video Streaming ⏳

**Goal**: Get neural effect working with video input

**Tasks**:
1. **Create `Video_Effects/` folder structure**
2. **Copy and modify `neural_image_shader.glsl`**:
   - Rename to `neural_video_effect.glsl`
   - Update function names and comments
   - Test compilation
3. **Create configuration file** for video texture binding
4. **Test with short video clip** (5-10 seconds)

**Expected Result**: Neural network transforms video frames with audio reactivity

### Phase 2: Streaming Pipeline Integration ⏳

**Goal**: Integrate with OneOffRender's streaming mode

**Tasks**:
1. **Modify texture loading system** to support video streams
2. **Update `render_shader.py`** to handle video textures on `iChannel1`
3. **Implement video texture streaming** using FFmpeg → ModernGL pipeline
4. **Test performance** vs frame-by-frame approach

**Expected Result**: 3-5x performance improvement over frame extraction

### Phase 3: User Interface & Scripts ⏳

**Goal**: Make video effects easy to use

**Tasks**:
1. **Create `process_video.py`** wrapper script
2. **Add video effects to web editor** (optional)
3. **Create batch processing** for multiple videos
4. **Add progress reporting** and error handling

**Expected Result**: Simple command-line interface for video effects

### Phase 4: Additional Effects ⏳

**Goal**: Expand beyond neural effects

**Tasks**:
1. **Port other shaders** to video input (glitch, kaleidoscope, etc.)
2. **Create effect presets** with different parameters
3. **Add real-time preview** capability
4. **Optimize for different video formats**

## 🔧 Configuration Example

**`Video_Effects/Configs/neural_config.json`**:
```json
{
  "input": {
    "video_file": "Video_Effects/Input_Videos/test_video.mp4",
    "audio_file": "Input_Audio/music.mp3"
  },
  "shader_settings": {
    "shader_file": "Video_Effects/Shaders/neural_video_effect.glsl",
    "textures": {
      "iChannel1": {
        "type": "video_stream",
        "file": "Video_Effects/Input_Videos/test_video.mp4",
        "filter": "linear",
        "wrap": "clamp"
      }
    }
  },
  "rendering": {
    "streaming": true,
    "quality": {
      "crf": 18,
      "preset": "medium"
    }
  },
  "output": {
    "video_file": "Video_Effects/Output_Videos/test_video_neural.mp4",
    "frame_rate": 30
  }
}
```

## 🎯 Expected Results

### Neural Video Effect Output:
- **Dynamic transformations** - Video content morphs and flows with neural patterns
- **Audio reactivity** - Effects pulse and change intensity with music
- **Preserved motion** - Original video movement maintained but "neurally transformed"
- **Organic feel** - Flowing, dream-like distortions that follow the neural network
- **High quality** - Full resolution processing with smooth temporal coherence

### Performance Characteristics:
- **3-5x faster** than frame-by-frame processing
- **Memory efficient** - No temporary frame storage
- **Real-time capable** - Suitable for live processing (future)
- **GPU accelerated** - Full hardware acceleration

## 🚀 Getting Started

### Prerequisites:
- OneOffRender fully installed and working
- FFmpeg with video codec support
- Test video file (MP4 recommended)
- Audio file for reactivity

### Quick Start:
1. **Create folder structure** as outlined above
2. **Copy `neural_image_shader.glsl`** to `Video_Effects/Shaders/neural_video_effect.glsl`
3. **Create basic config file** based on template
4. **Test with short video** (5-10 seconds first)
5. **Verify streaming mode** is enabled in config

## 📋 Status Tracking

- [ ] **Phase 1**: Basic video streaming setup
- [ ] **Phase 2**: Streaming pipeline integration  
- [ ] **Phase 3**: User interface and scripts
- [ ] **Phase 4**: Additional effects and optimization

## 🎉 Vision

Once complete, users will be able to:
```bash
# Process single video with neural effect
python Video_Effects/Scripts/process_video.py input.mp4 --effect neural --audio music.mp3

# Batch process multiple videos
python Video_Effects/Scripts/batch_process.py --effect neural --audio-dir Input_Audio/

# Real-time preview (future)
python Video_Effects/Scripts/preview.py input.mp4 --effect neural --live
```

This will create a powerful video effects system that leverages OneOffRender's streaming capabilities for high-performance, audio-reactive video processing! 🌟
