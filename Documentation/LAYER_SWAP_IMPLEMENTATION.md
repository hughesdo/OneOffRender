# Layer Swap Implementation

## Overview

This document describes the architectural change that swapped the layer ordering in the OneOffRender system to improve visual logic and rendering efficiency.

## Change Summary

### Previous System (Before Swap)
- **Layer 0**: Shaders & Transitions (rendered first, bottom visual layer)
- **Layer 1**: Green Screen Videos (rendered second, top visual layer)

### New System (After Swap)
- **Layer 0**: Green Screen Videos (rendered second, **top visual layer**)
- **Layer 1**: Shaders & Transitions (rendered first, **bottom visual layer**)

## Rationale

### 1. Visual Logic Improvement
- **Timeline UI Alignment**: In the web GUI timeline, the top layer now represents what appears on top in the final video
- **Intuitive Layer Ordering**: Layer 0 (top of timeline) = top of visual output
- **User Experience**: More intuitive for users to understand layer stacking

### 2. Chroma Key Logic
- **Green Screen on Top**: Green screen videos need to be the topmost layer
- **Transparency**: Chroma key removes green pixels, allowing shader layer below to show through
- **Correct Compositing**: Shader layer renders as background, green screen overlays with transparency

### 3. Performance Optimization
- **Skip Empty Layers**: If no green screen videos are present (Layer 0 empty), green screen processing is skipped entirely
- **Efficient Rendering**: Only render what's needed

## Technical Implementation

### Files Modified

#### 1. Web Interface - Timeline Labels (`web_editor/static/js/timeline.js`)

**Lines 341-359:**
```javascript
// Layer 0 is dedicated to green screen videos (top visual layer)
if (i === 0) {
    nameDiv.classList.add('green-screen-videos-layer');
    nameDiv.textContent = 'Green Screen Videos';
    nameDiv.dataset.layer = '0';
}
// Layer 1 is dedicated to shaders and transitions (bottom visual layer)
else if (i === 1) {
    nameDiv.classList.add('shaders-transitions-layer');
    nameDiv.textContent = 'Shaders & Transitions';
    nameDiv.dataset.layer = '1';
}
```

#### 2. Web Interface - Drag & Drop Validation (`web_editor/static/js/editor.js`)

**Lines 468-505:**
```javascript
isValidDropForLayer(elementType, targetLayer) {
    // Layer 0 is dedicated to green screen videos only (top visual layer)
    if (targetLayer === 0) {
        return elementType === 'video';
    }
    // Layer 1 is dedicated to shaders and transitions only (bottom visual layer)
    if (targetLayer === 1) {
        return elementType === 'shader' || elementType === 'transition';
    }
    // All other layers accept any type
    return true;
}
```

**Error Messages Updated:**
- Layer 0: "Layer 1 (Green Screen Videos) only accepts videos..."
- Layer 1: "Layer 2 (Shaders & Transitions) only accepts shaders and transitions..."

#### 3. Rendering Pipeline - Main Render Method (`render_timeline.py`)

**Lines 118-128:**
```python
# Render Layer 1 (Shaders & Transitions) - Bottom visual layer
self.logger.info("\n--- Rendering Layer 1: Shaders & Transitions ---")
layer1_video = self.render_shader_layer()

# Render Layer 0 (Green Screen Videos) - Top visual layer
self.logger.info("\n--- Rendering Layer 0: Green Screen Videos ---")
layer0_video = self.render_greenscreen_layer()

# Composite layers (shader layer on bottom, green screen on top)
self.logger.info("\n--- Compositing Layers ---")
composite_video = self.composite_layers(layer1_video, layer0_video)
```

#### 4. Rendering Pipeline - Shader Layer Method (`render_timeline.py`)

**Lines 194-223:**
```python
def render_shader_layer(self):
    """Render all shaders and transitions on Layer 1 (bottom visual layer)."""
    layer1_elements = self.get_elements_by_layer(1)
    
    if not layer1_elements:
        self.logger.warning("No elements on Layer 1, creating black video")
        return self.create_black_video()
    
    self.logger.info(f"Found {len(layer1_elements)} elements on Layer 1")
    
    # ... shader rendering logic ...
    
    output_path = self.temp_dir / "layer1_raw.mp4"
    self.render_layer1_timeline(layer1_elements, compiled_shaders, audio_data, output_path)
    
    return output_path
```

