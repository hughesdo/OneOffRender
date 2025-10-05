# Layer Swap - Testing Guide

## 🧪 How to Test the Layer Swap Implementation

This guide provides step-by-step instructions to verify that the layer swap is working correctly.

---

## Prerequisites

1. **Web Interface Running**: Make sure the web server is running
2. **Browser Open**: Open the web interface in your browser
3. **Test Files Ready**: Have at least one shader, one transition, and one video file available

---

## Test 1: Verify Layer Labels

### Steps
1. Open the web interface
2. Look at the timeline layer names on the left side

### Expected Results
```
┌─────────────────────────────┐
│ Music                       │ ← Audio track
├─────────────────────────────┤
│ Green Screen Videos         │ ← Layer 0 (top)
├─────────────────────────────┤
│ Shaders & Transitions       │ ← Layer 1 (bottom)
├─────────────────────────────┤
│ Layer 3                     │ ← Additional layers
└─────────────────────────────┘
```

### ✅ Pass Criteria
- Layer 0 shows "Green Screen Videos"
- Layer 1 shows "Shaders & Transitions"
- Labels are clearly visible

---

## Test 2: Drop Video on Layer 0 (Should Work)

### Steps
1. Find a video file in the "Videos" section
2. Drag the video file
3. Drop it on Layer 0 (Green Screen Videos)

### Expected Results
- ✅ Video is accepted
- ✅ Video appears on Layer 0 timeline
- ✅ No error message

### ❌ Fail Indicators
- Error message appears
- Video is not added to timeline
- Video appears on wrong layer

---

## Test 3: Drop Shader on Layer 0 (Should Fail)

### Steps
1. Find a shader file in the "Shaders" section
2. Drag the shader file
3. Drop it on Layer 0 (Green Screen Videos)

### Expected Results
- ❌ Shader is rejected
- ❌ Shader is NOT added to timeline
- ✅ Error message appears:
  ```
  Layer 0 (Green Screen Videos) only accepts videos.
  Please drop shaders and transitions on Layer 1.
  ```

### ✅ Pass Criteria
- Error message displays "Layer 0" (not "Layer 1")
- Error message mentions "Layer 1" as the correct target
- Shader is not added to Layer 0

### ❌ Fail Indicators
- Shader is added to Layer 0
- No error message appears
- Error message shows wrong layer numbers

---

## Test 4: Drop Transition on Layer 0 (Should Fail)

### Steps
1. Find a transition file in the "Transitions" section
2. Drag the transition file
3. Drop it on Layer 0 (Green Screen Videos)

### Expected Results
- ❌ Transition is rejected
- ❌ Transition is NOT added to timeline
- ✅ Error message appears:
  ```
  Layer 0 (Green Screen Videos) only accepts videos.
  Please drop shaders and transitions on Layer 1.
  ```

### ✅ Pass Criteria
- Error message displays "Layer 0" (not "Layer 1")
- Error message mentions "Layer 1" as the correct target
- Transition is not added to Layer 0

---

## Test 5: Drop Shader on Layer 1 (Should Work)

### Steps
1. Find a shader file in the "Shaders" section
2. Drag the shader file
3. Drop it on Layer 1 (Shaders & Transitions)

### Expected Results
- ✅ Shader is accepted
- ✅ Shader appears on Layer 1 timeline
- ✅ No error message

### ❌ Fail Indicators
- Error message appears
- Shader is not added to timeline
- Shader appears on wrong layer

---

## Test 6: Drop Transition on Layer 1 (Should Work)

### Steps
1. Find a transition file in the "Transitions" section
2. Drag the transition file
3. Drop it on Layer 1 (Shaders & Transitions)

### Expected Results
- ✅ Transition is accepted
- ✅ Transition appears on Layer 1 timeline
- ✅ No error message

### ❌ Fail Indicators
- Error message appears
- Transition is not added to timeline
- Transition appears on wrong layer

---

## Test 7: Drop Video on Layer 1 (Should Fail)

### Steps
1. Find a video file in the "Videos" section
2. Drag the video file
3. Drop it on Layer 1 (Shaders & Transitions)

### Expected Results
- ❌ Video is rejected
- ❌ Video is NOT added to timeline
- ✅ Error message appears:
  ```
  Layer 1 (Shaders & Transitions) only accepts shaders and transitions.
  Please drop videos on Layer 0.
  ```

### ✅ Pass Criteria
- Error message displays "Layer 1" (not "Layer 2")
- Error message mentions "Layer 0" as the correct target
- Video is not added to Layer 1

### ❌ Fail Indicators
- Video is added to Layer 1
- No error message appears
- Error message shows wrong layer numbers

---

## Test 8: Create Complete Timeline

### Steps
1. Load an audio file
2. Add a video to Layer 0
3. Add a shader to Layer 1
4. Verify timeline looks correct

### Expected Results
```
┌─────────────────────────────────────────────────┐
│ Music: [████████████████████████████████████]   │
├─────────────────────────────────────────────────┤
│ Green Screen Videos: [dancer.mp4]              │ ← Layer 0
├─────────────────────────────────────────────────┤
│ Shaders & Transitions: [fractal.glsl]          │ ← Layer 1
└─────────────────────────────────────────────────┘
```

### ✅ Pass Criteria
- Video appears on Layer 0
- Shader appears on Layer 1
- Timeline is visually clear
- Elements are aligned correctly

