# Cubemap Support for OneOffRender

## Overview

This document explains cubemap texture support for OneOffRender, enabling shaders that use `samplerCube` uniforms for environment mapping, reflections, and skyboxes.

## What Are Cubemaps?

A **cubemap** is a texture composed of **6 square images** representing the faces of a cube. They're used for:
- **Environment Reflections** - Realistic reflections on surfaces
- **Skyboxes** - 360° background environments
- **Image-Based Lighting (IBL)** - Realistic lighting from environment
- **Spherical Mapping** - Wrapping textures around 3D objects

## Folder Structure

```
OneOffRender/
├── Cubemaps/                    ← Cubemap textures (6 faces each)
│   ├── skybox_px.png           ← Positive X (right)
│   ├── skybox_nx.png           ← Negative X (left)
│   ├── skybox_py.png           ← Positive Y (top)
│   ├── skybox_ny.png           ← Negative Y (bottom)
│   ├── skybox_pz.png           ← Positive Z (front)
│   └── skybox_nz.png           ← Negative Z (back)
├── Textures/                    ← Regular 2D textures
│   ├── Abstract 1.jpg
│   └── London.jpg
└── Shaders/
    ├── Shader Lesson 8 - cube maps.glsl
    └── metadata.json
```

## File Naming Convention

### Standard 6-Face Cubemap

Each cubemap requires **6 separate image files** with this naming pattern:

```
<basename>_px.<ext>  ← Positive X (right face)
<basename>_nx.<ext>  ← Negative X (left face)
<basename>_py.<ext>  ← Positive Y (top face)
<basename>_ny.<ext>  ← Negative Y (bottom face)
<basename>_pz.<ext>  ← Positive Z (front face)
<basename>_nz.<ext>  ← Negative Z (back face)
```

**Example:**
```
skybox_px.png
skybox_nx.png
skybox_py.png
skybox_ny.png
skybox_pz.png
skybox_nz.png
```

### Face Order (ModernGL)

ModernGL's `texture_cube()` expects data in this order:
1. **+X** (right)
2. **-X** (left)
3. **+Y** (top)
4. **-Y** (bottom)
5. **+Z** (front)
6. **-Z** (back)

## Supported Image Formats

✅ **PNG** (Recommended) - Lossless, no compression artifacts at seams  
✅ **JPG** - Smaller file size, but may have artifacts  
✅ **BMP** - Uncompressed, large files  
✅ **TGA** - Good for high-quality textures  
✅ **TIFF** - High quality, large files  

**Recommendation:** Use **PNG** for cubemaps to avoid compression artifacts at face boundaries.

## Image Requirements

### Size Requirements
- ✅ All 6 faces **must be the same size**
- ✅ Each face **must be square** (width == height)
- ✅ Common sizes: 512×512, 1024×1024, 2048×2048, 4096×4096
- ⚠️ Power-of-2 sizes recommended (512, 1024, 2048) but not required

### Color Format
- **RGB** (3 channels) - Standard, most common
- **RGBA** (4 channels) - With alpha/transparency (requires code modification)
- **Grayscale** - Will be converted to RGB automatically

### Coordinate System (OpenGL)

```
        +Y (top)
         |
         |
-X ------+------ +X
(left)   |      (right)
         |
        -Y (bottom)

+Z (front) points towards you
-Z (back) points away from you
```

**Important:** Different tools export cubemaps with different orientations. You may need to:
- Flip faces vertically or horizontally
- Rotate faces 90°/180°/270°
- Swap face assignments

## Metadata Schema

### Phase 1: Simple Cubemap (Single Set)

```json
{
  "name": "Shader Lesson 8 - cube maps.glsl",
  "preview_image": "Shader Lesson 8 - cube maps.JPG",
  "stars": 3,
  "buffer": null,
  "texture": {
    "iChannel1": {
      "type": "cubemap",
      "basename": "skybox"
    }
  },
  "description": "Raytraced sphere with cubemap reflections",
  "audio_reactive": false
}
```

**Behavior:** Loads `Cubemaps/skybox_*.png` (6 files) and binds to `iChannel1` as `samplerCube`

### Phase 2: Explicit File Paths

