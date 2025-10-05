# OneOffRender Web Editor - Architecture Documentation

## System Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                         USER INTERFACE (Browser)                     │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  ┌──────────────┐  ┌─────────────────────┐  ┌──────────────────┐  │
│  │   Music      │  │   Video Viewer      │  │   Asset          │  │
│  │   Selection  │  │   & Timeline        │  │   Selection      │  │
│  │   Panel      │  │   Editor            │  │   Panel          │  │
│  │              │  │                     │  │                  │  │
│  │  - Audio     │  │  - Video Preview    │  │  - Shaders       │  │
│  │    Files     │  │  - Playback         │  │  - Videos        │  │
│  │  - Duration  │  │  - Timeline Tracks  │  │  - Transitions   │  │
│  │  - Size      │  │  - Time Ruler       │  │  - Metadata      │  │
│  │              │  │  - Playhead         │  │                  │  │
│  └──────────────┘  └─────────────────────┘  └──────────────────┘  │
│                                                                       │
└───────────────────────────────┬───────────────────────────────────┘
                                │
                                │ HTTP/JSON
                                │
┌───────────────────────────────▼───────────────────────────────────┐
│                      FLASK BACKEND (Python)                         │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │                     API Endpoints                            │  │
│  ├─────────────────────────────────────────────────────────────┤  │
│  │  /api/audio/list          - List audio files                │  │
│  │  /api/shaders/list        - List shaders + metadata         │  │
│  │  /api/shaders/preview/*   - Serve preview images            │  │
│  │  /api/shaders/update      - Update metadata.json            │  │
│  │  /api/videos/list         - List videos + thumbnails        │  │
│  │  /api/videos/thumbnail/*  - Serve thumbnails                │  │
│  │  /api/transitions/list    - List transitions                │  │
│  │  /api/project/save        - Save project                    │  │
│  │  /api/project/render      - Render video                    │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                       │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │                   Processing Layer                           │  │
│  ├─────────────────────────────────────────────────────────────┤  │
│  │  - File System Scanner                                       │  │
│  │  - Thumbnail Generator (FFmpeg)                              │  │
│  │  - Audio Duration Extractor (librosa)                        │  │
│  │  - Metadata Manager (JSON)                                   │  │
│  │  - Project Serializer                                        │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                       │
└───────────────────────────────┬───────────────────────────────────┘
                                │
                                │ File I/O
                                │
┌───────────────────────────────▼───────────────────────────────────┐
│                      FILE SYSTEM (Project Directories)              │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  Input_Audio/              Shaders/                Transitions/      │
│  ├── music1.mp3           ├── shader1.glsl        ├── fade.glsl     │
│  ├── music2.wav           ├── shader1.JPG         ├── wipe.glsl     │
│  └── ...                  ├── metadata.json       └── ...           │
│                           └── ...                                    │
│                                                                       │
│  Input_Video/              Output_Video/                             │
│  ├── clip1.mp4            ├── final_render.mp4                      │
│  ├── clip2.mov            └── ...                                   │
│  └── thumbnails/                                                     │
│      ├── clip1_thumb.jpg                                             │
│      └── clip2_thumb.jpg                                             │
│                                                                       │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Frontend Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         editor.html                              │
│                    (Main HTML Template)                          │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             │ Loads
                             │
        ┌────────────────────┼────────────────────┐
        │                    │                    │
        ▼                    ▼                    ▼
┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│   api.js     │    │ timeline.js  │    │  editor.js   │
│              │    │              │    │              │
│ - API calls  │    │ - Timeline   │    │ - Main       │
│ - Data       │◄───┤   state      │◄───┤   controller │
│   formatting │    │ - Element    │    │ - UI events  │
│ - Error      │    │   management │    │ - Asset      │
│   handling   │    │ - Rendering  │    │   loading    │
└──────────────┘    └──────────────┘    └──────────────┘
        │                    │                    │
        └────────────────────┼────────────────────┘
                             │
                             │ Styles
                             ▼
                    ┌──────────────┐
                    │  editor.css  │
                    │              │
                    │ - Layout     │
                    │ - Colors     │
                    │ - Animations │
                    └──────────────┘
```

### Module Responsibilities

#### editor.js (Main Controller)
- Initializes the application
- Manages UI state
- Handles user interactions
- Coordinates between modules
- Implements drag-and-drop
- Manages asset loading

#### timeline.js (Timeline Manager)
- Maintains timeline state
- Manages layers and elements
- Handles element manipulation
- Implements undo/redo
- Renders timeline visualization
- Calculates positions and durations

#### api.js (Backend Communication)
- Makes HTTP requests
- Formats data for display
- Handles errors
- Provides utility functions
- Abstracts backend details

---

## Data Flow Diagrams

### 1. Audio Selection Flow

```
User clicks audio file
        │
        ▼
editor.js: selectAudio()
        │
        ├─► Store audio metadata
        │
        ├─► timeline.js: initialize(duration)
        │       │
        │       └─► Clear existing timeline
        │           Create empty layers
        │           Set duration
        │
        ├─► Enable interface
        │       │
        │       └─► Remove disabled overlay
        │           Enable buttons
        │           Activate panels
        │
        └─► Collapse music panel
                │
                └─► Add collapsed class
                    Show hover behavior
```

### 2. Drag and Drop Flow

```
User drags asset
        │
        ▼
Drag Start Event
        │
        ├─► Set drag data (type, metadata)
        └─► Set drag effect (copy)
        
User drops on timeline
        │
        ▼
Drop Event
        │
        ├─► Prevent default
        ├─► Get drag data
        ├─► Calculate drop time from mouse position
        │
        ▼
editor.js: onTimelineDrop()
        │
        └─► timeline.js: addElement(type, data, dropTime)
                │
                ├─► Generate unique ID
                ├─► Calculate default duration
                ├─► Find available layer
                ├─► Validate constraints
                ├─► Add to layers array
                ├─► Save state (undo)
                │
                └─► render()
                        │
                        └─► Update DOM
                            Show element on timeline
```

### 3. Metadata Update Flow

```
User edits shader metadata
        │
        ├─► Changes star rating
        │       │
        │       └─► Update star display
        │
        └─► Edits description
                │
                └─► Update character count

User clicks "Save Changes"
        │
        ▼
editor.js: saveShaderMetadata()
        │
        ├─► Get current values
        ├─► Validate (description ≤ 256 chars)
        │
        └─► api.js: updateShaderMetadata()
                │
                └─► POST /api/shaders/update
                        │
                        ▼
                Flask Backend
                        │
                        ├─► Load metadata.json
                        ├─► Find shader entry
                        ├─► Update values
                        ├─► Save metadata.json
                        │
                        └─► Return success
                                │
                                ▼
                        Show success message
                        Update local data
```

### 4. Timeline Rendering Flow

```
timeline.js: render()
        │
        ├─► Clear existing DOM
        │
        ├─► Calculate timeline width
        │       │
        │       └─► width = duration × zoom × 100px
        │
        ├─► Group elements by layer
        │
        ├─► For each layer:
        │       │
        │       ├─► Create layer div
        │       │
        │       ├─► For each element in layer:
        │       │       │
        │       │       ├─► Create element div
        │       │       ├─► Set position (left %)
        │       │       ├─► Set width (duration %)
        │       │       ├─► Add color class
        │       │       ├─► Add resize handles
        │       │       └─► Add to layer
        │       │
        │       └─► Add layer to timeline
        │
        ├─► Update layer names
        │
        └─► Update playhead position
```

---

## State Management

### Application State (editor.js)

```javascript
{
    selectedAudio: {
        name: "music.mp3",
        path: "Input_Audio/music.mp3",
        duration: 180.5,
        size: 5242880
    },
    
    shaders: [ /* Array of shader metadata */ ],
    videos: [ /* Array of video metadata */ ],
    transitions: [ /* Array of transition metadata */ ],
    
    currentShader: { /* Currently selected shader */ },
    
    timeline: Timeline instance
}
```

### Timeline State (timeline.js)

```javascript
{
    duration: 180.5,  // Total timeline duration (locked to audio)
    zoom: 1.0,        // Zoom level (pixels per second)
    playheadPosition: 0,  // Current playhead time
    selectedElement: "element_123",  // ID of selected element
    
    layers: [
        {
            id: "element_123",
            type: "shader",
            name: "shader.glsl",
            startTime: 0,
            duration: 30,
            layer: 0,
            data: { /* Element-specific data */ }
        },
        // ... more elements
    ],
    
    history: [ /* Array of timeline states for undo */ ],
    historyIndex: 0
}
```

---

## API Request/Response Formats

### GET /api/audio/list

**Response:**
```json
{
    "success": true,
    "files": [
        {
            "name": "music.mp3",
            "path": "Input_Audio/music.mp3",
            "duration": 180.5,
            "size": 5242880
        }
    ]
}
```

### GET /api/shaders/list

**Response:**
```json
{
    "success": true,
    "shaders": [
        {
            "name": "shader.glsl",
            "preview_image": "shader.JPG",
            "preview_path": "/api/shaders/preview/shader.JPG",
            "stars": 3,
            "buffer": null,
            "texture": null,
            "description": "Audio-reactive shader..."
        }
    ]
}
```

### POST /api/shaders/update

**Request:**
```json
{
    "name": "shader.glsl",
    "stars": 4,
    "description": "Updated description"
}
```

**Response:**
```json
{
    "success": true,
    "message": "Shader metadata updated"
}
```

---

## File System Structure

```
OneOffRender/
├── web_editor/
│   ├── app.py                    # Flask application
│   ├── requirements.txt          # Python dependencies
│   ├── README.md                 # User documentation
│   ├── QUICK_START.md           # Quick start guide
│   ├── ARCHITECTURE.md          # This file
│   │
│   ├── templates/
│   │   └── editor.html          # Main UI template
│   │
│   └── static/
│       ├── css/
│       │   └── editor.css       # All styles
│       │
│       └── js/
│           ├── api.js           # Backend communication
│           ├── timeline.js      # Timeline management
│           └── editor.js        # Main controller
│
├── Shaders/
│   ├── metadata.json            # Shader metadata
│   ├── *.glsl                   # Shader files
│   └── *.JPG                    # Preview images
│
├── Transitions/
│   └── *.glsl                   # Transition shaders
│
├── Input_Audio/
│   └── *.mp3, *.wav, etc.      # Audio files
│
├── Input_Video/
│   ├── *.mp4, *.mov, etc.      # Video files
│   └── thumbnails/
│       └── *_thumb.jpg          # Generated thumbnails
│
└── Output_Video/
    └── *.mp4                    # Rendered videos
