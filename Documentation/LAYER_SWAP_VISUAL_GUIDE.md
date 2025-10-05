# Layer Swap - Visual Guide

## 🎬 Before vs After Comparison

### BEFORE (Old System)
```
┌─────────────────────────────────────────────────────────┐
│                    WEB INTERFACE                        │
├─────────────────────────────────────────────────────────┤
│ Music Track                                             │
├─────────────────────────────────────────────────────────┤
│ Layer 0: Shaders & Transitions  ← Renders FIRST        │
├─────────────────────────────────────────────────────────┤
│ Layer 1: Green Screen Videos    ← Renders SECOND       │
└─────────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────┐
│                  RENDERING PIPELINE                     │
├─────────────────────────────────────────────────────────┤
│ Step 1: Render Layer 0 (Shaders)                       │
│         Output: layer0_raw.mp4                          │
├─────────────────────────────────────────────────────────┤
│ Step 2: Render Layer 1 (Green Screen)                  │
│         Output: layer1_composite.mp4                    │
├─────────────────────────────────────────────────────────┤
│ Step 3: Composite                                       │
│         [Layer 0] + [Layer 1 with alpha]                │
└─────────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────┐
│                   FINAL VIDEO                           │
├─────────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────┐           │
│  │                                         │           │
│  │   Green Screen Video (on top)          │           │
│  │   with transparency                     │           │
│  │                                         │           │
│  │   ┌─────────────────────────────┐      │           │
│  │   │                             │      │           │
│  │   │  Shader Background          │      │           │
│  │   │  (shows through green)      │      │           │
│  │   │                             │      │           │
│  │   └─────────────────────────────┘      │           │
│  │                                         │           │
│  └─────────────────────────────────────────┘           │
└─────────────────────────────────────────────────────────┘

❌ PROBLEM: Layer 0 in timeline (top) renders as bottom layer
❌ CONFUSING: Visual order doesn't match render order
```

---

### AFTER (New System) ✅
```
┌─────────────────────────────────────────────────────────┐
│                    WEB INTERFACE                        │
├─────────────────────────────────────────────────────────┤
│ Music Track                                             │
├─────────────────────────────────────────────────────────┤
│ Layer 0: Green Screen Videos    ← Renders SECOND       │
│          (TOP VISUAL LAYER)                             │
├─────────────────────────────────────────────────────────┤
│ Layer 1: Shaders & Transitions  ← Renders FIRST        │
│          (BOTTOM VISUAL LAYER)                          │
└─────────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────┐
│                  RENDERING PIPELINE                     │
├─────────────────────────────────────────────────────────┤
│ Step 1: Render Layer 1 (Shaders)                       │
│         Output: layer1_raw.mp4                          │
├─────────────────────────────────────────────────────────┤
│ Step 2: Render Layer 0 (Green Screen)                  │
│         Output: layer0_composite.mp4                    │
├─────────────────────────────────────────────────────────┤
│ Step 3: Composite                                       │
│         [Layer 1] + [Layer 0 with alpha]                │
└─────────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────┐
│                   FINAL VIDEO                           │
├─────────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────┐           │
│  │                                         │           │
│  │   Green Screen Video (on top)          │           │
│  │   with transparency                     │           │
│  │                                         │           │
│  │   ┌─────────────────────────────┐      │           │
│  │   │                             │      │           │
│  │   │  Shader Background          │      │           │
│  │   │  (shows through green)      │      │           │
│  │   │                             │      │           │
│  │   └─────────────────────────────┘      │           │
│  │                                         │           │
│  └─────────────────────────────────────────┘           │
└─────────────────────────────────────────────────────────┘

✅ SOLUTION: Layer 0 in timeline (top) renders as top layer
✅ INTUITIVE: Visual order matches render order
✅ LOGICAL: Top layer in UI = top layer in video
```

---

## 🎨 Timeline Visual Comparison

### OLD System
```
┌────────────────────────────────────────────────────────┐
│ Layer Name Column │ Timeline                           │
├───────────────────┼────────────────────────────────────┤
│ Music             │ ████████████████████████████████   │ ← Audio
├───────────────────┼────────────────────────────────────┤
│ Shaders &         │ [Shader A] [Trans] [Shader B]      │ ← Layer 0
│ Transitions       │                                    │
├───────────────────┼────────────────────────────────────┤
│ Green Screen      │ [Video 1]      [Video 2]           │ ← Layer 1
│ Videos            │                                    │
└───────────────────┴────────────────────────────────────┘

User thinks: "Layer 0 is on top, so shaders are on top"
Reality: Green screen videos render on top ❌ CONFUSING
```

