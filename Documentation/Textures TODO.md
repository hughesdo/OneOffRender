# Custom Texture Support Implementation TODO

## Overview

This document outlines the plan to implement custom texture loading and binding in OneOffRender. This will enable shaders that require image textures (3D textures, environment maps, noise textures, etc.) beyond the audio FFT data, while preserving `iChannel0` exclusively for audio reactivity.

## Current Status

### What Works Now ✅
- Single-pass and multi-pass (buffer) shader rendering
- Audio texture on `iChannel0` (512x256 FFT data) - **ALWAYS RESERVED**
- Buffer outputs on `iChannel1+` (for shaders with buffers)
- Metadata field `"texture": null` exists but is unused
- ModernGL texture creation infrastructure (used for audio and buffers)

### What's Missing ❌
- Custom texture loading from image files
- Texture detection and parsing from metadata.json
- Texture binding to shader channels (`iChannel1+`)
- Channel allocation logic (avoiding conflicts between buffers and textures)
- `Textures/` folder and organization
- Texture caching and memory management

## Why This Matters

Many Shadertoy shaders require custom textures for:
- **3D Texture Mapping** - Applying images to raymarched surfaces
- **Environment Maps** - Reflections and lighting (cubemaps, HDR images)
- **Noise Textures** - Procedural patterns and randomness
- **Lookup Tables (LUTs)** - Color grading and transformations
- **Normal Maps** - Surface detail without geometry

**Example:** "SIG15 EntryLevel" uses two textures:
1. `iChannel1` - 3D texture for surface mapping
2. `iChannel2` - Environment map for reflections

## Core Principle: Never Touch iChannel0

**CRITICAL RULE:** `iChannel0` is **ALWAYS** reserved for audio FFT data. Custom textures use `iChannel1`, `iChannel2`, `iChannel3`, `iChannel4` only.

### Channel Allocation Priority
```
iChannel0: Audio (ALWAYS - never reassign)
iChannel1-4: Buffers first (if present), then custom textures
```

## Folder Structure

```
OneOffRender/
├── Textures/                          ← NEW FOLDER
│   ├── Abstract 1.jpg                 ← 3D textures
│   ├── Uffizi Gallery Blurred.png    ← Environment maps
│   ├── Noise_256x256.png             ← Noise textures
│   ├── ColorLUT.png                  ← Lookup tables
│   └── ... (other texture files)
├── Shaders/
│   ├── SIG15 EntryLevel.glsl         ← Shaders using textures
│   └── metadata.json                  ← Texture references
```

## Metadata Schema Evolution

### Phase 1: Simple Single Texture (Immediate Implementation)

```json
{
  "name": "MyShader.glsl",
  "preview_image": "MyShader.JPG",
  "stars": 3,
  "buffer": null,
  "texture": "Abstract 1.jpg",
  "description": "Shader with 3D texture mapping",
  "audio_reactive": false
}
```

**Behavior:** Loads `Textures/Abstract 1.jpg` and binds to `iChannel1`

### Phase 2: Multiple Textures with Channel Mapping

```json
{
  "name": "SIG15 EntryLevel.glsl",
  "preview_image": null,
  "stars": 3,
  "buffer": null,
  "texture": {
    "iChannel1": "Abstract 1.jpg",
    "iChannel2": "Uffizi Gallery Blurred.png"
  },
  "description": "Raymarched tunnel with 3D texture and environment map",
  "audio_reactive": false
}
```

**Behavior:** 
- `iChannel0` = Audio (always)
- `iChannel1` = `Textures/Abstract 1.jpg`
- `iChannel2` = `Textures/Uffizi Gallery Blurred.png`

### Phase 3: Advanced Configuration (Texture Parameters)

```json
{
  "name": "AdvancedShader.glsl",
  "texture": {
    "iChannel1": {
      "file": "Abstract 1.jpg",
      "filter": "linear",
      "wrap": "repeat",
      "mipmap": true
    },
    "iChannel2": {
      "file": "Uffizi Gallery Blurred.png",
      "filter": "linear",
      "wrap": "clamp",
      "mipmap": false
    }
  }
}
```

**Parameters:**
- `filter`: `"linear"` (smooth) or `"nearest"` (pixelated)
- `wrap`: `"repeat"`, `"clamp"`, or `"mirror"`
- `mipmap`: `true` (better quality, more memory) or `false`

