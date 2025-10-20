# Shadertoy-Style Buffer Implementation TODO

## Overview

This document outlines the plan to implement Shadertoy-style multi-pass rendering with buffer feedback loops in OneOffRender. This will enable shaders like "The Four Trumpets 2" that require ping-pong buffers for trail effects and other advanced rendering techniques.

## Current Status

### What Works Now ✅
- Single-pass shader rendering
- Audio texture on `iChannel0` (512x256 FFT data)
- Shader transitions between different shaders
- Timeline-based shader sequencing
- User-selected transitions from web interface
- Metadata field `"buffer": null` exists but is unused

### What's Missing ❌
- Multi-pass rendering (buffers)
- Buffer feedback loops (reading previous frame)
- Multiple texture inputs beyond audio
- Custom channel routing
- Buffer metadata parsing and usage

## Why This Matters

Many advanced Shadertoy shaders require buffers for:
- **Feedback effects** - Reading previous frame for trails, motion blur, persistence
- **Multi-stage processing** - Separate passes for different effects
- **Temporal effects** - Accumulation over time
- **Complex pipelines** - Raymarching in one buffer, post-processing in another

**Example:** "The Four Trumpets 2" uses a ping-pong buffer to create trailing quasi-crystal patterns that accumulate and rotate over time.

## Implementation Strategy: Hybrid Approach

We'll use **both** metadata and file-based auto-discovery for maximum flexibility:

### Primary: Metadata-Driven (Fast)
Check `Shaders/metadata.json` `buffer` field first for explicit configuration

### Fallback: Auto-Discovery (Compatible)
Scan filesystem for `ShaderName.buffer.A.glsl` files if metadata is missing

### Benefits:
- ✅ Fast performance (no filesystem scans when metadata is complete)
- ✅ Backward compatibility (works without metadata updates)
- ✅ Future extensibility (can add advanced config later)
- ✅ Better UX (web editor knows about buffers immediately)

## File Naming Convention

Following Shadertoy conventions:

```
Waveform.glsl              ← Main image shader (final output)
Waveform.buffer.A.glsl     ← Buffer A (feedback loop)
Waveform.buffer.B.glsl     ← Buffer B (optional second buffer)
Waveform.buffer.C.glsl     ← Buffer C (optional third buffer)
Waveform.buffer.D.glsl     ← Buffer D (optional fourth buffer)
```

## Metadata Schema Evolution

### Phase 1: Simple Boolean (Immediate Implementation)

```json
{
  "name": "The Four Trumpets 2.glsl",
  "preview_image": "The Four Trumpets 2.JPG",
  "stars": 5,
  "buffer": true,
  "texture": null,
  "description": "Audio-reactive quasi-crystal with feedback trails",
  "audio_reactive": true
}
```

**Behavior:** Renderer auto-discovers buffer files using naming convention.

### Phase 2: File List (Medium Term)

```json
{
  "name": "Waveform.glsl",
  "buffer": {
    "enabled": true,
    "files": ["Waveform.buffer.A.glsl"]
  },
  "texture": null
}
```

**Behavior:** Explicitly lists which buffer files to load, skips auto-discovery.

### Phase 3: Full Configuration (Advanced)

```json
{
  "name": "ComplexShader.glsl",
  "buffer": {
    "enabled": true,
    "buffers": [
      {
        "id": "A",
        "file": "ComplexShader.buffer.A.glsl",
        "resolution": 1.0,
        "channels": {
          "iChannel0": {"type": "audio"},
          "iChannel1": {"type": "self", "filter": "linear", "wrap": "clamp"}
        }
      },
      {
        "id": "B",
        "file": "ComplexShader.buffer.B.glsl",
        "resolution": 0.5,
        "channels": {
          "iChannel0": {"type": "audio"},
          "iChannel1": {"type": "buffer", "id": "A"}
        }
      }
    ],
    "main_channels": {
      "iChannel0": {"type": "audio"},
      "iChannel1": {"type": "buffer", "id": "A"},
      "iChannel2": {"type": "buffer", "id": "B"}
    }
  }
}
```

**Behavior:** Complete control over buffer resolution, channel routing, and texture parameters.

## Channel Allocation Strategy

### Standard Shadertoy Convention

**For Main Image Shader:**
- `iChannel0` = Audio texture (512x256 FFT data)
- `iChannel1` = Buffer A output (current frame)
- `iChannel2` = Buffer B output (current frame)
- `iChannel3` = Buffer C output (current frame)
- `iChannel4` = Buffer D output (if needed)

**For Buffer Shaders (with feedback):**
- `iChannel0` = Audio texture
- `iChannel1` = Own previous frame (Buffer A reads Buffer A from previous frame)
- `iChannel2` = Other buffer outputs (optional)

## Implementation Plan

### Phase 1: Metadata Detection & Auto-Discovery ⏳

**Goal:** Detect buffers from metadata and filesystem

**Files to Modify:**
- `render_shader.py` - Add `detect_shader_buffers()` method
- `render_timeline.py` - Add buffer detection to `precompile_shaders()`
- `web_editor/app.py` - Parse and expose buffer info in shader list API

