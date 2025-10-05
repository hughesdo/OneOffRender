# Chroma Key Implementation Notes

## Problem Summary

The original chroma key implementation was failing to remove green from green screen videos. The issue was caused by a **two-step process that lost the alpha channel** between intermediate files.

---

## Root Causes

### 1. **Alpha Channel Loss**
- Created `layer0_composite.mp4` with `yuva420p` (alpha channel)
- H.264 encoding with alpha can be lossy
- When overlaying on shaders, alpha wasn't properly preserved
- Result: Green remained visible in final output

### 2. **Wrong Green Color**
- Code was targeting `rgb(0, 216, 0)` (0x00d800)
- Actual green in video was `rgb(0, 214, 0)` (0x00d600)
- 2-point difference prevented chroma key from working

### 3. **Wrong FFmpeg Syntax**
- Used positional parameters: `chromakey=0x00d800:0.5:0.3`
- Should use named parameters: `chromakey=color=0x00d800:similarity=0.5:blend=0.3`
- Positional syntax may not work correctly in all FFmpeg versions

---

## Solution: Single-Pass Compositing

### **Key Insight**
Combine chroma key and compositing into **one FFmpeg command** to avoid alpha channel loss.

### **New Pipeline**
```
Layer 1 (Shaders)     Layer 0 (Green Screen)
      ↓                        ↓
layer1_raw.mp4          layer0_raw.rgb
      ↓                        ↓
      └────────┬───────────────┘
               ↓
    Single FFmpeg Command:
    - Apply chroma key to raw RGB
    - Extract & blur alpha
    - Overlay on shaders
               ↓
         composite.mp4 ✅
```

---

## FFmpeg Filter Chain

### **The Working Command**
```bash
ffmpeg -y \
  -i layer1_raw.mp4 \
  -f rawvideo -pixel_format rgb24 -video_size 2560x1440 -framerate 30 -i layer0_raw.rgb \
  -filter_complex "
    [1:v]format=rgba,colorkey=0x00d600:0.38:0.0,split[fga][fgc];
    [fga]alphaextract,boxblur=2:1[matte];
    [fgc][matte]alphamerge[fg];
    [0:v][fg]overlay=0:0:format=auto
  " \
  -c:v libx264 -crf 18 -preset medium -pix_fmt yuv420p composite.mp4
```

### **Filter Breakdown**

1. **`[1:v]format=rgba`**
   - Converts raw RGB input to RGBA (adds alpha channel)
   - Required before applying chroma key

2. **`colorkey=0x00d600:0.38:0.0`**
   - Removes green color `rgb(0, 214, 0)` (hex: 0x00d600)
   - `similarity=0.38`: Removes colors 38% similar to target (tuned value)
   - `blend=0.0`: No edge blending (we handle this separately with blur)

3. **`split[fga][fgc]`**
   - Splits stream into two identical copies
   - `[fga]`: For alpha extraction
   - `[fgc]`: For color data

4. **`[fga]alphaextract,boxblur=2:1[matte]`**
   - Extracts alpha channel from `[fga]`
   - Applies box blur (2 pixels horizontal, 1 pixel vertical)
   - **Purpose**: Softens jagged edges, reduces aliasing

5. **`[fgc][matte]alphamerge[fg]`**
   - Merges color data `[fgc]` with cleaned alpha `[matte]`
   - Result: Green screen video with smooth transparency

6. **`[0:v][fg]overlay=0:0:format=auto`**
   - Overlays `[fg]` (green screen with alpha) on `[0:v]` (shaders)
   - Position: (0, 0) - top-left corner
   - `format=auto`: Automatically handles pixel format conversion

---

## Key Parameters

### **Chroma Key Color**
- **Value**: `0x00d600` = `rgb(0, 214, 0)`
- **How to find**: Extract frame, use color picker on green area
- **Important**: Must match EXACT green in video (not assumed value)

### **Similarity Threshold**
- **Value**: `0.38` (tuned through testing)
- **Range**: 0.0 (exact match only) to 1.0 (very forgiving)
- **Too low**: Leaves green edges/spill
- **Too high**: Removes subject colors that are greenish

### **Blur Amount**
- **Value**: `boxblur=2:1` (2 horizontal, 1 vertical)
- **Purpose**: Softens alpha edges to reduce jaggies
- **Trade-off**: More blur = smoother edges but softer subject boundaries

---

## Code Changes