---

## Test 9: Render Video

### Steps
1. Create timeline with:
   - Layer 0: Green screen video
   - Layer 1: Shader
2. Click "Render Video"
3. Wait for rendering to complete
4. Check console logs

### Expected Console Output
```
--- Rendering Layer 1: Shaders & Transitions ---
Found 1 elements on Layer 1
Rendering shader timeline with transitions...
✓ Layer 1 (shaders) rendering complete

--- Rendering Layer 0: Green Screen Videos ---
Found 1 video elements on Layer 0
Layer 0 (green screen) total frames: 900
✓ Layer 0 (green screen) rendering complete

--- Compositing Layers ---
Compositing Layer 1 (shaders - background) + Layer 0 (green screen - overlay with transparency)
```

### ✅ Pass Criteria
- Layer 1 renders first
- Layer 0 renders second
- Log messages show correct layer names
- No errors in console

---

## Test 10: Verify Final Video

### Steps
1. After rendering completes, open the output video
2. Verify visual composition

### Expected Results
- ✅ Green screen video appears on top
- ✅ Shader background visible through transparent areas
- ✅ Green pixels removed from video
- ✅ Audio synchronized correctly

### Visual Check
```
┌─────────────────────────────────────┐
│                                     │
│   👤 Dancer (from green screen)    │
│   on top of                         │
│   🌀 Animated Shader Background    │
│                                     │
└─────────────────────────────────────┘
```

---

## Test 11: Empty Layer 0

### Steps
1. Create timeline with:
   - Layer 0: Empty (no videos)
   - Layer 1: Shader only
2. Click "Render Video"
3. Check console logs

### Expected Console Output
```
--- Rendering Layer 1: Shaders & Transitions ---
Found 1 elements on Layer 1
✓ Layer 1 (shaders) rendering complete

--- Rendering Layer 0: Green Screen Videos ---
No elements on Layer 0, skipping green screen processing

--- Compositing Layers ---
No Layer 0 (green screen) content, using Layer 1 (shaders) only
```

### ✅ Pass Criteria
- Layer 0 processing is skipped
- Only shader renders
- No errors occur
- Final video is shader only

---

## Test 12: Shader Transitions

### Steps
1. Create timeline with:
   - Layer 0: Empty
   - Layer 1: Shader A → Transition → Shader B
2. Click "Render Video"
3. Verify transition works

### Expected Results
- ✅ Shader A renders
- ✅ Transition effect plays
- ✅ Shader B renders
- ✅ Smooth transition between shaders

---

## Quick Test Checklist

Use this checklist for rapid testing:

### Drag & Drop Validation
- [ ] Video → Layer 0 = ✅ Accepted
- [ ] Video → Layer 1 = ❌ Rejected (correct error message)
- [ ] Shader → Layer 0 = ❌ Rejected (correct error message)
- [ ] Shader → Layer 1 = ✅ Accepted
- [ ] Transition → Layer 0 = ❌ Rejected (correct error message)
- [ ] Transition → Layer 1 = ✅ Accepted

### Error Messages
- [ ] Layer 0 error shows "Layer 0" (not "Layer 1")
- [ ] Layer 1 error shows "Layer 1" (not "Layer 2")
- [ ] Error messages provide correct guidance

### Rendering
- [ ] Layer 1 renders first (shaders)
- [ ] Layer 0 renders second (green screen)
- [ ] Log messages show correct layer names
- [ ] Final video has correct layer order

### Visual Output
- [ ] Green screen on top
- [ ] Shader visible through transparency
- [ ] No visual artifacts
- [ ] Audio synchronized

---

## Troubleshooting

### Issue: Error messages show wrong layer numbers
**Solution**: Clear browser cache and refresh (Ctrl+Shift+R)

### Issue: Drag & drop not working at all
**Solution**: Check browser console for JavaScript errors

### Issue: Video renders incorrectly
**Solution**: Verify manifest JSON has correct layer assignments

### Issue: Layers appear in wrong order
**Solution**: Re-create timeline from scratch

---

## Test Results Template

Use this template to document your test results:

```
Date: ___________
Tester: ___________

Test 1 (Layer Labels):           [ ] Pass  [ ] Fail
Test 2 (Video → Layer 0):         [ ] Pass  [ ] Fail
Test 3 (Shader → Layer 0):        [ ] Pass  [ ] Fail
Test 4 (Transition → Layer 0):    [ ] Pass  [ ] Fail
Test 5 (Shader → Layer 1):        [ ] Pass  [ ] Fail
Test 6 (Transition → Layer 1):    [ ] Pass  [ ] Fail
Test 7 (Video → Layer 1):         [ ] Pass  [ ] Fail
Test 8 (Complete Timeline):       [ ] Pass  [ ] Fail
Test 9 (Render Video):            [ ] Pass  [ ] Fail
Test 10 (Verify Final Video):     [ ] Pass  [ ] Fail
Test 11 (Empty Layer 0):          [ ] Pass  [ ] Fail
Test 12 (Shader Transitions):     [ ] Pass  [ ] Fail

Overall Result: [ ] All Pass  [ ] Some Failures

Notes:
_________________________________________________
_________________________________________________
_________________________________________________
```

---

**Testing Guide Complete** ✅

Use this guide to thoroughly test the layer swap implementation and verify that all functionality works as expected.

