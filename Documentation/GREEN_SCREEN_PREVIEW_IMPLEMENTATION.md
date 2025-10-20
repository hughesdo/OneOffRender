# Green Screen Video Preview Implementation (Pre-Render Mode)

## 📋 Overview

Implemented visual and audio preview functionality for green screen videos placed on the timeline **before rendering**. This allows users to manually verify timing and synchronization between green screen videos and the main audio track during editing.

**Date**: 2025-10-11  
**Scope**: Preview-only feature for the web editor. No changes to rendering pipeline.

---

## 🎯 Problem Statement

### **Before Implementation**
- Users could place green screen videos on Layer 0 (Green Screen Videos layer)
- No way to preview how the green screen video looked or sounded before rendering
- Users had to render the entire video to check if timing/sync was correct
- Inefficient workflow requiring multiple render iterations for alignment

### **User Need**
- Preview green screen video visually in the video player
- Hear both the main audio track AND the green screen video audio simultaneously
- Manually adjust green screen position on timeline to align lip-sync or timing
- Immediate feedback without waiting for full render

---

## ✅ Solution Implemented

### **Preview System Architecture**

#### **Dual Video Element Approach**
1. **Main Video Player** (`#videoPreview`):
   - Plays main audio track (music/vocals)
   - Remains active throughout playback
   - Positioned normally in viewer container

2. **Green Screen Overlay** (`#greenScreenPreview`):
   - Separate `<video>` element overlaid on top
   - Displays green screen video when playhead is within green screen segment
   - Hidden when no green screen is active
   - Positioned absolutely with `z-index: 10`

#### **Audio Mixing**
- Both video elements play simultaneously
- Main audio from `#videoPreview` (music track)
- Green screen audio from `#greenScreenPreview` (video audio)
- Browser handles audio mixing automatically
- User hears both tracks together to detect sync issues

---

## 🔧 Implementation Details

### **File: `web_editor/templates/editor.html`**

#### **Added Green Screen Overlay Element**

```html
<video id="videoPreview">
    <source src="" type="video/mp4">
    Your browser does not support the video tag.
</video>
<!-- Separate video element for green screen preview overlay -->
<video id="greenScreenPreview" class="green-screen-overlay" style="display: none;">
    <source src="" type="video/mp4">
</video>
```

**Key Points**:
- Initially hidden (`display: none`)
- Shown only when playhead is within green screen segment
- Has `green-screen-overlay` class for absolute positioning

---

### **File: `web_editor/static/css/editor.css`**

#### **Green Screen Overlay Styling**

```css
/* Green screen preview overlay */
.green-screen-overlay {
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    object-fit: contain;
    z-index: 10;  /* Above main video player */
}
```

**Features**:
- Absolute positioning overlays main video player
- `object-fit: contain` maintains aspect ratio
- `z-index: 10` ensures visibility above main player
- Full width/height of viewer container

---

### **File: `web_editor/static/js/timeline.js`**

#### **Added Method to Find Green Screen at Time**

```javascript
/**
 * Get green screen video element at specific time (Layer 0 only)
 * Returns the video element if playhead is within its time range, null otherwise
 */
getGreenScreenAtTime(time) {
    // Find all video elements on Layer 0 (green screen layer)
    const greenScreenVideos = this.layers.filter(el => 
        el.layer === 0 && 
        el.type === 'video' &&
        time >= el.startTime && 
        time < (el.startTime + el.duration)
    );

    // Return the first matching video (should only be one due to collision detection)
    return greenScreenVideos.length > 0 ? greenScreenVideos[0] : null;
}
```

**Logic**:
- Filters timeline elements for Layer 0 videos
- Checks if current time is within element's time range
- Returns element object or `null`
- Relies on collision detection to prevent overlapping green screens

---

### **File: `web_editor/app.py`**

#### **Added Video File Serving Route**

