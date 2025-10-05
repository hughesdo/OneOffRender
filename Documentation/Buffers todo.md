# Multi-Pass Buffer Rendering - TODO

## Overview

This document outlines the plan to implement Shadertoy-style multi-pass rendering with buffer feedback loops in the OneOffRender system.

## Current System Status

### What Works Now
- ✅ Single-pass shader rendering
- ✅ Audio texture on `iChannel0` (512x256 FFT data)
- ✅ Shader transitions between different shaders
- ✅ Timeline-based shader sequencing
- ✅ User-selected transitions from web interface

### What's Missing
- ❌ Multi-pass rendering (buffers)
- ❌ Buffer feedback loops (reading previous frame)
- ❌ Multiple texture inputs beyond audio
- ❌ Custom channel routing

## Proposed File Naming Convention

Following Shadertoy conventions:

```
Waveform.glsl              ← Main image shader (final output)
Waveform.buffer.A.glsl     ← Buffer A (feedback loop)
Waveform.buffer.B.glsl     ← Buffer B (optional second buffer)
Waveform.buffer.C.glsl     ← Buffer C (optional third buffer)
Waveform.buffer.D.glsl     ← Buffer D (optional fourth buffer)
```

### Example Use Case

**Waveform Shader with Buffer A:**

**Main Image (`Waveform.glsl`):**
```glsl
void mainImage(out vec4 O, vec2 I)
{
    vec2 r = iResolution.xy;
    // Read from Buffer A (iChannel1) and audio (iChannel0)
    O = (I.y-=r.y/6e2)>1.?texture(iChannel1,I/r):texture(iChannel0,I/r);
}
```

**Buffer A (`Waveform.buffer.A.glsl`):**
```glsl
void mainImage(out vec4 O, vec2 I)
{
    // Raymarch with audio reactivity
    // Uses iChannel0 for audio, iChannel1 for previous frame feedback
    float i, d, z, r;
    for(O*= i; i++<9e1; O += (cos(z*.5+iTime+vec4(0,2,4,3))+1.3)/d/z)
    {
        vec3 R = iResolution.xyy,
         p = z * normalize(vec3(I+I,0) - R);
        r = max(-++p, 0.).y;
        p.y += r+r-4.*texture(iChannel0, vec2((p.x+6.5)/15.,(-p.z-3.)*5e1/R.y)).r;
        z += d = .1*(.1*r+abs(p.y)/(1.+r+r+r*r) + max(d=p.z+3.,-d*.1));
    }
    O = tanh(O/9e2);
}
```

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
- etc.

## Implementation Plan

### Phase 1: Auto-Discovery System

**Goal:** Automatically detect and load buffer files by naming convention

**Changes Required:**

1. **`precompile_shaders()` in `render_timeline.py`:**
   - Detect if `ShaderName.buffer.A.glsl` exists alongside `ShaderName.glsl`
   - Load and compile all buffer shaders
   - Store buffer programs with main shader

2. **Data Structure:**
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
            'texture_current': None,  # Current frame output
            'texture_previous': None, # Previous frame (for feedback)
            'fbo_current': None,
            'fbo_previous': None
        },
        'B': { ... },
        # etc.
    }
}
```

### Phase 2: Buffer Rendering Pipeline

**Goal:** Render buffers before main image, with feedback loops

**Rendering Order Per Frame:**
1. Render Buffer A → writes to `texture_current`
2. Render Buffer B → writes to `texture_current`
3. Render Buffer C → writes to `texture_current`
4. Render Buffer D → writes to `texture_current`
5. Render Main Image → reads from all buffer `texture_current`
6. Swap buffers: `texture_current` → `texture_previous` for next frame

**Changes Required:**

1. **New method: `render_shader_frame_with_buffers()`**
   - Replace current `render_shader_frame()` for multi-pass shaders
   - Implement buffer rendering loop
   - Handle texture binding for each pass

2. **Ping-Pong Buffer Management:**
   - Create two textures per buffer (current + previous)
   - Swap after each frame
   - Or use `texture.copy()` to save previous frame

### Phase 3: Texture Binding Logic

**Goal:** Correctly bind textures to shader channels

**For Buffer Shaders:**
```python
def render_buffer_pass(buffer_id, buffer_data, audio_texture):
    buffer_data['fbo_current'].use()

    # Bind audio to iChannel0
    audio_texture.use(location=0)
    if 'iChannel0' in buffer_data['program']:
        buffer_data['program']['iChannel0'].value = 0

    # Bind previous frame to iChannel1 (feedback)
    if buffer_data['texture_previous']:
        buffer_data['texture_previous'].use(location=1)
        if 'iChannel1' in buffer_data['program']:
            buffer_data['program']['iChannel1'].value = 1

    # Set uniforms
    buffer_data['program']['iTime'].value = time_seconds
    buffer_data['program']['iResolution'].value = (width, height)

    # Render
    buffer_vao.render()
```

**For Main Image:**
```python
def render_main_image(shader_data, audio_texture):
    fbo.use()

    # Bind audio to iChannel0
    audio_texture.use(location=0)
    shader_data['main']['program']['iChannel0'].value = 0

    # Bind buffer outputs to iChannel1, iChannel2, etc.
    channel = 1
    for buffer_id in ['A', 'B', 'C', 'D']:
        if buffer_id in shader_data['buffers']:
            buffer_data['buffers'][buffer_id]['texture_current'].use(location=channel)
            shader_data['main']['program'][f'iChannel{channel}'].value = channel
            channel += 1

    # Set uniforms and render
    main_vao.render()
