# New Shader Addition Guide for OneOffRender

## Overview

This guide provides step-by-step instructions for adding new shaders from Shadertoy to the OneOffRender application. The process involves converting Shadertoy-compatible GLSL code to OneOffRender's format, updating metadata, and testing functionality.

---

## File Requirements

Before starting, ensure you have these files:

### Required Files:
1. **Shader Source**: `./Shaders/[ShaderName].glsl` - The GLSL shader code
2. **Preview Image**: `./Shaders/[ShaderName].jpg` or `.JPG` - Visual preview (case-sensitive)
3. **Metadata Entry**: Entry in `./Shaders/metadata.json` - Shader information and settings

### File Naming:
- Shader filename and metadata `name` field must match exactly (case-sensitive)
- Preview image filename and metadata `preview_image` field must match exactly
- Use consistent naming: spaces are allowed, avoid special characters

---

## Step 1: Convert Shadertoy to OneOffRender Format

### 1.1 Add GLSL Version and Uniforms

**Add at the top of the shader file:**
```glsl
#version 330 core

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0;  // Audio texture (for audio-reactive shaders)

out vec4 fragColor;
```

### 1.2 Convert Main Function

**Replace Shadertoy format:**
```glsl
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    // shader code
}
```

**With OneOffRender format:**
```glsl
void main() {
    vec2 fragCoord = gl_FragCoord.xy;
    // Fix Y-coordinate flip for OneOffRender compatibility
    fragCoord.y = iResolution.y - fragCoord.y;
    
    // shader code
    
    fragColor = finalColor; // Set output color
}
```

### 1.3 Y-Coordinate Flip (Critical!)

OneOffRender uses a different coordinate system than Shadertoy. **Always add this line** after getting fragCoord:

```glsl
fragCoord.y = iResolution.y - fragCoord.y;
```

**Why this is needed:**
- Shadertoy: Y=0 at bottom, Y=max at top
- OneOffRender: Y=0 at top, Y=max at bottom
- Without this fix, shaders render upside-down

### 1.4 Audio Texture Integration (Audio-Reactive Shaders)

OneOffRender uses a 512×256 audio texture with this format:
- **Rows 0-1**: FFT spectrum data
- **Rows 2-4**: Guard band (prevents linear filtering artifacts)
- **Rows 5-255**: Waveform data

**Safe audio sampling:**
```glsl
// Sample spectrum (frequency domain)
float bass = texture(iChannel0, vec2(0.1, 0.0)).r;    // Low frequencies
float treble = texture(iChannel0, vec2(0.9, 0.0)).r;  // High frequencies

// Sample waveform (time domain) - use y=0.5 for center of waveform band
float waveform = texture(iChannel0, vec2(x_position, 0.5)).r;
```

### 1.5 Remove Unsupported Uniforms

Remove or replace these Shadertoy uniforms:
- `iMouse` - Mouse interaction (not supported)
- `iDate` - Date/time (not supported)
- `iChannelResolution` - Texture resolution (not needed)
- `iChannel1`, `iChannel2`, `iChannel3` - Additional textures (not supported)

---

## Step 2: Update Metadata

Add an entry to `./Shaders/metadata.json`:

### Example Entry:
```json
{
  "name": "Xor Mashup 001.glsl",
  "preview_image": "Xor Mashup 001.JPG",
  "stars": 3,
  "buffer": null,
  "texture": null,
  "description": "Audio-reactive molten heart with speak overlay. Combines techno god background with dynamic overlay effects, bass controls radius and ring width, treble affects color shifts.",
  "audio_reactive": true
}
```

### Field Descriptions:
- **name**: Exact shader filename (case-sensitive)
- **preview_image**: Exact image filename (case-sensitive, check .jpg vs .JPG)
- **stars**: Initial rating 1-5 (use 3 as default)
- **buffer**: Set to `null` (unless multi-pass rendering)
- **texture**: Set to `null` (unless external textures required)
- **description**: 1-2 sentence description of visual effect and audio reactivity
- **audio_reactive**: `true` if uses `iChannel0`, `false` otherwise