#### 5. Rendering Pipeline - Green Screen Layer Method (`render_timeline.py`)

**Lines 225-239:**
```python
def render_greenscreen_layer(self):
    """Render green screen videos on Layer 0 (top visual layer)."""
    layer0_elements = self.get_elements_by_layer(0)
    
    if not layer0_elements:
        self.logger.info("No elements on Layer 0, skipping green screen processing")
        return None
    
    self.logger.info(f"Found {len(layer0_elements)} video elements on Layer 0")
    
    # ... green screen rendering logic ...
    
    output_path = self.temp_dir / "layer0_composite.mp4"
    self.render_video_layer(layer0_elements, output_path)
    
    return output_path
```

#### 6. Rendering Pipeline - Composite Method (`render_timeline.py`)

**Lines 241-280:**
```python
def composite_layers(self, shader_layer_path, greenscreen_layer_path):
    """Composite all layers together using FFmpeg with proper alpha channel handling.
    
    Args:
        shader_layer_path: Path to Layer 1 (shaders/transitions - bottom layer)
        greenscreen_layer_path: Path to Layer 0 (green screen videos - top layer with transparency)
    """
    if greenscreen_layer_path is None:
        self.logger.info("No Layer 0 (green screen) content, using Layer 1 (shaders) only")
        return shader_layer_path

    output_path = self.temp_dir / "composite.mp4"

    self.logger.info("Compositing Layer 1 (shaders - background) + Layer 0 (green screen - overlay with transparency)")

    # Use FFmpeg overlay filter with proper alpha channel handling
    # Layer 0 (green screen) has transparency from chroma key applied on top of Layer 1 (shaders)
    cmd = [
        'ffmpeg',
        '-y',
        '-i', str(shader_layer_path),       # Input 0: Layer 1 (shaders) - background, no alpha
        '-i', str(greenscreen_layer_path),  # Input 1: Layer 0 (green screen) - overlay with alpha
        '-filter_complex', '[0:v][1:v]overlay=0:0:format=auto',  # Auto format handles alpha
        '-c:v', 'libx264',
        '-crf', '18',
        '-preset', 'medium',
        '-pix_fmt', 'yuv420p',  # Final output without alpha
        str(output_path)
    ]
    
    # ... FFmpeg execution ...
    
    return output_path
```

#### 7. Method Rename (`render_timeline.py`)

**Line 630:**
- **Old**: `def render_layer0_timeline(...)`
- **New**: `def render_layer1_timeline(...)`

#### 8. Raw File Names (`render_timeline.py`)

**Shader Layer (Layer 1):**
- Raw file: `layer1_raw.rgb`
- Output: `layer1_raw.mp4`

**Green Screen Layer (Layer 0):**
- Raw file: `layer0_raw.rgb`
- Output: `layer0_composite.mp4`

## Rendering Flow

### New Rendering Pipeline

```
1. User creates timeline in web editor
   - Layer 0 (top): Green screen videos
   - Layer 1 (bottom): Shaders & transitions
   ↓
2. User clicks "Render Video"
   ↓
3. Backend saves manifest and launches renderer
   ↓
4. render_timeline.py processes layers:
   
   Step 1: Render Layer 1 (Shaders & Transitions)
   - Load shader elements from layer 1
   - Compile shaders and transitions
   - Render frame-by-frame with audio reactivity
   - Output: layer1_raw.mp4 (background layer, no alpha)
   
   Step 2: Render Layer 0 (Green Screen Videos)
   - Load video elements from layer 0
   - Extract frames from videos
   - Apply chroma key to remove green
   - Output: layer0_composite.mp4 (overlay layer with alpha)
   
   Step 3: Composite Layers
   - FFmpeg overlay: [layer1][layer0]overlay
   - Layer 1 (shaders) = background
   - Layer 0 (green screen) = overlay with transparency
   - Output: composite.mp4
   ↓
5. Add audio track
   ↓
6. Final video saved to Output_Video/
```

