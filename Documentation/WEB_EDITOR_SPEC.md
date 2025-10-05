# OneOffRender Web Editor - Implementation Specification

## Overview

This document provides detailed answers to the open questions and implementation decisions for the OneOffRender web-based video editor.

---

## Answers to Open Questions

### 1. Audio File Formats
**Supported formats:**
- `.mp3` - MPEG Audio Layer 3
- `.wav` - Waveform Audio File Format
- `.flac` - Free Lossless Audio Codec
- `.m4a` - MPEG-4 Audio
- `.aac` - Advanced Audio Coding
- `.ogg` - Ogg Vorbis

**Implementation:** The backend uses `librosa` to read audio files and extract duration. All formats supported by librosa are available.

### 2. Video File Formats
**Supported formats:**
- `.mp4` - MPEG-4 Part 14 (recommended)
- `.avi` - Audio Video Interleave
- `.mov` - QuickTime File Format
- `.mkv` - Matroska Multimedia Container
- `.webm` - WebM Video Format

**Implementation:** FFmpeg is used for video processing, so any format supported by FFmpeg can be added.

### 3. Metadata Save Behavior
**Decision: Immediate auto-save**

When the user clicks "Save Changes" button:
- Changes are immediately saved to `metadata.json`
- A success message is displayed
- No explicit "Save" button for the entire project is needed for metadata

**Rationale:** This prevents data loss and provides immediate feedback. The metadata is small and quick to save.

### 4. Timeline Export Format
**Output format: MP4 with H.264 codec**

**Specifications:**
- Container: MP4
- Video Codec: H.264 (libx264)
- Audio Codec: AAC
- Default Resolution: 2560x1440 (configurable)
- Frame Rate: 30 fps (configurable)
- Quality: CRF 18 (high quality, configurable)

**Rationale:** MP4/H.264 is universally compatible and provides excellent quality-to-size ratio.

### 5. Layer Limit
**Decision: No hard limit, but practical limit of ~20 layers**

**Implementation:**
- Timeline starts with 5 visible layers
- Automatically expands as elements are added
- UI remains performant with up to 20 layers
- Warning displayed if exceeding 20 layers

**Rationale:** Most projects won't need more than 10 layers. Unlimited layers provide flexibility without artificial constraints.

### 6. Transition Placement
**Decision: Transitions can be placed anywhere on the timeline**

**Current Implementation:**
- Transitions are independent elements
- Can be placed at any time position
- Fixed duration of 1.6 seconds
- Not restricted to element boundaries

**Future Enhancement:**
- Optional "smart placement" mode that snaps transitions between adjacent elements
- Visual indicators when transitions overlap with other elements
- Automatic transition suggestions at element boundaries

**Rationale:** Maximum flexibility for creative control. Users can manually position transitions where needed.

### 7. Element Overlap Behavior
**Decision: Layered rendering with z-order**

**Implementation:**
- Elements on higher layers render on top of lower layers
- Overlapping elements on the same layer: later elements render on top
- No automatic conflict resolution
- Visual warning when elements overlap on the same layer

**Rendering behavior:**
- Shaders: Blend with underlying layers using alpha compositing
- Videos: Opaque by default, can be made transparent
- Transitions: Applied between the two overlapping elements

**Rationale:** Follows Adobe After Effects model. Gives users full control over layering and composition.

### 8. Project Save/Load
**Decision: JSON-based project files**

**Project file structure:**
```json
{
  "version": "1.0",
  "name": "My Project",
  "created": "2024-01-01T00:00:00Z",
  "modified": "2024-01-01T00:00:00Z",
  "audio": {
    "path": "Input_Audio/music.mp3",
    "duration": 180.5
  },
  "timeline": {
    "duration": 180.5,
    "layers": [
      {
        "id": "element_123",
        "type": "shader",
        "name": "shader_name.glsl",
        "startTime": 0,
        "duration": 30,
        "layer": 0,
        "data": { /* shader-specific data */ }
      }
    ]
  },
  "settings": {
    "resolution": { "width": 2560, "height": 1440 },
    "frameRate": 30,
    "quality": { "crf": 18, "preset": "medium" }
  }
}
```

**Features:**
- Save project to `.json` file
- Load project from `.json` file
- Auto-save every 5 minutes (optional)
- Recent projects list

---

## Implementation Details

### Architecture

#### Backend (Flask)
- **app.py**: Main Flask application
- **API endpoints**: RESTful API for asset management and rendering
- **File scanning**: Automatic discovery of shaders, videos, transitions
- **Thumbnail generation**: FFmpeg-based video thumbnail creation
- **Metadata management**: Read/write to metadata.json

