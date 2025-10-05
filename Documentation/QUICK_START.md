# OneOffRender Web Editor - Quick Start Guide

## 🚀 Get Started in 5 Minutes

### Prerequisites Check

Before starting, ensure you have:
- ✅ Python 3.8 or higher installed
- ✅ FFmpeg installed and in PATH
- ✅ OneOffRender project set up (venv created)

### Step 1: Install Dependencies

```bash
# From the OneOffRender root directory
cd web_editor
pip install -r requirements.txt
```

Or use the existing virtual environment:
```bash
# Activate venv first
venv\Scripts\activate  # Windows
source venv/bin/activate  # Linux/Mac

# Then install
pip install -r web_editor/requirements.txt
```

### Step 2: Start the Server

**Option A: Use the launcher (Windows)**
```bash
# From OneOffRender root directory
StartWebEditor.bat
```

**Option B: Manual start**
```bash
cd web_editor
python app.py
```

You should see:
```
 * Running on http://127.0.0.1:5000
 * Running on http://192.168.x.x:5000
```

### Step 3: Open in Browser

Navigate to: **http://localhost:5000**

---

## 🎬 Your First Video Project

### 1. Select Music (Required First Step)

The interface starts disabled. You must:
1. Look at the left panel (Music Selection)
2. Click on any audio file
3. The interface will enable automatically
4. The music panel will collapse

**Tip**: Hover over the collapsed music panel to see it again.

### 2. Add a Shader

1. Click the **"Shaders"** tab in the right panel
2. Select a shader from the dropdown (e.g., "Colorflow orbV1_Fixed.glsl")
3. See the preview image appear
4. **Drag the preview image** to the timeline
5. The shader appears as a blue bar

**Try this**: 
- Drag the edges of the blue bar to resize it
- Drag the bar itself to move it

### 3. Add a Video (Optional)

1. Click the **"Videos"** tab
2. If you have videos in `Input_Video/`, you'll see thumbnails
3. **Drag a thumbnail** to the timeline
4. The video appears as a green bar

**Note**: If no videos appear, add some `.mp4` files to the `Input_Video` directory and refresh.

### 4. Add a Transition

1. Click the **"Transitions"** tab
2. **Drag a transition name** to the timeline
3. The transition appears as an orange bar (1.6 seconds long)

**Tip**: Place transitions between shaders or videos for smooth blending.

### 5. Arrange Your Timeline

**Move elements**:
- Click and drag any bar left or right

**Resize elements**:
- Drag the left or right edge of shader/video bars
- Transitions cannot be resized (fixed 1.6s)

**Delete elements**:
- Click a bar to select it (gets a white outline)
- Press the `Delete` key

**Undo/Redo**:
- Click the ↶ button or press `Ctrl+Z` to undo
- Click the ↷ button or press `Ctrl+Y` to redo

### 6. Zoom the Timeline

- Click **+** to zoom in (see more detail)
- Click **-** to zoom out (see more of the timeline)

---

## 🎨 Edit Shader Metadata

While in the Shaders tab with a shader selected:

1. **Change Rating**:
   - Click the stars (☆) to rate 1-4 stars
   - Stars turn gold (★) when selected

2. **Edit Description**:
   - Type in the description box
   - Character counter shows remaining space (max 256)

3. **Save Changes**:
   - Click "Save Changes" button
   - Changes are saved to `Shaders/metadata.json`

---

## ⌨️ Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Delete` | Remove selected timeline element |
| `Ctrl+Z` | Undo last action |
| `Ctrl+Y` | Redo last undone action |
| `Space` | Play/Pause (coming soon) |

---

## 🎯 Quick Tips

### Timeline Tips
- **Elements can overlap**: Use multiple layers for complex compositions
- **Zoom for precision**: Zoom in when placing elements precisely
- **Use undo freely**: Full history is maintained
- **Timeline is locked**: Cannot extend beyond audio duration

### Shader Tips
- **Preview before adding**: Select shader to see preview
- **Rate your favorites**: Use stars to mark best shaders
- **Edit descriptions**: Add notes about what each shader does

### Video Tips
- **Thumbnails auto-generate**: First time may take a moment
- **Videos can be shortened**: But not extended beyond source length
- **Check duration**: Video duration shown under thumbnail

### Transition Tips
- **Fixed duration**: All transitions are 1.6 seconds
- **Place anywhere**: Not restricted to element boundaries
- **Try different ones**: Experiment with various transition effects

---

## 🔍 Troubleshooting

### Problem: Interface Won't Enable

**Symptom**: Everything stays greyed out after clicking audio

**Solutions**:
1. Check browser console (F12) for errors
2. Verify the audio file is valid
3. Refresh the page (F5) and try again
4. Try a different audio file

### Problem: No Audio Files Showing