### JSON Syntax:
- Ensure valid JSON (no trailing commas)
- Add comma after previous entry
- Use double quotes for all strings
- Boolean values: `true`/`false` (no quotes)

---

## Step 3: Test Shaders

### 3.1 Test with oneoff.py

Test each shader for 5 seconds to verify functionality:

```bash
# Test the shader
python oneoff.py "ShaderName.glsl" 5

# Example
python oneoff.py "Xor Mashup 001.glsl" 5
```

### 3.2 Success Criteria

✅ **Shader compiles without errors**
✅ **Video renders successfully to `Output_Video/`**
✅ **Audio reactivity is visible** (for audio-reactive shaders)
✅ **No upside-down rendering** (Y-flip applied correctly)
✅ **No black frames or rendering artifacts**

### 3.3 Check Output

Verify the output video:
- File exists in `Output_Video/[ShaderName]_5s.mp4`
- Video plays correctly
- Audio reactivity responds to music (bass/treble changes)
- No visual artifacts or corruption

---

## Step 4: Web Editor Integration

### 4.1 Automatic Detection

New shaders automatically appear in the web editor after:
1. Metadata is updated in `metadata.json`
2. Web page is refreshed (Ctrl+F5)

### 4.2 Audio Reactivity Detection

The `update_audio_metadata.py` script automatically detects audio-reactive shaders:

```bash
python update_audio_metadata.py
```

This script:
- Scans all `.glsl` files for `iChannel0` usage
- Updates `audio_reactive` field in metadata
- Shows purple music note icon (🎵) in web editor

### 4.3 Verification in Web Editor

1. Start web editor: `python web_editor/app.py`
2. Open browser: `http://localhost:5000`
3. Select audio file from left panel
4. Click "Shaders" tab in right panel
5. Verify new shaders appear in dropdown
6. Check audio-reactive shaders show music note icon

---

## Troubleshooting

### Common Issues and Solutions

#### 1. Shader Won't Compile
**Error**: `GLSL Compiler failed`

**Solutions**:
- Add `#version 330 core` at top
- Add required uniform declarations
- Replace `mainImage()` with `main()`
- Use `gl_FragCoord.xy` instead of function parameter
- Set `fragColor` as output variable

#### 2. Upside-Down Rendering
**Error**: Shader renders flipped vertically

**Solution**:
```glsl
fragCoord.y = iResolution.y - fragCoord.y;
```

#### 3. No Audio Reactivity
**Error**: Shader doesn't respond to music

**Solutions**:
- Verify `iChannel0` is declared as uniform
- Use correct audio texture sampling (y=0.5 for waveform)
- Check audio file is selected in web editor
- Ensure `audio_reactive: true` in metadata

#### 4. Missing Preview Image
**Error**: Shader shows no preview in web editor

**Solutions**:
- Check image file exists in `Shaders/` directory
- Verify filename matches metadata exactly (case-sensitive)
- Check file extension (.jpg vs .JPG)
- Generate preview by rendering 3-second clip and extracting frame

#### 5. Shader Not in Web Editor
**Error**: New shader doesn't appear in dropdown

**Solutions**:
- Verify metadata entry is valid JSON
- Check shader filename matches metadata `name` field exactly
- Refresh web page (Ctrl+F5)
- Check browser console for JavaScript errors

#### 6. Performance Issues
**Error**: Shader renders very slowly

**Solutions**:
- Reduce complexity of raymarching loops
- Lower iteration counts for expensive operations
- Optimize texture sampling
- Consider reducing render resolution for testing

---

## Audio Texture Format Details

### Texture Layout (512×256):
```
Row 0-1:   FFT Spectrum (frequency domain)
Row 2-4:   Guard band (prevents filtering artifacts)
Row 5-255: Waveform data (time domain)
```

### Sampling Guidelines:
```glsl
// Spectrum sampling (rows 0-1)
float freq = texture(iChannel0, vec2(frequency_0_to_1, 0.0)).r;

// Waveform sampling (rows 5-255) - use y=0.5 for center
float wave = texture(iChannel0, vec2(time_0_to_1, 0.5)).r;
```