```json
{
  "name": "MyShader.glsl",
  "texture": {
    "iChannel1": {
      "type": "cubemap",
      "files": {
        "px": "skybox_px.png",
        "nx": "skybox_nx.png",
        "py": "skybox_py.png",
        "ny": "skybox_ny.png",
        "pz": "skybox_pz.png",
        "nz": "skybox_nz.png"
      }
    }
  }
}
```

**Behavior:** Loads specific files from `Cubemaps/` folder

### Phase 3: Cross/Strip Layout (Future)

```json
{
  "name": "MyShader.glsl",
  "texture": {
    "iChannel1": {
      "type": "cubemap",
      "file": "skybox_cross.png",
      "layout": "cross"
    }
  }
}
```

**Behavior:** Loads single image with 6 faces in cross layout and splits them

## GLSL Shader Usage

### Uniform Declaration

```glsl
#version 330 core

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0;    // Audio (always reserved)
uniform samplerCube iChannel1;  // Cubemap texture

out vec4 fragColor;
```

### Sampling a Cubemap

```glsl
void main() {
    vec2 uv = gl_FragCoord.xy / iResolution.xy;
    
    // Create a 3D direction vector
    vec3 direction = normalize(vec3(uv * 2.0 - 1.0, 1.0));
    
    // Sample the cubemap using the direction
    vec4 color = texture(iChannel1, direction);
    
    fragColor = color;
}
```

### Reflection Example

```glsl
// Calculate reflection vector
vec3 viewDir = normalize(cameraPos - surfacePos);
vec3 normal = normalize(surfaceNormal);
vec3 reflection = reflect(-viewDir, normal);

// Sample cubemap for reflection
vec4 reflectionColor = texture(iChannel1, reflection);
```

## Channel Allocation

### Priority Order
```
iChannel0: Audio (ALWAYS - never reassign)
iChannel1-4: Buffers first (if present), then textures (2D or cubemap)
```

### Example Scenarios

**Scenario 1: Cubemap Only**
```
iChannel0 = Audio texture (512×256 FFT)
iChannel1 = Cubemap (skybox)
iChannel2 = Unused
iChannel3 = Unused
iChannel4 = Unused
```

**Scenario 2: Cubemap + 2D Texture**
```
iChannel0 = Audio texture
iChannel1 = Cubemap (environment)
iChannel2 = 2D texture (surface detail)
iChannel3 = Unused
iChannel4 = Unused
```

**Scenario 3: Buffer + Cubemap**
```
iChannel0 = Audio texture
iChannel1 = Buffer A output
iChannel2 = Cubemap (environment)
iChannel3 = Unused
iChannel4 = Unused
```

## Creating Cubemap Textures

### Option 1: Download Pre-made Cubemaps