## Channel Allocation Strategy

The system must intelligently allocate channels based on what's present:

| Scenario | iChannel0 | iChannel1 | iChannel2 | iChannel3 | iChannel4 |
|----------|-----------|-----------|-----------|-----------|-----------|
| **Audio only** | Audio | - | - | - | - |
| **Audio + 1 texture** | Audio | Texture1 | - | - | - |
| **Audio + 2 textures** | Audio | Texture1 | Texture2 | - | - |
| **Audio + Buffer A** | Audio | Buffer A | - | - | - |
| **Audio + Buffer A + 1 texture** | Audio | Buffer A | Texture1 | - | - |
| **Audio + Buffer A + 2 textures** | Audio | Buffer A | Texture1 | Texture2 | - |
| **Audio + Buffers A,B + 1 texture** | Audio | Buffer A | Buffer B | Texture1 | - |
| **Audio + Buffers A,B + 2 textures** | Audio | Buffer A | Buffer B | Texture1 | Texture2 |

**Key Rules:**
1. `iChannel0` is **ALWAYS** audio (never reassigned)
2. Buffers take priority over textures (buffers fill `iChannel1+` first)
3. Textures fill remaining channels after buffers
4. Warn if texture requests a channel already used by a buffer

## Implementation Plan

### Phase 1: Texture Loading System ⏳

**Goal:** Load image files as ModernGL textures

**New Method in `render_shader.py`:**
```python
def load_texture_from_file(self, texture_path, filter_mode='linear', 
                          wrap_mode='repeat', mipmap=False):
    """
    Load an image file as a ModernGL texture.
    
    Args:
        texture_path: Path to image file (jpg, png, etc.)
        filter_mode: 'linear' or 'nearest'
        wrap_mode: 'repeat', 'clamp', or 'mirror'
        mipmap: Whether to generate mipmaps
        
    Returns:
        ModernGL texture object or None on failure
    """
    from PIL import Image
    import numpy as np
    
    # Load image
    img = Image.open(texture_path).convert('RGB')
    img_data = np.flipud(np.array(img, dtype=np.uint8))
    
    # Create texture
    texture = self.ctx.texture(img.size, 3, img_data.tobytes())
    
    # Set filtering
    texture.filter = (self.ctx.LINEAR if filter_mode == 'linear' 
                     else self.ctx.NEAREST, 
                     self.ctx.LINEAR if filter_mode == 'linear' 
                     else self.ctx.NEAREST)
    
    # Set wrapping
    if wrap_mode == 'repeat':
        texture.repeat_x = True
        texture.repeat_y = True
    elif wrap_mode == 'clamp':
        texture.repeat_x = False
        texture.repeat_y = False
    
    # Generate mipmaps
    if mipmap:
        texture.build_mipmaps()
    
    return texture
```

**Dependencies:**
- PIL (Pillow) - Already used in the project
- NumPy - Already used in the project

### Phase 2: Texture Detection & Loading ⏳

**Goal:** Parse metadata and load textures during shader compilation

**New Method in `render_shader.py`:**
```python
def detect_and_load_textures(self, shader_path, metadata=None):
    """
    Detect and load texture files for a shader from metadata.
    
    Returns:
        Dict mapping channel names to texture objects
        Example: {'iChannel1': texture_obj, 'iChannel2': texture_obj}
    """
    textures = {}
    
    if not metadata or not metadata.get('texture'):
        return textures
    
    texture_config = metadata['texture']
    textures_dir = Path("Textures")
    
    # Phase 1: Simple string (single texture)
    if isinstance(texture_config, str):
        texture_file = textures_dir / texture_config
        if texture_file.exists():
            texture = self.load_texture_from_file(texture_file)
            if texture:
                textures['iChannel1'] = texture
    
    # Phase 2: Dict mapping channels to filenames
    elif isinstance(texture_config, dict):
        for channel, config in texture_config.items():
            if isinstance(config, str):
                # Simple filename
                texture_file = textures_dir / config
            elif isinstance(config, dict):
                # Advanced config with parameters
                texture_file = textures_dir / config['file']
                filter_mode = config.get('filter', 'linear')
                wrap_mode = config.get('wrap', 'repeat')
                mipmap = config.get('mipmap', False)
            
            if texture_file.exists():
                texture = self.load_texture_from_file(texture_file, ...)
                if texture:
                    textures[channel] = texture
    
    return textures
```

