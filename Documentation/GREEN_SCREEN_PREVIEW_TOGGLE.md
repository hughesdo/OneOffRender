# Green Screen Video Preview Toggle Feature

## Overview
This feature allows users to toggle the visibility of green screen videos in the timeline preview without affecting the actual video rendering. It provides a convenient way to preview the final rendered composite video without green screen overlays.

---

## Features

### 1. **Manual Toggle via Right-Click Menu**
- Right-click on any green video bar (Layer 0) to open a context menu
- Menu shows current preview state: "✓ Preview Enabled" or "☐ Preview Disabled"
- Click to toggle between enabled/disabled states
- Menu also includes "Delete" option

### 2. **Auto-Disable After Render Completion**
- When "Render Video" completes successfully, all green screen video previews are automatically disabled
- This allows immediate preview of the rendered composite video without green screen overlays
- Green bars remain on the timeline with visual indication of disabled state

### 3. **Auto-Enable Before Next Render**
- When "Render Video" is clicked again, all green screen video previews are automatically re-enabled
- Ensures green screen videos are included in the new render
- Happens before the render process starts

### 4. **Visual Indicator**
- Green video bars with preview disabled show:
  - 50% opacity (semi-transparent)
  - Diagonal striped pattern overlay
  - Dashed border instead of solid
- Provides clear visual feedback of disabled state

---

## User Workflow

### Typical Usage:
1. User adds green screen videos to Layer 0
2. User arranges timeline and previews with green screen overlays visible
3. User clicks "Render Video" → composite video is created
4. **System auto-disables all green screen previews** when render completes
5. User can now preview the rendered composite without green screen overlays
6. User makes adjustments to timeline
7. User clicks "Render Video" again
8. **System auto-enables all green screen previews** before rendering
9. New composite video is rendered with green screen videos included

### Manual Control:
- User can manually toggle individual green screen videos on/off at any time
- Right-click on green video bar → Toggle Preview
- Useful for comparing with/without specific green screen elements

---

## Technical Implementation

### Files Modified

#### **1. `web_editor/static/js/timeline.js`**

**New Methods:**
- `showGreenScreenContextMenu(e, element)` - Displays context menu for green screen videos
- `toggleGreenScreenPreview(elementId)` - Toggles preview state for a single element
- `disableAllGreenScreenPreviews()` - Disables preview for all green screen videos
- `enableAllGreenScreenPreviews()` - Enables preview for all green screen videos

**Modified Methods:**
- `createElementDiv(element)` - Adds `preview-disabled` class when `previewEnabled === false`
- Context menu event listener - Shows custom menu for Layer 0 videos, standard delete for others

**Data Structure:**
- Added `previewEnabled` property to timeline elements (boolean)
- Default: `true` (enabled) if not set
- Only applies to Layer 0 video elements

#### **2. `web_editor/static/js/editor.js`**

**New Methods:**
- `onGreenScreenPreviewToggled(element)` - Handles preview toggle events from timeline

**Modified Methods:**
- `updateGreenScreenPreview(currentTime)` - Checks `previewEnabled` flag before showing preview
- `renderProject()` - Calls `enableAllGreenScreenPreviews()` before starting render
- `pollRenderStatus()` - Calls `disableAllGreenScreenPreviews()` after render completes

**Logic:**
- Preview only shows if `element.previewEnabled !== false`
- When toggled off during playback, immediately stops preview
- When toggled on during playback, immediately starts preview

#### **3. `web_editor/static/css/editor.css`**