### **1. `composite_layers()` Method**
**Location**: `render_timeline.py` lines 313-392

**Changed from**: Two-step process
```python
# Step 1: Create layer0_composite.mp4 with chroma key
convert_raw_to_mp4_with_chromakey(...)

# Step 2: Overlay on shaders
ffmpeg -i layer1_raw.mp4 -i layer0_composite.mp4 -filter_complex overlay ...
```

**Changed to**: Single-step process
```python
# Single FFmpeg command with chroma key during compositing
ffmpeg -i layer1_raw.mp4 -f rawvideo ... -i layer0_raw.rgb \
  -filter_complex "[1:v]format=rgba,colorkey=...,overlay..." \
  composite.mp4
```

### **2. `render_video_layer()` Method**
**Location**: `render_timeline.py` lines 1614-1626

**Changed from**: Returns MP4 path
```python
convert_raw_to_mp4_with_chromakey(...)
return "layer0_composite.mp4"
```

**Changed to**: Returns raw RGB path
```python
# Don't convert to MP4 - chroma key applied during compositing
return "layer0_raw.rgb"
```

### **3. `render_greenscreen_layer()` Method**
**Location**: `render_timeline.py` lines 297-313

**Changed**: Now returns raw RGB file path instead of MP4 path

### **4. Green Color Updates**
**Locations**: Lines 1409, 1425, 1435, 1455, 1463

**Changed from**: `rgb(0, 216, 0)` everywhere
**Changed to**: `rgb(0, 214, 0)` everywhere

---

## Testing & Debugging

### **Extract Frame to Check Green Color**
```bash
ffmpeg -i layer0_composite.mp4 -vframes 1 -f image2 test_frame.png
```
Then use color picker in image editor on green area.

### **Test Chroma Key Manually**
```bash
ffmpeg -y \
  -i layer1_raw.mp4 \
  -f rawvideo -pixel_format rgb24 -video_size 2560x1440 -framerate 30 -i layer0_raw.rgb \
  -filter_complex "[1:v]format=rgba,colorkey=0x00d600:0.38:0.0,split[fga][fgc];[fga]alphaextract,boxblur=2:1[matte];[fgc][matte]alphamerge[fg];[0:v][fg]overlay=0:0:format=auto" \
  -c:v libx264 -crf 18 -preset medium -pix_fmt yuv420p test_output.mp4
```

### **Adjust Similarity if Needed**
- Green still visible? **Increase** similarity (try 0.5, 0.6)
- Subject being removed? **Decrease** similarity (try 0.3, 0.25)

### **Check for Green in Shaders**
If shaders contain green colors, they'll be removed too! Solutions:
1. Avoid green in shaders when using green screen
2. Use different chroma key color (blue, magenta)
3. Apply chroma key only to specific regions (complex)

---

## Lessons Learned

1. **Avoid intermediate files with alpha channels**
   - H.264 with alpha (`yuva420p`) can be lossy
   - Process in single pass when possible

2. **Always verify actual colors**
   - Don't assume green screen is `rgb(0, 255, 0)`
   - Extract frame and color pick to get exact values

3. **Use named parameters in FFmpeg**
   - `colorkey=color=0x00d600:similarity=0.38:blend=0.0`
   - More explicit and reliable than positional parameters

4. **Alpha channel processing matters**
   - Extract → Blur → Merge produces cleaner edges
   - Reduces jaggies and aliasing artifacts

5. **Test with manual FFmpeg commands first**
   - Faster iteration than full render pipeline
   - Easier to debug filter chain issues

---

## Future Improvements

### **Potential Enhancements**
1. **Auto-detect green color** from video frames
2. **Adaptive similarity** based on lighting variations
3. **Despill filter** to remove green color cast from subject
4. **Edge refinement** with more sophisticated alpha processing
5. **Support multiple chroma key colors** (blue screen, etc.)

### **Performance Optimization**
- Current approach processes raw RGB which is large
- Could use intermediate codec with lossless alpha (ProRes 4444)
- Trade-off: Larger files but potentially faster processing

---

## References

- FFmpeg colorkey filter: https://ffmpeg.org/ffmpeg-filters.html#colorkey
- FFmpeg overlay filter: https://ffmpeg.org/ffmpeg-filters.html#overlay-1
- Alpha channel formats: https://trac.ffmpeg.org/wiki/Encode/VFX

---

**Last Updated**: 2025-10-04  
**Status**: ✅ Working - Green screen removal successful

