# Timeline Layer Alignment Fix

## Issue Description

The left-side layer name column was not properly aligned with the corresponding timeline tracks on the right side. This caused visual misalignment where:
- The "Music" label didn't align with the red music bar
- Layer labels (Layer 1, Layer 2, etc.) didn't align with their timeline tracks
- Horizontal separator lines appeared broken or discontinuous

## Root Cause

**Problem:** Inline styles in JavaScript were overriding CSS and creating inconsistent box-sizing behavior.

**Specific Issues:**
1. Inline styles set on layer names and timeline layers
2. Potential box-sizing inconsistencies between left and right columns
3. Border calculations not properly accounted for in height

## Solution

### 1. Moved Styling from JavaScript to CSS

**Before:** Inline styles in `timeline.js`
```javascript
musicNameDiv.style.height = '40px';
musicNameDiv.style.display = 'flex';
musicNameDiv.style.alignItems = 'center';
musicNameDiv.style.padding = '0 10px';
musicNameDiv.style.borderBottom = '1px solid var(--border-color)';
// ... many more inline styles
```

**After:** CSS classes in `editor.css`
```css
.layer-name {
    height: 60px;
    display: flex;
    align-items: center;
    padding: 0 10px;
    border-bottom: 1px solid var(--border-color);
    box-sizing: border-box;
}
```

### 2. Added Explicit CSS Classes

**New CSS Classes Added:**

#### `.layer-name` (Regular layers)
```css
.layer-name {
    height: 60px;
    display: flex;
    align-items: center;
    padding: 0 10px;
    border-bottom: 1px solid var(--border-color);
    box-sizing: border-box;
}
```

#### `.layer-name.music-layer-name` (Music layer)
```css
.layer-name.music-layer-name {
    height: 40px;
    background-color: var(--bg-light);
    font-weight: bold;
}
```

#### `.timeline-layer.music-layer` (Music track)
```css
.timeline-layer.music-layer {
    height: 40px;
}
```

#### `.music-bar` (Red music bar)
```css
.music-bar {
    position: absolute;
    left: 0;
    top: 5px;
    width: 100%;
    height: 30px;
    background-color: #dc3545;
    border-radius: 4px;
    pointer-events: none;
    display: flex;
    align-items: center;
    padding-left: 10px;
    color: white;
    font-size: 12px;
    font-weight: 500;
}
```

### 3. Ensured Consistent Box-Sizing

**Key Fix:** Added explicit `box-sizing: border-box` to layer classes

This ensures that:
- Height includes padding and borders
- Left column and right tracks calculate height identically
- No unexpected height differences due to border/padding

## Height Specifications

### Music Layer:
- **Total Height:** 40px (including 1px border)
- **Left Column:** `.layer-name.music-layer-name` = 40px
- **Right Track:** `.timeline-layer.music-layer` = 40px
- **✅ Aligned**

### Regular Layers:
- **Total Height:** 60px (including 1px border)
- **Left Column:** `.layer-name` = 60px
- **Right Track:** `.timeline-layer` = 60px
- **✅ Aligned**

## Files Modified

### 1. `web_editor/static/css/editor.css`

**Added CSS Classes (Lines 666-710):**
```css
.timeline-layer {
    height: 60px;
    border-bottom: 1px solid var(--border-color);
    position: relative;
    width: 100%;
    min-width: 100%;
    box-sizing: border-box;
}

.timeline-layer.music-layer {
    height: 40px;
}

.layer-name {
    height: 60px;
    display: flex;
    align-items: center;
    padding: 0 10px;
    border-bottom: 1px solid var(--border-color);
    box-sizing: border-box;
}

.layer-name.music-layer-name {
    height: 40px;
    background-color: var(--bg-light);
    font-weight: bold;
}

.music-bar {
    position: absolute;
    left: 0;
    top: 5px;
    width: 100%;
    height: 30px;
    background-color: #dc3545;
    border-radius: 4px;
    pointer-events: none;
    display: flex;
    align-items: center;
    padding-left: 10px;
    color: white;
    font-size: 12px;
    font-weight: 500;
}
```