### NEW System ✅
```
┌────────────────────────────────────────────────────────┐
│ Layer Name Column │ Timeline                           │
├───────────────────┼────────────────────────────────────┤
│ Music             │ ████████████████████████████████   │ ← Audio
├───────────────────┼────────────────────────────────────┤
│ Green Screen      │ [Video 1]      [Video 2]           │ ← Layer 0 (TOP)
│ Videos            │                                    │
├───────────────────┼────────────────────────────────────┤
│ Shaders &         │ [Shader A] [Trans] [Shader B]      │ ← Layer 1 (BOTTOM)
│ Transitions       │                                    │
└───────────────────┴────────────────────────────────────┘

User thinks: "Layer 0 is on top, so videos are on top"
Reality: Green screen videos render on top ✅ MATCHES EXPECTATION
```

---

## 🔄 Rendering Flow Diagram

### Complete Pipeline
```
┌─────────────────────────────────────────────────────────────┐
│                    USER CREATES TIMELINE                    │
│                                                             │
│  Layer 0: [dancer.mp4] ────────────────────────────────    │
│  Layer 1: [fractal.glsl] ──────────────────────────────    │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│              MANIFEST GENERATION (JSON)                     │
│                                                             │
│  {                                                          │
│    "elements": [                                            │
│      {"type": "video", "layer": 0, ...},                   │
│      {"type": "shader", "layer": 1, ...}                   │
│    ]                                                        │
│  }                                                          │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                  RENDER LAYER 1 (SHADERS)                   │
│                                                             │
│  ┌───────────────────────────────────────────────┐         │
│  │ 1. Load shader elements from layer 1          │         │
│  │ 2. Compile GLSL shaders                       │         │
│  │ 3. Initialize OpenGL context                  │         │
│  │ 4. Load audio data for reactivity             │         │
│  │ 5. Render frame-by-frame:                     │         │
│  │    - Set uniforms (iTime, iResolution)        │         │
│  │    - Bind audio texture (iChannel0)           │         │
│  │    - Render to framebuffer                    │         │
│  │    - Write RGB pixels to raw file             │         │
│  │ 6. Convert raw to MP4                         │         │
│  └───────────────────────────────────────────────┘         │
│                                                             │
│  Output: layer1_raw.mp4 (1920x1080, RGB, no alpha)        │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│              RENDER LAYER 0 (GREEN SCREEN)                  │
│                                                             │
│  ┌───────────────────────────────────────────────┐         │
│  │ 1. Load video elements from layer 0           │         │
│  │ 2. For each frame:                            │         │
│  │    - Extract frame from video                 │         │
│  │    - Apply chroma key (remove green)          │         │
│  │    - Replace green with neon green            │         │
│  │    - Write to raw file                        │         │
│  │ 3. Convert raw to MP4 with chroma key:        │         │
│  │    - FFmpeg chromakey filter                  │         │
│  │    - Output with alpha channel                │         │
│  └───────────────────────────────────────────────┘         │
│                                                             │
│  Output: layer0_composite.mp4 (1920x1080, RGBA)           │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                    COMPOSITE LAYERS                         │
│                                                             │
│  FFmpeg Command:                                            │
│  ┌─────────────────────────────────────────────┐           │
│  │ ffmpeg -y \                                 │           │
│  │   -i layer1_raw.mp4 \        ← Background  │           │
│  │   -i layer0_composite.mp4 \  ← Overlay     │           │
│  │   -filter_complex \                         │           │
│  │     '[0:v][1:v]overlay=0:0:format=auto' \  │           │
│  │   -c:v libx264 \                            │           │
│  │   -pix_fmt yuv420p \                        │           │
│  │   composite.mp4                             │           │
│  └─────────────────────────────────────────────┘           │
│                                                             │
│  Result: Shader background + Green screen overlay          │
│  Output: composite.mp4 (1920x1080, RGB)                   │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                      ADD AUDIO TRACK                        │
│                                                             │
│  FFmpeg Command:                                            │
│  ┌─────────────────────────────────────────────┐           │
│  │ ffmpeg -y \                                 │           │
│  │   -i composite.mp4 \                        │           │
│  │   -i audio.mp3 \                            │           │
│  │   -c:v copy \                               │           │
│  │   -c:a aac \                                │           │
│  │   -shortest \                               │           │
│  │   final_output.mp4                          │           │
│  └─────────────────────────────────────────────┘           │
│                                                             │
│  Output: final_output.mp4 (with audio)                     │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                    FINAL VIDEO OUTPUT                       │
│                                                             │
│  📁 Output_Video/final_output.mp4                          │
│                                                             │
│  ✅ Shader background (Layer 1)                            │
│  ✅ Green screen overlay (Layer 0)                         │
│  ✅ Audio track synchronized                               │
│  ✅ Ready to share!                                        │
└─────────────────────────────────────────────────────────────┘
```