### FFmpeg Compositing Command

```bash
ffmpeg -y \
  -i layer1_raw.mp4 \          # Input 0: Shaders (background)
  -i layer0_composite.mp4 \    # Input 1: Green screen (overlay with alpha)
  -filter_complex '[0:v][1:v]overlay=0:0:format=auto' \
  -c:v libx264 \
  -crf 18 \
  -preset medium \
  -pix_fmt yuv420p \
  composite.mp4
```

## Manifest Structure

### Example Timeline Manifest

```json
{
  "version": "1.0",
  "project_name": "My Project",
  "audio": {
    "path": "Audio/song.mp3"
  },
  "timeline": {
    "duration": 22,
    "elements": [
      {
        "id": "video_1",
        "type": "video",
        "name": "dancer.mp4",
        "startTime": 0,
        "endTime": 10,
        "layer": 0,  // Green screen video on Layer 0 (top)
        "path": "Videos/dancer.mp4"
      },
      {
        "id": "shader_1",
        "type": "shader",
        "name": "fractal.glsl",
        "startTime": 0,
        "endTime": 10,
        "layer": 1,  // Shader on Layer 1 (bottom)
        "path": "Shaders/fractal.glsl"
      },
      {
        "id": "transition_1",
        "type": "transition",
        "name": "Circle",
        "startTime": 10,
        "endTime": 11.6,
        "layer": 1,  // Transition on Layer 1
        "path": "Transitions/Circle.glsl"
      }
    ]
  }
}
```

## Backward Compatibility

### Breaking Change
⚠️ **This is a breaking change for existing projects**

- Old manifests with shaders on layer 0 and videos on layer 1 will render incorrectly
- Users need to re-create timelines or manually edit manifest JSON files

### Migration Path
If you have existing `temp_render_manifest.json` files:

1. **Option 1**: Re-create the timeline in the web interface
2. **Option 2**: Manually edit the JSON:
   - Change all shader/transition elements from `"layer": 0` to `"layer": 1`
   - Change all video elements from `"layer": 1` to `"layer": 0`

## Testing Checklist

- [x] Web interface shows correct layer labels
- [x] Drag & drop validation works correctly
- [x] Shaders only drop to layer 1
- [x] Videos only drop to layer 0
- [x] Rendering pipeline processes layers in correct order
- [x] FFmpeg compositing places green screen on top
- [x] Chroma key removes green correctly
- [x] Empty layer 0 skips green screen processing
- [x] Transitions work correctly on layer 1
- [x] Log messages show correct layer numbers

## Benefits

### User Experience
✅ **Intuitive Layer Ordering**: Top layer in timeline = top layer in video
✅ **Clear Visual Hierarchy**: Easy to understand which layer is on top
✅ **Consistent with Industry Standards**: Most video editors use top-to-bottom layer ordering

### Technical Benefits
✅ **Correct Chroma Key Application**: Green screen properly overlays shaders
✅ **Performance**: Skip green screen processing when layer 0 is empty
✅ **Maintainability**: Code comments and variable names match visual behavior

### Rendering Quality
✅ **Proper Transparency**: Chroma key creates transparent areas showing shader beneath
✅ **No Visual Artifacts**: Correct layer ordering prevents compositing issues
✅ **Flexible Composition**: Easy to add more layers in the future

## Future Enhancements

### Potential Improvements
1. **Layer 2+**: Add support for additional general-purpose layers
2. **Layer Blending Modes**: Add blend modes (multiply, screen, overlay, etc.)
3. **Layer Opacity**: Per-layer opacity control
4. **Layer Effects**: Apply effects to entire layers (blur, color correction, etc.)
5. **Migration Tool**: Automatic conversion of old manifests to new format

---

**Status**: ✅ **COMPLETE** - Layer swap implemented and tested
**Date**: 2025-10-03
**Breaking Change**: Yes - requires timeline recreation for existing projects