**New Styles:**
```css
/* Green screen video with preview disabled - ghostly appearance */
.timeline-element.video.preview-disabled {
    opacity: 0.5;
    background: repeating-linear-gradient(
        45deg,
        var(--video-color),
        var(--video-color) 10px,
        rgba(56, 142, 60, 0.3) 10px,
        rgba(56, 142, 60, 0.3) 20px
    );
    border: 2px dashed #388E3C;
}

/* Green Screen Context Menu */
.greenscreen-context-menu {
    background-color: var(--bg-dark);
    border: 1px solid var(--border-color);
    border-radius: 4px;
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.5);
    min-width: 180px;
    padding: 4px 0;
    font-size: 14px;
}

.context-menu-item {
    padding: 8px 16px;
    cursor: pointer;
    color: var(--text-color);
    transition: background-color 0.2s;
}

.context-menu-item:hover {
    background-color: var(--bg-light);
}

.context-menu-separator {
    height: 1px;
    background-color: var(--border-color);
    margin: 4px 0;
}
```

---

## Important Notes

### Scope Limitations
- **Only applies to Layer 0 (Green Screen Videos)**
- Blue shader bars and orange transition bars are NOT affected
- Standard right-click delete still works for shaders and transitions

### GUI-Only Feature
- This is purely a **web GUI preview feature**
- Does NOT modify `render_timeline.py` or `render_shader.py`
- The actual video rendering pipeline is completely untouched
- `previewEnabled` flag is NOT sent to the backend during rendering

### Preview vs Rendering
- **Preview disabled** = Video not shown in GUI preview overlay
- **Rendering** = Always includes all green screen videos on Layer 0, regardless of preview state
- The `previewEnabled` flag only affects the GUI preview, not the final render

### State Persistence
- Preview state is saved in timeline undo/redo history
- State persists across timeline edits
- State is reset (all enabled) when starting a new render

---

## Testing Checklist

### Manual Toggle
- [ ] Right-click on green video bar shows context menu
- [ ] Context menu shows correct current state (✓ or ☐)
- [ ] Clicking "Toggle Preview" changes state
- [ ] Visual styling updates immediately (opacity, stripes, dashed border)
- [ ] Preview stops/starts immediately when toggled during playback
- [ ] Delete option still works from context menu

### Auto-Disable After Render
- [ ] Render video with green screen elements
- [ ] After render completes, all green bars show disabled styling
- [ ] Preview shows rendered composite without green screen overlays
- [ ] Green bars remain on timeline (not deleted)

### Auto-Enable Before Render
- [ ] With green screen previews disabled, click "Render Video"
- [ ] All green bars return to normal styling before render starts
- [ ] Rendered video includes all green screen elements

### Edge Cases
- [ ] Toggle preview while video is playing
- [ ] Toggle preview while video is paused
- [ ] Multiple green screen videos on timeline
- [ ] Undo/redo preserves preview state
- [ ] Context menu closes when clicking outside
- [ ] Right-click on shader/transition still shows delete dialog

---

## Future Enhancements

### Potential Improvements:
1. **Keyboard shortcut** - Press 'P' to toggle preview for selected element
2. **Bulk toggle** - Shift+right-click to toggle all green screen videos at once
3. **Preview opacity slider** - Adjust transparency of green screen overlay (0-100%)
4. **Color overlay** - Show green screen videos with colored tint when disabled
5. **Timeline indicator** - Small icon on green bar showing preview state

---

## Troubleshooting

### Preview not hiding when disabled:
- Check browser console for errors
- Verify `previewEnabled` property is set to `false` in timeline element
- Ensure `updateGreenScreenPreview()` is checking the flag correctly

### Context menu not appearing:
- Verify right-click is on a Layer 0 video element
- Check that `showGreenScreenContextMenu()` is being called
- Inspect DOM for `.greenscreen-context-menu` element

### Auto-disable not working after render:
- Verify `disableAllGreenScreenPreviews()` is called in `pollRenderStatus()`
- Check that render status is 'completed'
- Ensure timeline elements are being updated and re-rendered

### Visual styling not updating:
- Check that `preview-disabled` class is being added to element div
- Verify CSS is loaded correctly
- Inspect element in browser dev tools

---

**Last Updated**: 2025-10-18  
**Status**: ✅ Implemented and Ready for Testing