**Update `precompile_shaders()` method:**
```python
# After buffer detection and compilation
textures = self.detect_and_load_textures(shader_file, shader_metadata)

compiled_shaders[shader_file.name] = {
    'program': program,
    'path': shader_file,
    'buffers': buffers,
    'textures': textures  # NEW
}
```

### Phase 3: Texture Binding in Rendering Pipeline ⏳

**Goal:** Bind textures to shader channels during rendering

**Update `render_shader_frame_with_buffers()` in `render_shader.py`:**

```python
# After binding audio to iChannel0
audio_texture.use(location=0)
if 'iChannel0' in program:
    program['iChannel0'].value = 0

# Bind buffer outputs to iChannel1, iChannel2, etc.
channel = 1
for buffer_id in ['A', 'B', 'C', 'D']:
    if buffer_id in shader_data.get('buffers', {}):
        shader_data['buffers'][buffer_id]['texture_current'].use(location=channel)
        if f'iChannel{channel}' in program:
            program[f'iChannel{channel}'].value = channel
        channel += 1

# NEW: Bind custom textures to remaining channels
textures = shader_data.get('textures', {})
for texture_channel in sorted(textures.keys()):
    if texture_channel.startswith('iChannel'):
        requested_channel = int(texture_channel.replace('iChannel', ''))

        # Only bind if channel isn't already used by buffers
        if requested_channel >= channel:
            textures[texture_channel].use(location=requested_channel)
            if texture_channel in program:
                program[texture_channel].value = requested_channel
        else:
            self.logger.warning(
                f"Channel conflict: {texture_channel} already used by buffer"
            )
```

**Also update:**
- `render_shader_frame()` - For single-pass shaders without buffers
- `render_single_shader_video()` - For oneoff.py rendering
- Similar methods in `render_timeline.py`

### Phase 4: Timeline & Multi-Shader Support ⏳

**Goal:** Support textures in timeline rendering and multi-shader mode

**Files to Update:**
- `render_timeline.py` - Add same texture loading/binding logic
- Handle texture cleanup when switching between shaders
- Implement texture caching to avoid reloading same textures

## Example: Converting SIG15 EntryLevel

### Original Shadertoy Code (Lines 73-79, 115):
```glsl
vec3 _texture(vec3 p)
{
    vec3 ta = texture(iChannel0, vec2(p.y,p.z)).xyz;  // ❌ Wrong channel
    vec3 tb = texture(iChannel0, vec2(p.x,p.z)).xyz;  // ❌ Wrong channel
    vec3 tc = texture(iChannel0, vec2(p.x,p.y)).xyz;  // ❌ Wrong channel
    return (ta + tb + tc) / 3.0;
}

// Later in mainImage:
diff += texture(iChannel1, ref).xyz;  // ❌ Wrong channel
```

### Fixed OneOffRender Code:
```glsl
#version 330 core

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0;  // Audio (NEVER TOUCH)
uniform sampler2D iChannel1;  // Abstract 1.jpg (3D texture)
uniform sampler2D iChannel2;  // Uffizi Gallery Blurred.png (environment)

out vec4 fragColor;

vec3 _texture(vec3 p)
{
    vec3 ta = texture(iChannel1, vec2(p.y,p.z)).xyz;  // ✅ Custom texture
    vec3 tb = texture(iChannel1, vec2(p.x,p.z)).xyz;  // ✅ Custom texture
    vec3 tc = texture(iChannel1, vec2(p.x,p.y)).xyz;  // ✅ Custom texture
    return (ta + tb + tc) / 3.0;
}

void main() {
    vec2 fragCoord = gl_FragCoord.xy;
    // ... raymarching code ...

    diff += _texture(w);
    diff += texture(iChannel2, ref).xyz;  // ✅ Environment map

    // ... rest of shader ...
    fragColor = vec4(sqrt(fc), 1.0);
}
```

### Updated metadata.json Entry:
```json
{
  "name": "SIG15 EntryLevel.glsl",
  "preview_image": null,
  "stars": 3,
  "buffer": null,
  "texture": {
    "iChannel1": "Abstract 1.jpg",
    "iChannel2": "Uffizi Gallery Blurred.png"
  },
  "description": "Raymarched tunnel with 3D texture mapping and environment reflections",
  "audio_reactive": false
}
```