**New Functions:**
```python
def detect_shader_buffers(shader_path, metadata=None):
    """
    Detect buffer files for a shader using hybrid approach.
    
    Args:
        shader_path: Path to main shader file
        metadata: Optional metadata dict for this shader
        
    Returns:
        List of buffer IDs ['A', 'B', ...] or empty list
    """
    # 1. Check metadata first
    if metadata and metadata.get('buffer'):
        buffer_config = metadata['buffer']
        if isinstance(buffer_config, bool) and buffer_config:
            # Phase 1: Boolean, auto-discover files
            pass
        elif isinstance(buffer_config, dict):
            # Phase 2/3: Explicit configuration
            return buffer_config.get('files', [])
    
    # 2. Fallback: Auto-discover by file naming
    base_name = shader_path.stem
    found_buffers = []
    for buffer_id in ['A', 'B', 'C', 'D']:
        buffer_file = shader_path.parent / f"{base_name}.buffer.{buffer_id}.glsl"
        if buffer_file.exists():
            found_buffers.append(buffer_id)
    
    return found_buffers
```

**Data Structure:**
```python
compiled_shaders[element_id] = {
    'main': {
        'program': main_program,
        'element': element,
        'path': shader_path
    },
    'buffers': {
        'A': {
            'program': buffer_a_program,
            'path': buffer_a_path,
            'texture_current': None,
            'texture_previous': None,
            'fbo_current': None,
            'fbo_previous': None
        },
        # B, C, D...
    }
}
```

### Phase 2: Buffer Rendering Pipeline ⏳

**Goal:** Render buffers before main image with feedback loops

**Rendering Order Per Frame:**
1. Render Buffer A → writes to `texture_current`
2. Render Buffer B → writes to `texture_current`
3. Render Buffer C → writes to `texture_current`
4. Render Buffer D → writes to `texture_current`
5. Render Main Image → reads from all buffer `texture_current`
6. Swap buffers: `texture_current` ↔ `texture_previous` for next frame

**New Methods:**
```python
def render_shader_frame_with_buffers(shader_data, vbo, fbo, audio_data, frame_idx, frame_rate, raw_file):
    """Render a frame with multi-pass buffer support."""
    
    # 1. Render all buffer passes
    for buffer_id in ['A', 'B', 'C', 'D']:
        if buffer_id in shader_data['buffers']:
            render_buffer_pass(shader_data['buffers'][buffer_id], audio_data, frame_idx, frame_rate)
    
    # 2. Render main image using buffer outputs
    render_main_image(shader_data['main'], shader_data['buffers'], audio_data, frame_idx, frame_rate, fbo, raw_file)
    
    # 3. Swap ping-pong buffers for next frame
    for buffer_id, buffer_data in shader_data['buffers'].items():
        swap_buffer_textures(buffer_data)

def render_buffer_pass(buffer_data, audio_data, frame_idx, frame_rate):
    """Render a single buffer pass."""
    buffer_data['fbo_current'].use()
    
    # Bind audio to iChannel0
    audio_texture.use(location=0)
    buffer_data['program']['iChannel0'].value = 0
    
    # Bind previous frame to iChannel1 (feedback)
    if buffer_data['texture_previous']:
        buffer_data['texture_previous'].use(location=1)
        buffer_data['program']['iChannel1'].value = 1
    
    # Set uniforms
    buffer_data['program']['iTime'].value = frame_idx / frame_rate
    buffer_data['program']['iResolution'].value = (width, height)
    
    # Render
    buffer_vao.render()

def swap_buffer_textures(buffer_data):
    """Swap current and previous textures for ping-pong rendering."""
    buffer_data['texture_current'], buffer_data['texture_previous'] = \
        buffer_data['texture_previous'], buffer_data['texture_current']
    buffer_data['fbo_current'], buffer_data['fbo_previous'] = \
        buffer_data['fbo_previous'], buffer_data['fbo_current']
```

### Phase 3: Web Interface Integration ⏳

**Goal:** Display buffer information in web editor

**Changes to `web_editor/app.py`:**
```python
@app.route('/api/shaders/list')
def list_shaders():
    # ... existing code ...
    
    for shader in shaders:
        shader['preview_path'] = f"/api/shaders/preview/{shader['preview_image']}"
        
        # Add buffer information
        if shader.get('buffer'):
            shader['has_buffers'] = True
            shader['buffer_count'] = len(detect_shader_buffers(shader['name'], shader))
        else:
            shader['has_buffers'] = False
            shader['buffer_count'] = 0
```

**Changes to `web_editor/static/js/editor.js`:**
- Add badge to shader thumbnails showing "Multi-Pass" or "Buffers: A, B"
- Show warning tooltip about increased render time
- Add filter option to show/hide multi-pass shaders

### Phase 4: Transition Support ⏳

**Goal:** Handle transitions between multi-pass shaders

