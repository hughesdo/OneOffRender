# Green Screen Videos Layer Implementation

## Overview
Implemented a dedicated "Green Screen Videos" layer (Layer 2 / Layer 1 in code) that only accepts videos, with comprehensive visual drag-and-drop feedback matching the "Shaders & Transitions" layer.

## Features Implemented

### 1. ✅ Layer Name Change
- **Old Name:** "Layer 2"
- **New Name:** "Green Screen Videos"
- **Font Size:** 11px (smaller to fit within 150px width)
- **Styling:** Green tint background, centered text, bold font
- **Height:** 60px (unchanged - maintains vertical alignment)

### 2. ✅ Drag-and-Drop Restrictions
- **Allowed:** Videos only ✅
- **Blocked:** Shaders ❌ | Transitions ❌
- **Validation:** Both in drag-over preview and actual drop
- **User Feedback:** Alert message if invalid drop attempted

### 3. ✅ Visual Feedback During Drag Operations

#### Valid Drop (Video):
- **Layer Track:** Green dashed border, light green background
- **Layer Name:** Green left border, light green background
- **Cursor:** `copy` cursor (indicates valid drop)
- **Effect:** Smooth transition animations

#### Invalid Drop (Shader or Transition):
- **Layer Track:** Red dashed border, light red background
- **Layer Name:** Red left border, light red background
- **Cursor:** `not-allowed` cursor
- **Alert:** Message explaining restriction

#### Hover (No Drag):
- **Layer Name:** Subtle green background highlight
- **Effect:** Indicates interactive area

### 4. ✅ Auto-Concatenation Respects Restrictions
- Shaders/transitions automatically skip layer 1
- Videos prefer layer 1 (Green Screen Videos)
- Shaders/transitions placed on layer 0 or layer 2+
- Smart placement finds best available space

## Layer Structure

| Layer Code | Display Name | Allowed Types | Color |
|------------|--------------|---------------|-------|
| Layer 0 | Shaders & Transitions | Shaders, Transitions | Blue |
| Layer 1 | Green Screen Videos | Videos | Green |
| Layer 2+ | Layer 3, Layer 4, etc. | Any | Default |

## Implementation Details

### JavaScript Changes

#### 1. Timeline.js - Layer Rendering

**File:** `web_editor/static/js/timeline.js` (Lines 328-346)

```javascript
// Add layer name
const nameDiv = document.createElement('div');
nameDiv.className = 'layer-name';
// Layer 0 is dedicated to shaders and transitions
if (i === 0) {
    nameDiv.classList.add('shaders-transitions-layer');
    nameDiv.textContent = 'Shaders & Transitions';
    nameDiv.dataset.layer = '0';
} 
// Layer 1 is dedicated to videos (green screen)
else if (i === 1) {
    nameDiv.classList.add('green-screen-videos-layer');
    nameDiv.textContent = 'Green Screen Videos';
    nameDiv.dataset.layer = '1';
} 
else {
    nameDiv.textContent = `Layer ${i + 1}`;
}
this.namesColumn.appendChild(nameDiv);
```

#### 2. Timeline.js - Auto-Concatenation Logic

**File:** `web_editor/static/js/timeline.js` (Lines 70-141)

**Key Changes:**
- Added `canUseLayer1` check for videos
- Videos prefer layer 1 when available
- Shaders/transitions skip layer 1 during placement search
- New layers respect type restrictions

```javascript
findAutoConcatenationPlacement(elementType, duration, targetLayer = null) {
    // Check layer restrictions
    const canUseLayer0 = elementType === 'shader' || elementType === 'transition';
    const canUseLayer1 = elementType === 'video';
    
    // If no layers exist, start at appropriate layer
    if (existingLayers.length === 0) {
        if (canUseLayer0) {
            return { layer: 0, startTime: 0, duration: Math.min(duration, this.duration) };
        } else if (canUseLayer1) {
            return { layer: 1, startTime: 0, duration: Math.min(duration, this.duration) };
        } else {
            return { layer: 2, startTime: 0, duration: Math.min(duration, this.duration) };
        }
    }
    
    // Try each existing layer in order (left-to-right filling)
    for (const layerNum of existingLayers) {
        // Skip layer 0 if element type is not allowed
        if (layerNum === 0 && !canUseLayer0) {
            continue;
        }
        // Skip layer 1 if element type is not allowed
        if (layerNum === 1 && !canUseLayer1) {
            continue;
        }
        // ... rest of logic
    }
}
```

#### 3. Editor.js - Validation Logic

**File:** `web_editor/static/js/editor.js` (Lines 468-482)

```javascript
isValidDropForLayer(elementType, targetLayer) {
    // Layer 0 is dedicated to shaders and transitions only
    if (targetLayer === 0) {
        return elementType === 'shader' || elementType === 'transition';
    }
    // Layer 1 is dedicated to videos only
    if (targetLayer === 1) {
        return elementType === 'video';
    }
    // All other layers accept any type
    return true;
}
```

#### 4. Editor.js - Drop Handler with Error Messages

**File:** `web_editor/static/js/editor.js` (Lines 484-513)

```javascript
onTimelineDrop(e) {
    // ... validation code ...
    
    if (!this.isValidDropForLayer(data.type, targetLayer)) {
        if (targetLayer === 0) {
            alert(`Layer 1 (Shaders & Transitions) only accepts shaders and transitions.\nPlease drop videos on Layer 2 or below.`);
        } else if (targetLayer === 1) {
            alert(`Layer 2 (Green Screen Videos) only accepts videos.\nPlease drop shaders and transitions on Layer 1 or Layer 3+.`);
        }
        return;
    }
    
    // ... add element code ...
}
```