---

## 🎭 Chroma Key Visualization

### How Green Screen Compositing Works

```
LAYER 1 (SHADERS - BACKGROUND)
┌─────────────────────────────────────┐
│ ████████████████████████████████    │
│ ████ Animated Fractal ██████████    │
│ ████████████████████████████████    │
│ ████████████████████████████████    │
│ ████████████████████████████████    │
└─────────────────────────────────────┘
              +
LAYER 0 (GREEN SCREEN - OVERLAY)
┌─────────────────────────────────────┐
│ 🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩    │
│ 🟩🟩🟩🟩 👤 Dancer 🟩🟩🟩🟩🟩🟩    │
│ 🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩    │
│ 🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩    │
│ 🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩🟩    │
└─────────────────────────────────────┘
              ↓
        CHROMA KEY APPLIED
        (Remove 🟩 = Transparent)
              ↓
┌─────────────────────────────────────┐
│ ⬜⬜⬜⬜⬜⬜⬜⬜⬜⬜⬜⬜⬜⬜⬜⬜    │
│ ⬜⬜⬜⬜ 👤 Dancer ⬜⬜⬜⬜⬜⬜    │
│ ⬜⬜⬜⬜⬜⬜⬜⬜⬜⬜⬜⬜⬜⬜⬜⬜    │
│ ⬜⬜⬜⬜⬜⬜⬜⬜⬜⬜⬜⬜⬜⬜⬜⬜    │
│ ⬜⬜⬜⬜⬜⬜⬜⬜⬜⬜⬜⬜⬜⬜⬜⬜    │
└─────────────────────────────────────┘
              ↓
         COMPOSITE RESULT
┌─────────────────────────────────────┐
│ ████████████████████████████████    │
│ ████ 👤 Dancer on Fractal ██████    │
│ ████████████████████████████████    │
│ ████████████████████████████████    │
│ ████████████████████████████████    │
└─────────────────────────────────────┘

Legend:
🟩 = Green pixels (removed by chroma key)
⬜ = Transparent (alpha = 0)
█ = Shader background (visible through transparency)
👤 = Dancer (non-green pixels, kept)
```

---

## 📊 Layer Priority Table

| Layer | Content | Visual Position | Render Order | Alpha Channel | Can Skip |
|-------|---------|----------------|--------------|---------------|----------|
| 0 | Green Screen Videos | Top (overlay) | 2nd | Yes | Yes |
| 1 | Shaders & Transitions | Bottom (background) | 1st | No | No |
| 2+ | Future layers | TBD | TBD | TBD | TBD |

---

## 🎯 Use Case Examples

### Example 1: Music Video
```
Layer 0: [dancer.mp4] ──────────────────────────────
Layer 1: [fractal.glsl] ────────────────────────────

Result: Dancer appears in front of animated fractal
```

### Example 2: Shader-Only Video
```
Layer 0: (empty)
Layer 1: [waveform.glsl] ───────────────────────────

Result: Pure shader video, no green screen processing
```

### Example 3: Multiple Videos
```
Layer 0: [dancer1.mp4] ──── [dancer2.mp4] ─────────
Layer 1: [particles.glsl] ──────────────────────────

Result: Different dancers appear at different times
        over particle background
```

### Example 4: Shader Transitions
```
Layer 0: (empty)
Layer 1: [shader1] ─ [transition] ─ [shader2] ─────

Result: Smooth transition between two shaders
```

---

**Visual Guide Complete** ✅