```

### Phase 4: Transition Support

**Goal:** Handle transitions between multi-pass shaders

**Challenges:**
- Transition shader needs outputs from both "from" and "to" shader buffers
- May need to render both shader pipelines during transition

**Approach:**
1. Render "from" shader with all its buffers → output to temp texture
2. Render "to" shader with all its buffers → output to temp texture
3. Apply transition shader blending the two outputs

### Phase 5: JSON Metadata (Optional)

**Goal:** Support advanced configurations beyond auto-discovery

**Use Cases:**
- Custom channel routing
- External texture files (images, videos)
- Buffer resolution overrides
- Filter/wrap mode settings

**Example Metadata:**
```json
{
  "Waveform.glsl": {
    "name": "Waveform",
    "description": "Audio-reactive waveform with feedback",
    "buffers": [
      {
        "id": "A",
        "file": "Waveform.buffer.A.glsl",
        "resolution": "full",
        "inputs": [
          {"channel": 0, "type": "audio"},
          {"channel": 1, "type": "buffer", "id": "A", "filter": "linear", "wrap": "clamp"}
        ]
      }
    ],
    "main_inputs": [
      {"channel": 0, "type": "audio"},
      {"channel": 1, "type": "buffer", "id": "A"}
    ]
  }
}
```

### Phase 6: Web Interface Support

**Goal:** Allow users to upload and manage multi-pass shaders

**Features:**
- Upload multiple files as a "shader package"
- Visual indicator for multi-pass shaders
- Preview showing buffer outputs
- Drag-and-drop for shader packages

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
1. **Buffer resolution scaling:** Allow buffers to render at lower resolution
2. **Lazy buffer creation:** Only create buffers when shader uses them
3. **Buffer pooling:** Reuse textures across different shaders
4. **Conditional rendering:** Skip buffer passes if not needed

## Backward Compatibility

### Existing Shaders
- ✅ All current single-pass shaders continue to work unchanged
- ✅ No changes required to existing shader files
- ✅ System automatically detects if buffers exist

### Detection Logic
```python
def has_buffers(shader_path):
    base_name = shader_path.stem
    for buffer_id in ['A', 'B', 'C', 'D']:
        buffer_file = shader_path.parent / f"{base_name}.buffer.{buffer_id}.glsl"
        if buffer_file.exists():
            return True
    return False

# Use appropriate rendering path
if has_buffers(shader_path):
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

### Core Rendering (`render_timeline.py`)
- `precompile_shaders()` - Add buffer detection and compilation
- `render_shader_frame()` - Add multi-pass support or create new method
- Add `render_buffer_pass()` method
- Add `swap_buffer_textures()` method
- Add buffer texture/FBO creation in initialization

### Shader Loader (`render_shader.py`)
- Similar changes for standalone shader rendering
- Ensure consistency with timeline rendering

### Web Interface (`web_editor/app.py`)
- Add support for uploading shader packages
- Detect multi-pass shaders in shader list
- Display buffer information in UI

### Web Interface Frontend (`web_editor/static/js/editor.js`)
- Visual indicator for multi-pass shaders
- Handle shader package uploads
- Show buffer preview (optional)

## Future Extensions

### Texture Inputs
- Support external image files: `ShaderName.texture.0.png`
- Support video files: `ShaderName.texture.1.mp4`
- Naming convention: `ShaderName.texture.{channel}.{ext}`

### Cubemap Support
- Support cubemap textures for environment mapping
- Naming: `ShaderName.cubemap.0.{face}.png`

### 3D Textures
- Support volumetric textures
- Naming: `ShaderName.texture3d.0.raw`

### Buffer Resolution Control
- Allow buffers to render at different resolutions
- Useful for performance optimization
- Example: Half-res buffer for blur effects

## References

### Shadertoy Documentation
- [Shadertoy Buffers](https://www.shadertoy.com/howto)
- Multi-pass rendering examples
- Channel binding conventions

### Current System
- `render_timeline.py` - Main timeline rendering
- `render_shader.py` - Single shader rendering
- `Transitions/` - Transition shader examples
- `Shaders/` - Current single-pass shaders

## Notes

- This is a significant architectural change
- Requires careful testing to avoid breaking existing functionality
- Performance impact should be documented and communicated to users
- Consider adding a "complexity indicator" in web UI (single-pass vs multi-pass)
- May want to add render time estimates based on buffer count

## Questions to Resolve

1. **Buffer persistence across shader switches:**
   - Should buffers reset when switching shaders in timeline?
   - Or maintain state for smooth transitions?

2. **Transition handling:**
   - How to handle buffer states during transitions?
   - Render both shader pipelines simultaneously?

3. **Memory management:**
   - When to release buffer textures?
   - Pool textures across shaders?

4. **Error handling:**
   - What if buffer shader fails to compile?
   - Fallback to single-pass rendering?

5. **Web interface:**
   - How to upload multi-file shader packages?
   - ZIP file upload?
   - Multiple file selection?

---

**Status:** Planning phase - not yet implemented
**Priority:** Medium - nice to have for advanced shaders
**Complexity:** High - requires significant rendering pipeline changes
**Estimated Effort:** 2-3 weeks of development + testing

