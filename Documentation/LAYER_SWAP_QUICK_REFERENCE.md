# Layer Swap - Quick Reference

## 🎯 What Changed?

### Layer Assignments (NEW)
- **Layer 0** = Green Screen Videos (top visual layer)
- **Layer 1** = Shaders & Transitions (bottom visual layer)

### Layer Assignments (OLD)
- ~~Layer 0 = Shaders & Transitions~~
- ~~Layer 1 = Green Screen Videos~~

---

## 📋 Quick Facts

| Aspect | Layer 0 | Layer 1 |
|--------|---------|---------|
| **Content Type** | Green Screen Videos | Shaders & Transitions |
| **Visual Position** | Top (overlay) | Bottom (background) |
| **Rendering Order** | Second | First |
| **Alpha Channel** | Yes (from chroma key) | No |
| **Can Be Empty** | Yes (skips processing) | No (creates black video) |
| **Drag & Drop** | Videos only | Shaders/transitions only |

---

## 🎨 Web Interface

### Timeline View
```
┌─────────────────────────────────────┐
│ Music                               │ ← Audio track (fixed)
├─────────────────────────────────────┤
│ Green Screen Videos (Layer 0)       │ ← Top visual layer
├─────────────────────────────────────┤
│ Shaders & Transitions (Layer 1)     │ ← Bottom visual layer
├─────────────────────────────────────┤
│ Layer 3                             │ ← Future layers
└─────────────────────────────────────┘
```

### Drag & Drop Rules
- ✅ **Videos** → Layer 0 only
- ✅ **Shaders** → Layer 1 only
- ✅ **Transitions** → Layer 1 only
- ❌ **Videos** → Layer 1 = Error
- ❌ **Shaders/Transitions** → Layer 0 = Error

---

## 🔧 Rendering Pipeline

### Render Order
```
1. Render Layer 1 (Shaders)
   ↓
2. Render Layer 0 (Green Screen)
   ↓
3. Composite: [Layer 1] + [Layer 0 with alpha]
   ↓
4. Add Audio
   ↓
5. Final Output
```

### File Outputs
- **Layer 1**: `layer1_raw.mp4` (shaders, no alpha)
- **Layer 0**: `layer0_composite.mp4` (green screen with alpha)
- **Composite**: `composite.mp4` (final combined)

---

## 💡 Why This Change?

### Visual Logic
- **Before**: Layer 0 (bottom of timeline) = bottom of video ❌ Confusing
- **After**: Layer 0 (top of timeline) = top of video ✅ Intuitive

### Chroma Key Logic
- Green screen videos need to be **on top** with transparency
- Shader layer shows through transparent areas
- Correct compositing order

### Performance
- If Layer 0 is empty → skip green screen processing entirely
- Only render what's needed

---

## ⚠️ Breaking Changes

### Existing Projects
**Old manifests will render incorrectly!**

### Migration Options

#### Option 1: Re-create Timeline (Recommended)
1. Open web interface
2. Load audio file
3. Drag elements to correct layers:
   - Videos → Layer 0
   - Shaders/Transitions → Layer 1
4. Render

#### Option 2: Manual JSON Edit
Edit `temp_render_manifest.json`:
```json
{
  "timeline": {
    "elements": [
      {
        "type": "video",
        "layer": 0  // Change from 1 to 0
      },
      {
        "type": "shader",
        "layer": 1  // Change from 0 to 1
      }
    ]
  }
}
```

---

## 🧪 Testing

### Test Scenarios

#### ✅ Test 1: Green Screen on Top
- Layer 0: Green screen video
- Layer 1: Shader
- **Expected**: Video overlays shader, green removed

#### ✅ Test 2: Empty Layer 0
- Layer 0: Empty
- Layer 1: Shader
- **Expected**: Shader only, no green screen processing

#### ✅ Test 3: Transitions
- Layer 1: Shader A → Transition → Shader B
- **Expected**: Smooth transition between shaders

#### ✅ Test 4: Drag & Drop Validation
- Try dragging video to Layer 1
- **Expected**: Error message, drop rejected

---

## 📝 Code Changes Summary

### Files Modified
1. `web_editor/static/js/timeline.js` - Layer labels
2. `web_editor/static/js/editor.js` - Drag & drop validation
3. `render_timeline.py` - Rendering pipeline

### Key Method Changes
- `render_shader_layer()` - Now processes Layer 1
- `render_greenscreen_layer()` - Now processes Layer 0
- `composite_layers()` - Updated parameter names and comments
- `render_layer0_timeline()` → `render_layer1_timeline()` - Renamed

### Log Message Updates
- All log messages now show correct layer numbers
- Clear indication of which layer is being processed

---

## 🚀 Usage Examples

### Example 1: Music Video with Dancer
```json
{
  "timeline": {
    "elements": [
      {
        "type": "video",
        "name": "dancer.mp4",
        "layer": 0,  // Green screen dancer on top
        "startTime": 0,
        "endTime": 30
      },
      {
        "type": "shader",
        "name": "fractal.glsl",
        "layer": 1,  // Fractal shader background
        "startTime": 0,
        "endTime": 30
      }
    ]
  }
}
```
**Result**: Dancer appears in front of animated fractal background

### Example 2: Shader-Only Video
```json
{
  "timeline": {
    "elements": [
      {
        "type": "shader",
        "name": "waveform.glsl",
        "layer": 1,  // Shader on Layer 1
        "startTime": 0,
        "endTime": 20
      },
      {
        "type": "transition",
        "name": "Circle",
        "layer": 1,  // Transition on Layer 1
        "startTime": 20,
        "endTime": 21.6
      },
      {
        "type": "shader",
        "name": "particles.glsl",
        "layer": 1,  // Next shader on Layer 1
        "startTime": 21.6,
        "endTime": 40
      }
    ]
  }
}
```
**Result**: Shader video with smooth transition, no green screen processing

---

## 🔍 Troubleshooting

### Issue: Video appears behind shader
**Cause**: Video on Layer 1 instead of Layer 0
**Fix**: Move video to Layer 0 in timeline

### Issue: Shader not visible
**Cause**: No elements on Layer 1
**Fix**: Add shader to Layer 1

### Issue: Green not removed from video
**Cause**: Chroma key settings incorrect
**Fix**: Check green screen settings in video element

### Issue: Old project renders incorrectly
**Cause**: Manifest uses old layer assignments
**Fix**: Re-create timeline or manually edit JSON

---

## 📚 Related Documentation

- `LAYER_SWAP_IMPLEMENTATION.md` - Full technical details
- `RENDER_PIPELINE_IMPLEMENTATION.md` - Overall rendering pipeline
- `GREEN_SCREEN_VIDEOS_LAYER_IMPLEMENTATION.md` - Green screen specifics
- `SHADERS_TRANSITIONS_LAYER_IMPLEMENTATION.md` - Shader layer specifics

---

**Last Updated**: 2025-10-03
**Status**: ✅ Implemented and tested
**Breaking Change**: Yes