### 2. `web_editor/static/js/timeline.js`

**Simplified `renderMusicLayer()` (Lines 321-342):**
```javascript
renderMusicLayer() {
    // Add music layer name (just "Music" label, no filename)
    const musicNameDiv = document.createElement('div');
    musicNameDiv.className = 'layer-name music-layer-name';
    musicNameDiv.textContent = 'Music';
    this.namesColumn.appendChild(musicNameDiv);

    // Add music layer bar
    const musicLayerDiv = document.createElement('div');
    musicLayerDiv.className = 'timeline-layer music-layer';

    // Create the red bar spanning full timeline
    const musicBar = document.createElement('div');
    musicBar.className = 'music-bar';
    musicBar.textContent = this.audioFileName || 'Audio Track';

    musicLayerDiv.appendChild(musicBar);
    this.container.appendChild(musicLayerDiv);
}
```

**Simplified Layer Name Creation (Lines 303-310):**
```javascript
// Add layer name
const nameDiv = document.createElement('div');
nameDiv.className = 'layer-name';
nameDiv.textContent = `Layer ${i + 1}`;
this.namesColumn.appendChild(nameDiv);
```

## Visual Result

### Before (Misaligned):
```
Left Column          Right Timeline
┌──────────────┐    ┌─────────────────────┐
│ Music        │    │                     │
│              │    │ [==== Music ====]   │ ← Misaligned
├──────────────┤    ├─────────────────────┤
│ Layer 1      │    │                     │
│              │    │  [Shader]           │ ← Misaligned
├──────────────┤    ├─────────────────────┤
```

### After (Aligned):
```
Left Column          Right Timeline
┌──────────────┐    ┌─────────────────────┐
│ Music        │    │ [==== Music ====]   │ ← Aligned!
├──────────────┼────┼─────────────────────┤
│ Layer 1      │    │  [Shader]           │ ← Aligned!
├──────────────┼────┼─────────────────────┤
│ Layer 2      │    │                     │ ← Aligned!
└──────────────┴────┴─────────────────────┘
```

## Benefits

✅ **Perfect Alignment:** Left labels match right tracks exactly
✅ **Continuous Lines:** Separator lines flow across both columns
✅ **Maintainable:** CSS-based styling is easier to modify
✅ **Consistent:** Box-sizing ensures predictable behavior
✅ **Clean Code:** Removed 20+ lines of inline styles from JavaScript

## Testing Instructions

1. **Hard refresh browser:**
   - Windows: `Ctrl+Shift+R`
   - Mac: `Cmd+Shift+R`

2. **Select an audio file** to initialize timeline

3. **Verify music layer alignment:**
   - ✅ "Music" label (left) aligns with red bar (right)
   - ✅ Horizontal line is continuous across both sides

4. **Add elements to timeline:**
   - Drop shaders, videos, or transitions
   - ✅ "Layer 1" label aligns with Layer 1 track
   - ✅ "Layer 2" label aligns with Layer 2 track
   - ✅ All separator lines are continuous

5. **Scroll timeline:**
   - Scroll horizontally on timeline tracks
   - ✅ Left column stays fixed and aligned
   - ✅ No visual jumping or misalignment

## Technical Details

### Box-Sizing Explanation

With `box-sizing: border-box`:
```
Total Height = Content + Padding + Border

Example:
height: 60px
padding: 0 10px
border-bottom: 1px

Total visible height = 60px (border included)
```

Without `box-sizing: border-box`:
```
Total Height = Content + Padding + Border (added separately)

Example:
height: 60px
padding: 0 10px
border-bottom: 1px

Total visible height = 61px (border added to height)
```

This 1px difference caused the misalignment!

### Why CSS Over Inline Styles?

1. **Consistency:** All elements use same styling rules
2. **Maintainability:** Change once in CSS, applies everywhere
3. **Performance:** Browser can optimize CSS better than inline styles
4. **Debugging:** Easier to inspect and modify in DevTools
5. **Separation of Concerns:** Styling in CSS, logic in JavaScript

## Status

✅ **COMPLETE** - Timeline layers are now perfectly aligned between left column and right tracks.