### CSS Changes

#### Green Screen Videos Layer Styling

**File:** `web_editor/static/css/editor.css` (Lines 731-755)

```css
.layer-name.green-screen-videos-layer {
    font-size: 11px;
    font-weight: 600;
    text-align: center;
    background-color: rgba(76, 175, 80, 0.1);
    color: #4CAF50;
    transition: background-color 0.2s ease;
}

.layer-name.green-screen-videos-layer:hover {
    background-color: rgba(76, 175, 80, 0.2);
}
```

**Note:** The drag-over states (`.drag-over-valid` and `.drag-over-invalid`) are reused from the existing implementation and work for both specialized layers.

## User Experience

### Workflow Examples

#### Example 1: Dropping Video on Layer 2 (Green Screen Videos)
```
1. User drags video from right panel
2. Hovers over "Green Screen Videos" layer
3. Layer highlights GREEN with dashed border
4. Cursor shows "copy" icon
5. User drops video
6. Video appears at end of layer 2 content
```

#### Example 2: Attempting to Drop Shader on Layer 2
```
1. User drags shader from right panel
2. Hovers over "Green Screen Videos" layer
3. Layer highlights RED with dashed border
4. Cursor shows "not-allowed" icon
5. User drops shader anyway
6. Alert appears: "Layer 2 (Green Screen Videos) only accepts videos. Please drop shaders and transitions on Layer 1 or Layer 3+."
7. Shader is NOT added to timeline
```

#### Example 3: Auto-Placement Intelligence
```
Timeline state:
┌─────────────────────────────────────────────┐
│ Shaders & Transitions │ [Shader A][Shader B]│
├─────────────────────────────────────────────┤
│ Green Screen Videos   │ [Video C - full]    │
├─────────────────────────────────────────────┤
│ Layer 3               │ [empty]             │
└─────────────────────────────────────────────┘

User drops Video D anywhere:
→ System tries layer 1 (preferred for videos): Full
→ System skips layer 0 (videos not allowed)
→ System creates/uses layer 3 and places Video D there
```

#### Example 4: Shader Auto-Placement
```
Timeline state:
┌─────────────────────────────────────────────┐
│ Shaders & Transitions │ [Shader A - full]   │
├─────────────────────────────────────────────┤
│ Green Screen Videos   │ [Video B][Video C]  │
└─────────────────────────────────────────────┘

User drops Shader D anywhere:
→ System tries layer 0 (preferred for shaders): Full
→ System skips layer 1 (shaders not allowed)
→ System creates layer 2 and places Shader D there
```

## Visual Design

### Color Scheme

| Layer | Normal | Hover | Valid Drop | Invalid Drop |
|-------|--------|-------|------------|--------------|
| Shaders & Transitions | Blue tint | Lighter blue | Green | Red |
| Green Screen Videos | Green tint | Lighter green | Green | Red |
| General Layers | Default | Default | Green | Red |

### Distinguishing Features

- **Shaders & Transitions:** Blue background (rgba(33, 150, 243, 0.1))
- **Green Screen Videos:** Green background (rgba(76, 175, 80, 0.1))
- Both use same drag-over feedback (green for valid, red for invalid)

## Files Modified

1. **web_editor/static/js/timeline.js**
   - Updated layer name rendering (Lines 328-346)
   - Modified `findAutoConcatenationPlacement()` with layer 1 restrictions (Lines 70-141)

2. **web_editor/static/js/editor.js**
   - Updated `isValidDropForLayer()` to validate layer 1 (Lines 468-482)
   - Updated `onTimelineDrop()` with layer 1 error message (Lines 484-513)

3. **web_editor/static/css/editor.css**
   - Added `.green-screen-videos-layer` styling (Lines 731-755)

## Testing Instructions

1. **Refresh browser:** `Ctrl+R` or `F5`

2. **Test layer names:**
   - ✅ Layer 1 shows "Shaders & Transitions" (blue tint)
   - ✅ Layer 2 shows "Green Screen Videos" (green tint)
   - ✅ Both texts are centered and fit within column
   - ✅ Hover shows lighter tint on both

3. **Test valid drop (video on layer 2):**
   - Drag video from right panel
   - Hover over "Green Screen Videos" layer
   - ✅ Green dashed border appears
   - ✅ Green left border on layer name
   - ✅ Cursor shows "copy" icon
   - Drop video
   - ✅ Video appears on layer 2

4. **Test invalid drop (shader on layer 2):**
   - Drag shader from right panel
   - Hover over "Green Screen Videos" layer
   - ✅ Red dashed border appears
   - ✅ Red left border on layer name
   - ✅ Cursor shows "not-allowed" icon
   - Drop shader
   - ✅ Alert message appears
   - ✅ Shader is NOT added to timeline

5. **Test invalid drop (transition on layer 2):**
   - Drag transition from right panel
   - Hover over "Green Screen Videos" layer
   - ✅ Red visual feedback
   - Drop transition
   - ✅ Alert message appears
   - ✅ Transition is NOT added

6. **Test auto-placement:**
   - Drop video anywhere
   - ✅ Video prefers layer 2 (Green Screen Videos)
   - Drop shader anywhere
   - ✅ Shader prefers layer 1, skips layer 2
   - Drop transition anywhere
   - ✅ Transition prefers layer 1, skips layer 2

7. **Test alignment:**
   - ✅ Both specialized layer names are 60px tall
   - ✅ Both align perfectly with timeline tracks
   - ✅ No vertical offset

## Status

✅ **COMPLETE** - Green Screen Videos layer fully implemented with visual feedback and restrictions.