**Free Sources:**
- [Poly Haven](https://polyhaven.com/hdris) - High-quality HDRIs (can convert to cubemap)
- [HDRIHaven](https://hdrihaven.com/) - Free HDR environment maps
- [Humus Cubemaps](http://www.humus.name/index.php?page=Textures) - Classic cubemap collection
- [OpenGameArt](https://opengameart.org/) - Search for "skybox" or "cubemap"

### Option 2: Convert Panoramic/Equirectangular Images

Use tools to convert 360° panoramic images to 6-face cubemaps:
- **[Cubemap Converter](https://matheowis.github.io/HDRI-to-CubeMap/)** (Online)
- **[cmftStudio](https://github.com/dariomanesku/cmftStudio)** (Desktop app)
- **Blender** - Built-in cubemap baking
- **Python PIL/Pillow** - Custom scripts

### Option 3: Render from 3D Software

Render 6 views from a 3D scene:
- **Blender** - Camera with 90° FOV, render 6 directions
- **Unity/Unreal** - Built-in cubemap capture
- **Maya/3ds Max** - Environment map rendering

### Option 4: Create Test Cubemap

Simple solid-color faces for testing:
```python
from PIL import Image

colors = {
    'px': (255, 0, 0),    # Red (right)
    'nx': (0, 255, 255),  # Cyan (left)
    'py': (0, 255, 0),    # Green (top)
    'ny': (255, 0, 255),  # Magenta (bottom)
    'pz': (0, 0, 255),    # Blue (front)
    'nz': (255, 255, 0),  # Yellow (back)
}

size = 512
for face, color in colors.items():
    img = Image.new('RGB', (size, size), color)
    img.save(f'Cubemaps/test_{face}.png')
```

## Performance Considerations

### Memory Usage

Cubemap memory = `width × height × 6 faces × bytes_per_pixel`

**Examples:**
- 512×512 RGB: 512 × 512 × 6 × 3 = **4.7 MB**
- 1024×1024 RGB: 1024 × 1024 × 6 × 3 = **18.9 MB**
- 2048×2048 RGB: 2048 × 2048 × 6 × 3 = **75.5 MB**
- 4096×4096 RGB: 4096 × 4096 × 6 × 3 = **302 MB**

### Recommendations

- **512×512** - Good for simple reflections, low memory
- **1024×1024** - Standard quality, balanced
- **2048×2048** - High quality, large memory
- **4096×4096** - Ultra quality, very large memory (use sparingly)

### Mipmaps

Mipmaps improve performance and reduce aliasing:
- Adds ~33% more memory
- Improves sampling quality at distance
- Recommended for most cubemaps

## Troubleshooting

### Common Issues

**Issue: Cubemap appears black or incorrect**
- ✓ Check all 6 files exist and are readable
- ✓ Verify all faces are the same size
- ✓ Ensure faces are square (width == height)
- ✓ Check file naming matches convention

**Issue: Seams visible between faces**
- Use PNG instead of JPG (no compression artifacts)
- Ensure cubemap was generated with proper filtering
- Enable mipmaps for smoother transitions

**Issue: Reflections look wrong**
- Check face orientation (may need flips/rotations)
- Verify coordinate system matches OpenGL convention
- Test with solid-color test cubemap first

**Issue: Shader compilation error**
- Ensure `samplerCube` is declared, not `sampler2D`
- Check texture binding matches uniform name
- Verify sampling uses `vec3` direction, not `vec2` UV

## Implementation Status

### ✅ Completed
- Folder structure (`Cubemaps/` folder created)
- File naming convention defined
- Image format support (PNG, JPG, etc.)
- Metadata schema designed

### ⏳ To Be Implemented
- `load_cubemap_from_files()` function in `render_shader.py`
- Cubemap detection in `detect_and_load_textures()`
- Cubemap binding in rendering methods
- Shader conversion for "Shader Lesson 8 - cube maps.glsl"
- Testing with actual cubemap textures

### 📅 Estimated Implementation Time
- **Code Implementation:** 4-6 hours
- **Testing & Debugging:** 2-3 hours
- **Shader Conversion:** 30 minutes
- **Total:** 7-10 hours

## Alternative: Spherical Mapping Workaround

If full cubemap support is not yet implemented, you can use **spherical/equirectangular mapping** as a workaround:

1. Convert cubemap to equirectangular 2D image
2. Use `sampler2D` instead of `samplerCube`
3. Convert 3D direction to 2D UV coordinates:

```glsl
uniform sampler2D iChannel1;  // Equirectangular map

vec2 directionToUV(vec3 dir) {
    float u = atan(dir.z, dir.x) / (2.0 * 3.14159) + 0.5;
    float v = asin(dir.y) / 3.14159 + 0.5;
    return vec2(u, v);
}

void main() {
    vec3 direction = normalize(vec3(...));
    vec2 uv = directionToUV(direction);
    vec4 color = texture(iChannel1, uv);
    fragColor = color;
}
```

This approach was used successfully for "SIG15 EntryLevel" shader.

## References

- [LearnOpenGL - Cubemaps](https://learnopengl.com/Advanced-OpenGL/Cubemaps)
- [ModernGL Documentation - TextureCube](https://moderngl.readthedocs.io/en/latest/reference/context.html#moderngl.Context.texture_cube)
- [OpenGL Wiki - Cubemap Texture](https://www.khronos.org/opengl/wiki/Cubemap_Texture)
- [Shadertoy - How to use Cubemaps](https://www.shadertoy.com/view/XsjfDD)

---

**Last Updated:** 2025-10-14  
**Status:** Documentation complete, implementation pending