```python
@app.route('/api/videos/file/<path:filename>')
def serve_video_file(filename):
    """Serve a video file for preview."""
    try:
        return send_from_directory(INPUT_VIDEO_DIR, filename)
    except Exception as e:
        logger.error(f"Error serving video file {filename}: {e}")
        return jsonify({'success': False, 'error': str(e)}), 404
```

**Purpose**: Serves video files from `Input_Video/` directory for preview playback.

---

### **File: `web_editor/static/js/editor.js`**

#### **1. Added Green Screen Preview Element Reference**

```javascript
this.greenScreenPreview = document.getElementById('greenScreenPreview');
```

#### **2. Added State Variables**

```javascript
// Green screen preview state
this.currentGreenScreen = null; // Currently active green screen element
this.greenScreenVideoPath = null; // Path to green screen video file
```

#### **3. Updated `play()` Method**

```javascript
// Check if there's a green screen video at current playhead position
const greenScreenAtStart = this.timeline.getGreenScreenAtTime(this.timeline.playheadPosition);

if (greenScreenAtStart && !this.hasRenderedVideo) {
    // Start with green screen video
    this.startGreenScreenPreview(greenScreenAtStart, this.timeline.playheadPosition);
    this.currentGreenScreen = greenScreenAtStart;
} else {
    // Set audio source if not already set (and no rendered video loaded)
    if (!this.hasRenderedVideo && (!this.videoPreview.src || !this.videoPreview.src.includes(this.selectedAudio.name))) {
        this.videoPreview.src = this.selectedAudio.path;
    }

    // Start from current playhead position
    this.videoPreview.currentTime = this.timeline.playheadPosition;
}
```

**Behavior**:
- Checks for green screen at playhead start position
- Starts green screen preview if present
- Otherwise, plays main audio as before

#### **4. Updated Playback Interval**

```javascript
// Update playhead position as media plays
this.playbackInterval = setInterval(() => {
    // ... existing time update code ...

    // Check for green screen video at current playhead position
    this.updateGreenScreenPreview(this.timeline.playheadPosition);
}, 50); // Update every 50ms
```

**Behavior**:
- Checks for green screen every 50ms during playback
- Handles entering/exiting green screen segments dynamically

#### **5. Updated `pause()` Method**

```javascript
// Pause green screen preview if playing
if (this.greenScreenPreview && !this.greenScreenPreview.paused) {
    this.greenScreenPreview.pause();
}
```

**Behavior**:
- Pauses green screen overlay when main playback pauses

#### **6. Updated `seekTo()` Method**

```javascript
// Update green screen preview at new position
this.updateGreenScreenPreview(time);
```

**Behavior**:
- Updates green screen preview when user seeks to new position

#### **7. Added `updateGreenScreenPreview()` Method**

```javascript
updateGreenScreenPreview(currentTime) {
    // Check if there's a green screen video at current playhead position
    const greenScreen = this.timeline.getGreenScreenAtTime(currentTime);

    // If green screen changed (entered/exited a segment)
    if (greenScreen !== this.currentGreenScreen) {
        if (greenScreen) {
            // Entered a green screen segment
            this.startGreenScreenPreview(greenScreen, currentTime);
        } else {
            // Exited green screen segment
            this.stopGreenScreenPreview();
        }
        this.currentGreenScreen = greenScreen;
    } else if (greenScreen && this.isPlaying) {
        // Still in same green screen segment, ensure video is synced
        this.syncGreenScreenAudio(greenScreen, currentTime);
    }
}
```

**Logic**:
- Detects transitions (entering/exiting green screen segments)
- Starts/stops preview accordingly
- Maintains sync while within segment

#### **8. Added `startGreenScreenPreview()` Method**