### Required Files:
```
Textures/
├── Abstract 1.jpg                 ← 3D texture for surface mapping
└── Uffizi Gallery Blurred.png    ← Environment map for reflections
```

## Performance Considerations

### Texture Loading Time
- **Small textures (512x512):** ~50-100ms per texture
- **Medium textures (1024x1024):** ~100-200ms per texture
- **Large textures (2048x2048):** ~200-500ms per texture
- **4K textures (4096x4096):** ~500-1000ms per texture

**Impact:** Adds to shader compilation time, but only happens once at startup.

### GPU Memory Usage
- **512x512 RGB:** ~0.75 MB
- **1024x1024 RGB:** ~3 MB
- **2048x2048 RGB:** ~12 MB
- **4096x4096 RGB:** ~48 MB
- **With mipmaps:** +33% memory (e.g., 1024x1024 = ~4 MB)

**Recommendation:** Use compressed formats (JPG) for large textures, PNG for textures requiring transparency.

### Runtime Performance
- ✅ **No impact** - Textures are GPU-resident, sampling is hardware-accelerated
- ✅ Mipmaps improve quality and can improve performance (better cache coherency)

## Texture Caching Strategy

### Problem
Loading the same texture multiple times wastes memory and startup time.

### Solution: Global Texture Cache
```python
class ShaderRenderer:
    def __init__(self, config_path):
        # ... existing init ...
        self.texture_cache = {}  # NEW: Cache loaded textures

    def load_texture_from_file(self, texture_path, ...):
        # Check cache first
        cache_key = (str(texture_path), filter_mode, wrap_mode, mipmap)
        if cache_key in self.texture_cache:
            self.logger.debug(f"Using cached texture: {texture_path.name}")
            return self.texture_cache[cache_key]

        # Load texture
        texture = ... # existing loading code

        # Store in cache
        self.texture_cache[cache_key] = texture
        return texture

    def cleanup_textures(self):
        """Release all cached textures."""
        for texture in self.texture_cache.values():
            texture.release()
        self.texture_cache.clear()
```

## Supported Image Formats

PIL (Pillow) supports:
- ✅ **JPG/JPEG** - Best for photos, environment maps (lossy compression)
- ✅ **PNG** - Best for textures with transparency, sharp edges (lossless)
- ✅ **BMP** - Uncompressed (large files, fast loading)
- ✅ **TGA** - Common in game development
- ✅ **TIFF** - High-quality, supports 16-bit (large files)
- ✅ **WebP** - Modern format, good compression

**Recommendation:** Use JPG for large textures, PNG for small textures or those requiring transparency.

## Error Handling

### Missing Texture Files
```python
if not texture_file.exists():
    self.logger.warning(f"Texture file not found: {texture_file}")
    # Option 1: Create placeholder texture (solid color)
    # Option 2: Skip texture binding (shader may fail)
    # Option 3: Fail shader compilation
```

**Recommendation:** Create a 1x1 magenta placeholder texture to make missing textures obvious.

### Channel Conflicts
```python
if requested_channel < channel:
    self.logger.error(
        f"Channel conflict: {texture_channel} requested but already "
        f"used by buffer. Buffers occupy iChannel1-{channel-1}."
    )
    # Skip binding this texture
```

### Shader Compilation Errors
If shader expects a texture that isn't bound, ModernGL will:
- Issue a warning about unused uniform
- Shader may render black or incorrectly

**Solution:** Validate that all `uniform sampler2D iChannelX` declarations have corresponding textures.

## Testing Strategy

### Test Cases

1. **Single Texture:**
   - Create shader using one custom texture on `iChannel1`
   - Verify texture loads and binds correctly
   - Test: Display texture directly

2. **Multiple Textures:**
   - Create shader using two textures (`iChannel1`, `iChannel2`)
   - Verify both load and bind correctly
   - Test: SIG15 EntryLevel shader

3. **Textures + Audio:**
   - Verify `iChannel0` remains audio
   - Verify textures don't interfere with audio reactivity
   - Test: Audio-reactive shader with texture overlay