**Symptom**: "No audio files found" message

**Solutions**:
1. Add audio files to `Input_Audio/` directory
2. Supported formats: MP3, WAV, FLAC, M4A, AAC, OGG
3. Refresh the page
4. Check Flask console for errors

### Problem: Video Thumbnails Not Showing

**Symptom**: Placeholder images instead of thumbnails

**Solutions**:
1. Verify FFmpeg is installed: `ffmpeg -version`
2. Check Flask console for thumbnail generation errors
3. Delete `Input_Video/thumbnails/` folder and restart
4. Ensure videos are in supported formats

### Problem: Drag and Drop Not Working

**Symptom**: Can't drag elements to timeline

**Solutions**:
1. Ensure audio is selected first (interface must be enabled)
2. Try a different browser (Chrome recommended)
3. Check that element shows drag cursor
4. Refresh the page

### Problem: Changes Not Saving

**Symptom**: Shader metadata doesn't persist

**Solutions**:
1. Check file permissions on `Shaders/metadata.json`
2. Ensure Flask has write access to the directory
3. Look for error messages in Flask console
4. Try running as administrator (Windows)

---

## 📊 Testing Checklist

Use this checklist to verify everything works:

- [ ] Server starts without errors
- [ ] Browser opens to editor interface
- [ ] Interface is disabled initially
- [ ] Audio files list loads
- [ ] Clicking audio enables interface
- [ ] Music panel collapses after selection
- [ ] Shaders tab loads shader list
- [ ] Shader preview shows when selected
- [ ] Can edit shader stars and description
- [ ] Shader metadata saves successfully
- [ ] Can drag shader to timeline
- [ ] Videos tab shows video thumbnails
- [ ] Can drag video to timeline
- [ ] Transitions tab shows transition list
- [ ] Can drag transition to timeline
- [ ] Timeline elements appear correctly
- [ ] Can move timeline elements
- [ ] Can resize shader/video elements
- [ ] Can delete elements with Delete key
- [ ] Undo/redo works
- [ ] Zoom in/out works
- [ ] Time markers display correctly

---

## 🎓 Next Steps

Once you're comfortable with the basics:

1. **Experiment with Layers**:
   - Add multiple elements at the same time
   - Create overlapping effects
   - Try different layer orders

2. **Create Complex Compositions**:
   - Mix shaders, videos, and transitions
   - Build sequences with multiple shaders
   - Use transitions for smooth blending

3. **Organize Your Assets**:
   - Rate all your shaders
   - Add descriptive notes
   - Identify your favorite combinations

4. **Plan Your Videos**:
   - Sketch out timeline layouts
   - Test different arrangements
   - Save project files (coming soon)

---

## 📚 Additional Resources

- **Full Documentation**: See `README.md` in web_editor folder
- **Technical Spec**: See `WEB_EDITOR_SPEC.md` in root folder
- **Implementation Details**: See `WEB_EDITOR_IMPLEMENTATION_SUMMARY.md`
- **Main Project**: See main OneOffRender documentation

---

## 🆘 Getting Help

If you encounter issues:

1. **Check the logs**: Look at Flask console output
2. **Browser console**: Press F12 and check for JavaScript errors
3. **Verify setup**: Ensure all prerequisites are installed
4. **Try examples**: Use the testing checklist above
5. **Read docs**: Check README.md and specification files

---

## 🎉 You're Ready!

You now have everything you need to start creating amazing audio-reactive videos with the OneOffRender Web Editor.

**Have fun creating!** 🎨🎬✨

---

## Quick Reference Card

```
┌─────────────────────────────────────────────────────────┐
│  OneOffRender Web Editor - Quick Reference              │
├─────────────────────────────────────────────────────────┤
│  START:  StartWebEditor.bat  or  python web_editor/app.py │
│  URL:    http://localhost:5000                          │
├─────────────────────────────────────────────────────────┤
│  WORKFLOW:                                              │
│  1. Select music (left panel)                           │
│  2. Add shaders (right panel → Shaders tab)             │
│  3. Add videos (right panel → Videos tab)               │
│  4. Add transitions (right panel → Transitions tab)     │
│  5. Arrange timeline (drag, resize, delete)             │
│  6. Save and render                                     │
├─────────────────────────────────────────────────────────┤
│  SHORTCUTS:                                             │
│  Delete    - Remove selected element                    │
│  Ctrl+Z    - Undo                                       │
│  Ctrl+Y    - Redo                                       │
│  +/-       - Zoom timeline                              │
├─────────────────────────────────────────────────────────┤
│  COLORS:                                                │
│  Blue      - Shaders                                    │
│  Green     - Videos                                     │
│  Orange    - Transitions                                │
└─────────────────────────────────────────────────────────┘
```