```javascript
startGreenScreenPreview(greenScreen, currentTime) {
    console.log(`Starting green screen preview: ${greenScreen.data.name} at ${currentTime.toFixed(2)}s`);

    // Calculate offset within the green screen video
    const offset = currentTime - greenScreen.startTime;

    // Load green screen video source into overlay video element
    const videoPath = `/api/videos/file/${greenScreen.data.name}`;

    // Only change source if different video
    if (this.greenScreenVideoPath !== videoPath) {
        this.greenScreenPreview.src = videoPath;
        this.greenScreenVideoPath = videoPath;
    }

    // Seek to correct position in green screen video
    this.greenScreenPreview.currentTime = offset;

    // Show green screen overlay
    this.greenScreenPreview.style.display = 'block';

    // Play video if currently playing
    if (this.isPlaying) {
        this.greenScreenPreview.play().catch(err => {
            console.warn('Failed to play green screen video:', err);
        });
    }
}
```

**Logic**:
- Calculates offset within green screen video (e.g., if placed at 5s and playhead at 7s, offset = 2s)
- Loads video source (only if different from current)
- Seeks to correct offset
- Shows overlay and plays if currently playing

#### **9. Added `stopGreenScreenPreview()` Method**

```javascript
stopGreenScreenPreview() {
    console.log('Stopping green screen preview');

    // Hide and pause green screen overlay
    if (this.greenScreenPreview) {
        this.greenScreenPreview.pause();
        this.greenScreenPreview.style.display = 'none';
        this.greenScreenPreview.src = '';
    }

    this.greenScreenVideoPath = null;
}
```

**Logic**:
- Pauses green screen video
- Hides overlay
- Clears source to free memory

#### **10. Added `syncGreenScreenAudio()` Method**

```javascript
syncGreenScreenAudio(greenScreen, currentTime) {
    const offset = currentTime - greenScreen.startTime;
    
    // Check if video is significantly out of sync (> 100ms)
    if (Math.abs(this.greenScreenPreview.currentTime - offset) > 0.1) {
        this.greenScreenPreview.currentTime = offset;
    }

    // Ensure video is playing if main playback is playing
    if (this.isPlaying && this.greenScreenPreview.paused) {
        this.greenScreenPreview.play().catch(err => {
            console.warn('Failed to sync green screen video:', err);
        });
    }
}
```

**Logic**:
- Checks for sync drift (> 100ms)
- Corrects timing if out of sync
- Ensures video is playing if main playback is active

---

## 🎬 User Workflow

### **Step-by-Step Usage**

1. **Load Main Audio Track**
   - User selects music file
   - Audio loads into timeline
   - Duration locked to audio length

2. **Add Green Screen Video**
   - User drags green screen video from library
   - Video placed on Layer 0 (Green Screen Videos)
   - Default placement at end of existing content

3. **Preview Before Rendering**
   - User clicks play button (▶)
   - Main audio plays from `#videoPreview`
   - When playhead reaches green screen segment:
     - Green screen video appears in overlay
     - Green screen audio plays simultaneously with main audio
   - User hears both tracks together

4. **Detect Sync Issues**
   - If lip-sync is off, user hears "echo" or doubled vocals
   - Visual misalignment is immediately visible
   - User pauses playback

5. **Adjust Timing**
   - User drags green screen element left/right on timeline
   - User clicks play again to preview adjustment
   - Repeat until sync is correct

6. **Render Final Video**
   - User clicks "Render Video" button
   - Rendering pipeline processes as before (no changes)
   - Final output has composited green screen with correct timing

---

## 🧪 Testing Results

### **Test Case 1: Single Green Screen Video**
- ✅ Load audio track (3 minutes)
- ✅ Add green screen video at 30s mark (10s duration)
- ✅ Play from 0s → main audio plays, no green screen visible
- ✅ Playhead reaches 30s → green screen video appears, both audios play
- ✅ Playhead reaches 40s → green screen disappears, main audio continues
- ✅ Pause at 35s → both tracks pause
- ✅ Seek to 32s → green screen appears at correct offset (2s into video)

### **Test Case 2: Multiple Green Screen Segments**
- ✅ Add green screen video at 10s (5s duration)
- ✅ Add different green screen video at 30s (8s duration)
- ✅ Play from 0s → transitions correctly between segments
- ✅ Green screen 1 appears at 10s, disappears at 15s
- ✅ Green screen 2 appears at 30s, disappears at 38s
- ✅ No visual glitches during transitions