4. **Textures + Buffers:**
   - Create shader with Buffer A and one texture
   - Verify buffer gets `iChannel1`, texture gets `iChannel2`
   - Test: Buffer feedback with texture mapping

5. **Texture Parameters:**
   - Test different filter modes (linear vs nearest)
   - Test different wrap modes (repeat vs clamp)
   - Test mipmaps (quality improvement)

6. **Missing Textures:**
   - Reference non-existent texture in metadata
   - Verify graceful error handling
   - Test: Placeholder texture or skip

7. **Large Textures:**
   - Load 4K texture (4096x4096)
   - Monitor memory usage
   - Verify no performance degradation

## Files to Modify

### Core Rendering
- ✅ `render_shader.py` - Add texture loading, detection, and binding
- ✅ `render_timeline.py` - Add same texture support for timeline rendering

### Folder Structure
- ✅ Create `Textures/` folder in project root
- ✅ Add example textures for testing

### Documentation
- ✅ `Documentation/README - New Shader Addition.md` - Add texture instructions
- ✅ `Shaders/metadata.json` - Update entries with texture references
- ✅ This file (`Textures TODO.md`) - Implementation guide

## Implementation Checklist

### Phase 1: Basic Single Texture Support
- [ ] Create `Textures/` folder
- [ ] Add `load_texture_from_file()` method to `render_shader.py`
- [ ] Add `detect_and_load_textures()` method to `render_shader.py`
- [ ] Update `precompile_shaders()` to load textures
- [ ] Update `render_shader_frame()` to bind textures (single-pass)
- [ ] Update `render_shader_frame_with_buffers()` to bind textures (multi-pass)
- [ ] Update `render_single_shader_video()` to bind textures (oneoff.py)
- [ ] Test with simple single-texture shader

### Phase 2: Multiple Textures
- [ ] Support dict format in metadata for multiple textures
- [ ] Implement channel conflict detection (buffers vs textures)
- [ ] Add logging for texture binding
- [ ] Test with SIG15 EntryLevel (2 textures)

### Phase 3: Advanced Features
- [ ] Add texture parameter support (filter, wrap, mipmap)
- [ ] Implement texture caching (reuse across frames)
- [ ] Add texture memory management
- [ ] Create placeholder texture for missing files
- [ ] Support for different image formats

### Phase 4: Timeline & Multi-Shader Support
- [ ] Add same texture support to `render_timeline.py`
- [ ] Handle texture loading in multi-shader renders
- [ ] Implement texture cleanup between shader switches
- [ ] Test texture caching across multiple shaders

### Phase 5: Web Interface Integration
- [ ] Display texture info in shader list (web editor)
- [ ] Add texture badge to shader thumbnails
- [ ] Show texture file names in shader details
- [ ] Add texture upload functionality (future)

## Priority & Timeline

**Status:** Planning phase - not yet implemented
**Priority:** Medium-High - enables many Shadertoy shaders
**Complexity:** Medium - requires texture loading and channel management
**Estimated Effort:** 9-14 hours of development + testing

### Milestones

- [ ] **Week 1:** Phase 1 - Basic single texture support (3-4 hours)
- [ ] **Week 1:** Phase 2 - Multiple textures (1-2 hours)
- [ ] **Week 2:** Phase 3 - Advanced features (3-4 hours)
- [ ] **Week 2:** Phase 4 - Timeline support (2-3 hours)
- [ ] **Week 3:** Testing, debugging, documentation (2-4 hours)

## References

- [Shadertoy Texture Documentation](https://www.shadertoy.com/howto)
- [ModernGL Texture Documentation](https://moderngl.readthedocs.io/en/latest/reference/texture.html)
- [PIL/Pillow Documentation](https://pillow.readthedocs.io/)
- `Buffers TODO.md` - Buffer implementation (similar pattern)
- `Shaders/metadata.json` - Current metadata structure

---

## Next Steps

1. Review and approve this implementation plan
2. Create `Textures/` folder and add test textures
3. Implement Phase 1: Basic texture loading
4. Test with simple shader
5. Implement Phase 2: Multiple textures
6. Convert SIG15 EntryLevel shader as proof of concept
7. Iterate and expand to full texture support

---

**Last Updated:** 2025-10-12
**Author:** AI Assistant
**Related Documents:** `Buffers TODO.md`, `Documentation/README - New Shader Addition.md`

