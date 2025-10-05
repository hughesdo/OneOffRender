# OneOffRender Web Editor

A web-based video editor interface for creating audio-reactive videos using GLSL shaders, video clips, and transitions.

## Features

- **Music-First Workflow**: Select audio file before editing begins
- **Timeline Editor**: Adobe After Effects-style multi-layer timeline
- **Shader Library**: Browse and preview audio-reactive shaders with ratings and descriptions
- **Video Integration**: Add video clips with automatic thumbnail generation
- **Transition Effects**: Apply transition shaders between elements
- **Drag & Drop**: Intuitive drag-and-drop interface for adding elements to timeline
- **Real-time Preview**: Video viewer with playback controls
- **Metadata Management**: Edit shader ratings and descriptions directly in the UI
- **Undo/Redo**: Full history support for timeline edits
- **Keyboard Shortcuts**: Efficient editing with keyboard commands

## Installation

### Prerequisites

- Python 3.8 or higher
- FFmpeg installed and available in PATH
- All dependencies from the main OneOffRender project

### Setup

1. Navigate to the web_editor directory:
   ```bash
   cd web_editor
   ```

2. Install Python dependencies:
   ```bash
   pip install -r requirements.txt
   ```

3. Ensure FFmpeg is installed:
   ```bash
   ffmpeg -version
   ```

## Running the Editor

1. Start the Flask server:
   ```bash
   python app.py
   ```

2. Open your web browser and navigate to:
   ```
   http://localhost:5000
   ```

3. The editor interface will load with the music selection panel active.

## Usage Guide

### Getting Started

1. **Select Music**: Click on an audio file in the left panel to begin editing
   - The interface will enable once music is selected
   - The timeline will be locked to the audio duration
   - The music panel will automatically collapse

2. **Add Shaders**:
   - Click the "Shaders" tab in the right panel
   - Select a shader from the dropdown
   - Preview the shader and edit its metadata (rating, description)
   - Drag the preview image to the timeline

3. **Add Videos**:
   - Click the "Videos" tab
   - Drag video thumbnails to the timeline
   - Videos can be shortened but not extended beyond their source duration

4. **Add Transitions**:
   - Click the "Transitions" tab
   - Drag transition names to the timeline
   - Transitions have a fixed duration of ~1.6 seconds

### Timeline Controls

- **Zoom**: Use +/- buttons to zoom in/out on the timeline
- **Undo/Redo**: Use the ↶/↷ buttons or Ctrl+Z/Ctrl+Y
- **Move Elements**: Click and drag timeline bars horizontally
- **Resize Elements**: Drag the left or right edges of shader/video bars
- **Delete Elements**: Select an element and press Delete key
- **Playhead**: Click on the timeline to move the playhead

### Keyboard Shortcuts

- `Space`: Play/Pause (when implemented)
- `Delete`: Remove selected timeline element
- `Ctrl+Z`: Undo
- `Ctrl+Y`: Redo

### Saving and Rendering

- **Save Project**: Click "Save Project" to save your timeline (feature in development)
- **Render Video**: Click "Render Video" to export the final video file

## Timeline Element Types

### Shaders (Blue)
- Audio-reactive GLSL shaders
- Default duration: Fill from drop point to end of audio
- Resizable: Yes
- Can be shortened or lengthened within timeline bounds

### Videos (Green)
- Video clips from Input_Video directory
- Default duration: Full video length
- Resizable: Yes, but cannot exceed source video duration
- Automatically generates thumbnails at 3-second mark

### Transitions (Orange)
- Transition effects between elements
- Fixed duration: 1.6 seconds
- Resizable: No
- Can be moved but not resized

## File Structure

```
web_editor/
├── app.py                 # Flask backend server
├── requirements.txt       # Python dependencies
├── README.md             # This file
├── templates/
│   └── editor.html       # Main editor interface
└── static/
    ├── css/
    │   └── editor.css    # Editor styles
    └── js/
        ├── api.js        # Backend API communication
        ├── timeline.js   # Timeline management
        └── editor.js     # Main editor logic
```

## API Endpoints

### GET /api/audio/list
Returns list of available audio files with duration and size.

### GET /api/shaders/list
Returns list of shaders with metadata from metadata.json.

### GET /api/shaders/preview/<filename>
Serves shader preview images.

### POST /api/shaders/update
Updates shader metadata (stars and description).

### GET /api/videos/list
Returns list of videos with thumbnails and duration.

### GET /api/videos/thumbnail/<filename>
Serves video thumbnail images.

### GET /api/transitions/list
Returns list of available transition shaders.

### POST /api/project/save
Saves the current timeline project (in development).

### POST /api/project/render
Renders the timeline to a video file (in development).

## Configuration

The editor uses the following directories from the main project:
- `../Shaders/` - Shader files and metadata.json
- `../Transitions/` - Transition shader files
- `../Input_Audio/` - Audio files
- `../Input_Video/` - Video files
- `../Input_Video/thumbnails/` - Generated video thumbnails

## Supported File Formats

### Audio
- MP3 (.mp3)
- WAV (.wav)
- FLAC (.flac)
- M4A (.m4a)
- AAC (.aac)
- OGG (.ogg)

### Video
- MP4 (.mp4)
- AVI (.avi)
- MOV (.mov)
- MKV (.mkv)
- WebM (.webm)

## Known Limitations

1. **Rendering**: The render functionality is currently in development and will integrate with the existing render_shader.py system.

2. **Playback**: Real-time preview playback is not yet implemented. The video viewer will show the rendered output once rendering is complete.

3. **Project Persistence**: Project save/load functionality is in development.

4. **Layer Collision**: The timeline currently allows overlapping elements. Proper layer management and collision detection will be added.

5. **Transition Placement**: Transitions can be placed anywhere on the timeline. Future versions may enforce placement between adjacent elements.

## Troubleshooting

### Thumbnails Not Generating
- Ensure FFmpeg is installed and in your PATH
- Check that video files are in a supported format
- Look for error messages in the Flask console

### Audio Files Not Loading
- Verify audio files are in the Input_Audio directory
- Check that files are in a supported format
- Ensure librosa can read the audio files

### Interface Not Enabling
- Make sure you've selected an audio file
- Check the browser console for JavaScript errors
- Verify the Flask server is running

## Development

### Adding New Features

The codebase is modular and easy to extend:

- **Backend**: Add new API endpoints in `app.py`
- **Frontend**: Extend functionality in the respective JS modules
- **Styling**: Modify `editor.css` for visual changes

### Testing

Test the editor with various combinations of:
- Different audio file lengths
- Multiple shaders, videos, and transitions
- Different timeline zoom levels
- Undo/redo operations

## Future Enhancements

- [ ] Real-time video preview with shader rendering
- [ ] Project save/load functionality
- [ ] Advanced layer management with z-order control
- [ ] Snapping to time markers and other elements
- [ ] Element duplication
- [ ] Transition preview animations
- [ ] Export presets (resolution, quality, format)
- [ ] Batch rendering multiple projects
- [ ] Timeline markers and annotations
- [ ] Audio waveform visualization

## License

This web editor is part of the OneOffRender project and follows the same license.

## Support

For issues, questions, or contributions, please refer to the main OneOffRender project documentation.