### Audio Reactivity Patterns:
- **Bass**: Sample low frequencies (x=0.0 to 0.3)
- **Mid**: Sample mid frequencies (x=0.3 to 0.7)
- **Treble**: Sample high frequencies (x=0.7 to 1.0)
- **Waveform**: Use for time-domain effects, amplitude modulation

---

## Example: Complete Shader Conversion

### Before (Shadertoy):
```glsl
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    float bass = texture(iChannel0, vec2(0.1, 0.0)).r;
    fragColor = vec4(uv * bass, 0.0, 1.0);
}
```

### After (OneOffRender):
```glsl
#version 330 core

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0;

out vec4 fragColor;

void main() {
    vec2 fragCoord = gl_FragCoord.xy;
    fragCoord.y = iResolution.y - fragCoord.y;  // Y-flip fix
    
    vec2 uv = fragCoord / iResolution.xy;
    float bass = texture(iChannel0, vec2(0.1, 0.0)).r;
    fragColor = vec4(uv * bass, 0.0, 1.0);
}
```

---

## Testing Checklist

- [ ] Shader compiles without errors
- [ ] Y-coordinate flip applied (no upside-down rendering)
- [ ] Audio reactivity works (if applicable)
- [ ] Output video created successfully
- [ ] Metadata entry added with correct fields
- [ ] Preview image exists and matches filename
- [ ] Shader appears in web editor dropdown
- [ ] Audio icon shows for audio-reactive shaders (🎵)
- [ ] No visual artifacts or black frames

---

## Future Enhancements

### Potential Improvements:
- **Multi-pass rendering** support for complex shaders
- **External texture** loading for image-based effects
- **Custom uniform** parameters for user control
- **Shader presets** with different parameter sets
- **Real-time preview** in web editor
- **Shader performance** profiling and optimization

---

## Recently Registered Shaders (2025-10-05)

The following 18 verified working shaders have been successfully registered in the metadata system:

### Audio-Reactive Shaders (16):
1. **Base Vortex.glsl** - Audio-reactive tunnel vortex with rotating geometry
2. **Bubble Colors.glsl** - Colorful bubble patterns with gentle pulsing
3. **Colorful Columns.glsl** - Frequency-based column visualization
4. **Colorful Columns_V2.glsl** - Enhanced version with anti-flickering
5. **Cosmic Energy Streams1.glsl** - Flowing energy tendrils with dynamic lighting
6. **Cosmic Nebula2.glsl** - Deep space nebula with stellar formation
7. **Flowing Mathematical Patterns2.glsl** - Mathematical flow with beat detection
8. **Fork Bass Vorte PAEz 125.1.glsl** - Vortex tunnel variant with bass response
9. **Iridescent Breathing Orbs.glsl** - Breathing orbs with color shifts
10. **Luminous Nebulae.glsl** - Color-changing nebula effects
11. **MoltenHeart.glsl** - Dual-layer raymarching with intense effects
12. **Petal Drift.glsl** - Drifting Gaussian petals with gentle lighting
13. **sleeplessV4.glsl** - Bass-driven orb visualization
14. **Sonic Nebula.glsl** - Multi-frequency responsive nebula
15. **Volumetric Glow2.glsl** - Atmospheric lighting with brightness pulsing
16. **Xor Mashup 002.glsl** - XOR pattern mashup with rhythmic effects

### Static Shaders (2):
1. **Gyroid Art.glsl** - Mathematical gyroid surface visualization (no audio)
2. **Funky Flight.GLSL** - Funky flight path with smooth camera movement (no audio)

### Registration Notes:
- All shaders have been tested and confirmed working with OneOff.py
- Audio reactivity has been verified by inspecting iChannel0 usage in source code
- All corresponding preview images (.JPG) exist and are properly named
- Metadata entries include appropriate descriptions and audio_reactive flags
- All shaders are now discoverable in the web editor and oneoff.py

### File Verification Status:
✅ All 18 shader files (.glsl/.GLSL) exist in Shaders/ directory
✅ All 18 preview images (.JPG) exist and match shader names
✅ All metadata entries properly formatted in metadata.json
✅ Audio reactivity correctly identified for each shader

---

**Document Version**: 1.2
**Last Updated**: 2025-10-05
**Status**: Complete and Ready for Use - 18 New Shaders Registered