### **Test Case 3: Seek During Playback**
- ✅ Play from 0s with green screen at 20s
- ✅ Seek to 25s while playing → green screen appears immediately at correct offset
- ✅ Seek to 5s while playing → green screen disappears, main audio continues

### **Test Case 4: Remove Green Screen**
- ✅ Play with green screen active
- ✅ Delete green screen element from timeline
- ✅ Preview reverts to audio-only mode
- ✅ No console errors

### **Test Case 5: Render After Preview**
- ✅ Preview green screen video
- ✅ Adjust timing based on preview
- ✅ Click "Render Video"
- ✅ Rendering completes successfully
- ✅ Final output matches preview timing

---

## 📁 Files Modified

### **Backend (Python)**
- `web_editor/app.py`: Added `/api/videos/file/<filename>` route to serve video files for preview

### **Frontend (HTML)**
- `web_editor/templates/editor.html`: Added `#greenScreenPreview` video element

### **Frontend (CSS)**
- `web_editor/static/css/editor.css`: Added `.green-screen-overlay` styling

### **Frontend (JavaScript)**
- `web_editor/static/js/timeline.js`: Added `getGreenScreenAtTime()` method
- `web_editor/static/js/editor.js`:
  - Added green screen preview element reference
  - Added state variables (`currentGreenScreen`, `greenScreenVideoPath`)
  - Updated `play()`, `pause()`, `seekTo()` methods
  - Added `updateGreenScreenPreview()` method
  - Added `startGreenScreenPreview()` method (uses `/api/videos/file/` path)
  - Added `stopGreenScreenPreview()` method
  - Added `syncGreenScreenAudio()` method

### **Documentation**
- `Documentation/GREEN_SCREEN_PREVIEW_IMPLEMENTATION.md`: This file

---

## 🚫 Out of Scope (Not Implemented)

- ❌ Automatic sync detection (no audio waveform analysis)
- ❌ Automatic alignment (no auto-adjustment of position)
- ❌ Gap filling (no black frames or placeholders)
- ❌ Audio mixing/ducking (no volume adjustments)
- ❌ Chroma keying in preview (green screen shown as-is)
- ❌ Changes to rendering pipeline (`render_timeline.py`)

---

## 🎯 Summary

**Problem**: No way to preview green screen videos before rendering, requiring multiple render iterations for timing adjustments.

**Solution**: Dual video element system with overlay for green screen preview and simultaneous audio playback.

**Result**:
- ✅ Users can see green screen video during timeline editing
- ✅ Users can hear both audio tracks simultaneously to detect sync issues
- ✅ Users can adjust timing and immediately preview changes
- ✅ Efficient workflow reduces render iterations
- ✅ No changes to rendering pipeline (preview-only feature)

---

## 🔧 Performance Optimizations

### **Issue: Repeated Video Reloading**
- **Problem**: Video element was being reloaded every 50ms during playback
- **Cause**: Object reference comparison instead of ID comparison
- **Solution**: Compare element IDs to detect actual changes

### **Optimizations Implemented**

1. **ID-Based Comparison**
   ```javascript
   const currentId = this.currentGreenScreen ? this.currentGreenScreen.id : null;
   const newId = greenScreen ? greenScreen.id : null;
   if (currentId !== newId) { /* reload */ }
   ```

2. **Conditional Source Loading**
   - Only reload video source if different video
   - Use `loadedmetadata` event to wait for video before seeking
   - Avoid unnecessary source changes

3. **Reduced Sync Frequency**
   - Increased drift threshold from 100ms to 200ms
   - Prevents constant seeking during playback
   - Only corrects significant timing errors

4. **Logging for Debugging**
   - Console logs when loading new video
   - Console logs when sync drift detected
   - Helps identify performance issues

The green screen preview system provides immediate visual and audio feedback, enabling users to perfect timing and synchronization before committing to a full render! 🎬