```

---

## Technology Stack

### Frontend
- **HTML5**: Semantic markup, drag-and-drop API
- **CSS3**: Grid, Flexbox, CSS variables, animations
- **JavaScript (ES6+)**: Classes, async/await, modules
- **No frameworks**: Vanilla JS for simplicity and performance

### Backend
- **Flask**: Lightweight Python web framework
- **librosa**: Audio analysis and duration extraction
- **Pillow**: Image processing for placeholders
- **FFmpeg**: Video thumbnail generation

### Development Tools
- **Python 3.8+**: Backend runtime
- **Modern browsers**: Chrome, Firefox, Edge, Safari
- **Git**: Version control

---

## Performance Considerations

### Frontend Optimizations
- Lazy loading of assets
- Debounced timeline rendering
- Virtual scrolling for large lists (future)
- CSS transforms for smooth animations
- Event delegation for dynamic elements

### Backend Optimizations
- Thumbnail caching
- Streaming large files
- Async file operations (future)
- Database for metadata (future)

---

## Security Considerations

### Input Validation
- File path validation (prevent directory traversal)
- Description length limits (256 chars)
- Star rating range (1-4)
- JSON schema validation

### File Access
- Restricted to configured directories
- No arbitrary file system access
- Read-only for most operations
- Write access only to metadata.json

### Network Security
- CORS configured for local development
- No authentication (local use only)
- HTTPS recommended for production

---

## Extension Points

### Adding New Asset Types

1. **Backend** (app.py):
   ```python
   @app.route('/api/newtype/list')
   def list_newtype():
       # Scan directory
       # Return JSON
   ```

2. **Frontend** (editor.js):
   ```javascript
   async loadNewType() {
       this.newTypes = await API.getNewTypes();
       this.renderNewTypeList();
   }
   ```

3. **Timeline** (timeline.js):
   ```javascript
   calculateDefaultDuration(type, data, dropTime) {
       if (type === 'newtype') return 5;
       // ...
   }
   ```

### Adding New Features

- **Playback**: Implement in editor.js play()/pause()
- **Rendering**: Integrate with render_shader.py
- **Project Save**: Implement in app.py save/load endpoints
- **Effects**: Add new timeline element types
- **Filters**: Add asset filtering in UI

---

## Testing Strategy

### Unit Testing
- Timeline state management
- Element manipulation logic
- Duration calculations
- Constraint validation

### Integration Testing
- API endpoint responses
- File system operations
- Thumbnail generation
- Metadata persistence

### UI Testing
- Drag and drop functionality
- Timeline rendering
- Asset loading
- User interactions

### End-to-End Testing
- Complete workflow from audio selection to render
- Multiple element types
- Undo/redo operations
- Project save/load

---

## Deployment Considerations

### Local Development
- Use Flask development server
- Debug mode enabled
- Hot reload for changes

### Production (Future)
- Use production WSGI server (Gunicorn, uWSGI)
- Disable debug mode
- Configure proper logging
- Set up HTTPS
- Add authentication
- Use database for metadata

---

## Maintenance

### Code Organization
- Modular architecture
- Clear separation of concerns
- Consistent naming conventions
- Comprehensive comments

### Documentation
- Inline code comments
- API documentation
- User guides
- Architecture diagrams

### Version Control
- Git for source control
- Semantic versioning
- Change logs
- Feature branches

---

## Future Architecture Enhancements

### Phase 1
- WebSocket for real-time updates
- WebGL for shader preview
- Web Workers for heavy processing
- IndexedDB for client-side storage

### Phase 2
- Microservices architecture
- Message queue for rendering
- Distributed rendering
- Cloud storage integration

### Phase 3
- Real-time collaboration
- Plugin system
- API for third-party integrations
- Mobile app

---

This architecture provides a solid foundation for the OneOffRender Web Editor while remaining flexible for future enhancements.