#### Frontend (Vanilla JavaScript)
- **editor.js**: Main application controller
- **timeline.js**: Timeline state management and rendering
- **api.js**: Backend communication layer
- **editor.css**: Complete styling with CSS variables

### Key Features Implemented

#### 1. Music-First Workflow
- Interface starts completely disabled
- Only music selection panel is active
- Selecting audio enables all features
- Music panel auto-collapses after selection
- Hover to expand collapsed panel

#### 2. Timeline System
- Multi-layer support (Adobe After Effects style)
- Drag-and-drop from asset panels
- Resize elements (except transitions)
- Move elements horizontally
- Visual time markers (10s minor, 30s major)
- Playhead indicator
- Zoom in/out functionality
- Undo/redo with full history

#### 3. Asset Management
- **Shaders**: Dropdown selection with preview, metadata editing
- **Videos**: Grid view with thumbnails, duration display
- **Transitions**: List view with drag-and-drop

#### 4. Metadata Editing
- Star rating (1-4 stars)
- Description editing (max 256 characters)
- Character counter
- Immediate save to metadata.json

#### 5. Timeline Elements
- **Color-coded**: Blue (shaders), Green (videos), Orange (transitions)
- **Resizable**: Drag handles on left/right edges
- **Movable**: Click and drag to reposition
- **Selectable**: Click to select, visual highlight
- **Deletable**: Press Delete key to remove

### Rendering Pipeline (To Be Implemented)

The rendering system will integrate with the existing `render_shader.py`:

1. **Timeline Processing**:
   - Parse timeline JSON
   - Sort elements by layer and time
   - Validate element durations and positions

2. **Frame Generation**:
   - For each frame (1/30th second):
     - Determine active elements at current time
     - Render shaders with audio reactivity
     - Composite video clips
     - Apply transitions between elements
     - Blend layers according to z-order

3. **Audio Processing**:
   - Extract audio features using librosa
   - Generate FFT data for shader reactivity
   - Sync audio with video frames

4. **Video Encoding**:
   - Use FFmpeg to encode frames
   - Add audio track
   - Output final MP4 file

### Performance Considerations

#### Frontend
- **Virtual scrolling**: For large asset lists
- **Debounced updates**: Timeline rendering on drag/resize
- **Canvas rendering**: For timeline visualization (future enhancement)
- **Web Workers**: For heavy computations (future enhancement)

#### Backend
- **Thumbnail caching**: Generated once, stored in thumbnails directory
- **Lazy loading**: Assets loaded on demand
- **Streaming**: Large file transfers use streaming
- **Background rendering**: Render process runs asynchronously

### Browser Compatibility

**Tested browsers:**
- Chrome 90+ (recommended)
- Firefox 88+
- Edge 90+
- Safari 14+

**Required features:**
- HTML5 Drag and Drop API
- CSS Grid and Flexbox
- ES6 JavaScript (async/await, classes)
- Fetch API

### Security Considerations

1. **File Access**: Backend only accesses configured directories
2. **Path Validation**: All file paths are validated to prevent directory traversal
3. **Input Sanitization**: User inputs are sanitized before saving
4. **CORS**: Configured for local development only
5. **File Upload**: Not implemented (uses existing files only)

---

## Usage Workflow

### Typical Editing Session

1. **Start Editor**: Run `StartWebEditor.bat` or `python web_editor/app.py`
2. **Open Browser**: Navigate to `http://localhost:5000`
3. **Select Music**: Click an audio file in the left panel
4. **Add Shaders**: 
   - Switch to Shaders tab
   - Select shader from dropdown
   - Edit metadata if desired
   - Drag preview to timeline
5. **Add Videos**:
   - Switch to Videos tab
   - Drag video thumbnails to timeline
   - Resize as needed
6. **Add Transitions**:
   - Switch to Transitions tab
   - Drag transitions to timeline between elements
7. **Arrange Timeline**:
   - Move elements to desired positions
   - Resize durations
   - Create multiple layers for overlays
8. **Save Project**: Click "Save Project" button
9. **Render**: Click "Render Video" button
10. **Wait**: Rendering happens in background
11. **Output**: Find rendered video in `Output_Video` directory

### Advanced Techniques

#### Creating Overlays
1. Add base shader/video on Layer 0
2. Add overlay shader/video on Layer 1
3. Adjust timing for desired effect
4. Transitions can blend between layers