**Approach:**
1. Render "from" shader with all its buffers → output to temp texture
2. Render "to" shader with all its buffers → output to temp texture
3. Apply transition shader blending the two outputs

**Challenge:** Buffer states need to persist during transitions for smooth visual continuity.

## Performance Considerations

### Render Time Impact
- **Single-pass shader:** 1x render time
- **With 1 buffer:** 2x render time (Buffer A + Main)
- **With 2 buffers:** 3x render time (Buffer A + Buffer B + Main)
- **With 4 buffers:** 5x render time (A + B + C + D + Main)

### Memory Requirements
- Each buffer needs 2 textures (ping-pong) at full resolution
- **1920x1080 RGB:** ~6MB per texture
- **4 buffers:** 8 textures = ~48MB GPU memory
- **2560x1440 RGB:** ~11MB per texture
- **4 buffers at 1440p:** 8 textures = ~88MB GPU memory

### Optimization Strategies
1. **Lazy buffer creation:** Only create buffers when shader uses them
2. **Buffer resolution scaling:** Allow buffers to render at lower resolution (Phase 3)
3. **Buffer pooling:** Reuse textures across different shaders
4. **Conditional rendering:** Skip buffer passes if not needed

## Backward Compatibility

### Existing Shaders
- ✅ All current single-pass shaders continue to work unchanged
- ✅ No changes required to existing shader files
- ✅ System automatically detects if buffers exist
- ✅ Shaders with `"buffer": null` use fast single-pass path

### Detection Logic
```python
if shader_data.get('buffers'):
    render_shader_frame_with_buffers(...)
else:
    render_shader_frame(...)  # Current implementation
```

## Testing Strategy

### Test Cases

1. **Single Buffer Feedback:**
   - Create simple shader with Buffer A that reads previous frame
   - Verify feedback loop works correctly
   - Test: Fade trail effect

2. **Multiple Buffers:**
   - Create shader with Buffer A and Buffer B
   - Verify both buffers render in correct order
   - Test: Ping-pong effect between buffers

3. **Audio Reactivity:**
   - Verify audio texture still works on iChannel0
   - Test buffer reading audio data
   - Test main image reading audio data

4. **Transitions:**
   - Test transition between single-pass and multi-pass shader
   - Test transition between two multi-pass shaders
   - Verify buffer states persist correctly

5. **Performance:**
   - Benchmark render time with 0, 1, 2, 4 buffers
   - Monitor GPU memory usage
   - Test at different resolutions

## Files to Modify

### Core Rendering
- `render_shader.py` - Add buffer detection, compilation, and rendering
- `render_timeline.py` - Add buffer support to timeline rendering

### Web Interface
- `web_editor/app.py` - Parse and expose buffer metadata
- `web_editor/static/js/editor.js` - Display buffer badges and warnings
- `web_editor/templates/index.html` - UI elements for buffer info

### Documentation
- `Documentation/README - New Shader Addition.md` - Add buffer shader instructions
- `Shaders/metadata.json` - Update entries with buffer information

## Migration Path for Existing Shaders

### For "The Four Trumpets 2.glsl"

**Step 1:** Update metadata.json
```json
{
  "name": "The Four Trumpets 2.glsl",
  "preview_image": "The Four Trumpets 2.JPG",
  "stars": 5,
  "buffer": true,
  "texture": null,
  "description": "Audio-reactive quasi-crystal with feedback trails",
  "audio_reactive": true
}
```

**Step 2:** Split shader into files
- `The Four Trumpets 2.glsl` - Main image (display final result)
- `The Four Trumpets 2.buffer.A.glsl` - Quasi-crystal with feedback

**Step 3:** Update uniforms
- Change `uniform sampler2D feedbackTex;` → Use `iChannel1` in buffer shader
- Change `uniform sampler2D audioTex;` → Use `iChannel0`
- Change `uniform vec2 resolution;` → Use `iResolution`
- Change `uniform float time;` → Use `iTime`
- Change `out vec4 FragColor;` → Use `out vec4 fragColor;`

## Priority & Timeline

**Status:** Planning phase - not yet implemented  
**Priority:** High - enables advanced Shadertoy shaders  
**Complexity:** High - requires significant rendering pipeline changes  
**Estimated Effort:** 2-3 weeks of development + testing

### Milestones

- [ ] **Week 1:** Phase 1 - Metadata detection and auto-discovery
- [ ] **Week 2:** Phase 2 - Buffer rendering pipeline
- [ ] **Week 3:** Phase 3 - Web interface integration + testing
- [ ] **Future:** Phase 4 - Transition support for multi-pass shaders

## References

- [Shadertoy Buffers Documentation](https://www.shadertoy.com/howto)
- `Documentation/Buffers todo.md` - Original detailed planning document
- `Shaders/metadata.json` - Current metadata structure
- `render_shader.py` - Current single-pass rendering implementation

---

**Next Steps:**
1. Review and approve this implementation plan
2. Create feature branch: `feature/buffer-support`
3. Implement Phase 1: Metadata detection
4. Test with "The Four Trumpets 2" shader
5. Iterate and expand to full buffer support