#### Shader Sequences
1. Add multiple shaders in sequence on same layer
2. Add transitions between each shader
3. Adjust transition timing for smooth flow
4. Use star ratings to track favorite combinations

#### Video Integration
1. Add video clips at specific timestamps
2. Shorten videos to use only desired portions
3. Layer shaders over videos for effects
4. Use transitions to blend video clips

---

## Future Enhancements

### Phase 2 Features
- [ ] Real-time preview with WebGL shader rendering
- [ ] Audio waveform visualization on timeline
- [ ] Snap-to-grid and snap-to-elements
- [ ] Element duplication (Ctrl+D)
- [ ] Multi-select elements
- [ ] Group elements
- [ ] Timeline markers and annotations
- [ ] Export presets (4K, 1080p, etc.)

### Phase 3 Features
- [ ] Shader parameter editing in UI
- [ ] Custom transition duration
- [ ] Video effects (speed, reverse, etc.)
- [ ] Audio effects and mixing
- [ ] Keyframe animation
- [ ] Template projects
- [ ] Batch rendering queue

### Phase 4 Features
- [ ] Collaborative editing
- [ ] Cloud storage integration
- [ ] Mobile/tablet support
- [ ] Plugin system for custom effects
- [ ] AI-assisted editing suggestions

---

## Troubleshooting Guide

### Common Issues

#### 1. Interface Won't Enable
**Symptom**: Everything stays greyed out after selecting audio
**Solution**: 
- Check browser console for errors
- Verify audio file is valid
- Refresh page and try again

#### 2. Thumbnails Not Showing
**Symptom**: Video thumbnails show placeholder
**Solution**:
- Verify FFmpeg is installed: `ffmpeg -version`
- Check Flask console for errors
- Manually delete `Input_Video/thumbnails` and restart

#### 3. Drag and Drop Not Working
**Symptom**: Can't drag elements to timeline
**Solution**:
- Ensure audio is selected first
- Check that element is marked as draggable
- Try different browser

#### 4. Metadata Not Saving
**Symptom**: Changes to stars/description don't persist
**Solution**:
- Check file permissions on `Shaders/metadata.json`
- Verify Flask has write access
- Check Flask console for errors

#### 5. Timeline Elements Disappear
**Symptom**: Elements vanish after adding
**Solution**:
- Check that element duration is valid
- Verify element isn't beyond timeline end
- Use undo (Ctrl+Z) to restore

---

## Development Notes

### Code Organization

```
web_editor/
├── app.py                    # Flask backend (300 lines)
├── requirements.txt          # Python dependencies
├── README.md                # User documentation
├── templates/
│   └── editor.html          # Main UI template (150 lines)
└── static/
    ├── css/
    │   └── editor.css       # Complete styling (500 lines)
    └── js/
        ├── api.js           # API layer (150 lines)
        ├── timeline.js      # Timeline logic (300 lines)
        └── editor.js        # Main controller (400 lines)
```

### Adding New Asset Types

To add a new asset type (e.g., images):

1. **Backend** (`app.py`):
   ```python
   @app.route('/api/images/list')
   def list_images():
       # Scan directory, return JSON
   ```

2. **Frontend** (`editor.js`):
   ```javascript
   async loadImages() {
       this.images = await API.getImages();
       this.renderImageGrid();
   }
   ```

3. **Timeline** (`timeline.js`):
   ```javascript
   calculateDefaultDuration(type, data, dropTime) {
       if (type === 'image') return 5; // 5 seconds
       // ...
   }
   ```

### Testing Checklist

- [ ] Audio file selection enables interface
- [ ] All asset types load correctly
- [ ] Drag and drop works for all asset types
- [ ] Timeline elements can be moved
- [ ] Timeline elements can be resized (except transitions)
- [ ] Undo/redo works correctly
- [ ] Zoom in/out works
- [ ] Metadata editing saves correctly
- [ ] Star ratings update visually
- [ ] Description character counter works
- [ ] Keyboard shortcuts function
- [ ] Multiple layers work correctly
- [ ] Elements stay within timeline bounds
- [ ] Playhead moves correctly

---

## Conclusion

The OneOffRender Web Editor provides a complete, professional-grade interface for creating audio-reactive videos. The implementation follows modern web development best practices and provides a solid foundation for future enhancements.

The modular architecture makes it easy to extend with new features, and the clean separation between frontend and backend ensures maintainability.

For questions or contributions, please refer to the main project documentation.

