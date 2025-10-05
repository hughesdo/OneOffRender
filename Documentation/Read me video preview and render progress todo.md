# Video Preview & Render Progress - Implementation TODO

## 📋 Overview

This document outlines the implementation plan for enhancing the web editor's video preview system and adding real-time render progress tracking. The goal is to provide users with clear visual feedback during the editing and rendering workflow.

---

## 🎯 Current State Analysis

### Video Preview Element
- **Location**: `web_editor/templates/editor.html` (Lines 82-88)
- **Current behavior**: Shows overlay message "Select music to begin editing"
- **Overlay element**: `.viewer-overlay` with semi-transparent background
- **Video element**: `<video id="videoPreview" controls>`

### Music Selection Flow
- **Trigger**: User clicks audio file in left panel
- **Handler**: `selectAudio()` in `editor.js` (Line 192)
- **Actions**: 
  - Enables interface via `enableInterface()` (Line 217)
  - Initializes timeline with audio duration
  - Collapses music panel
  - **Does NOT clear video overlay**

### Render Process
- **Trigger**: User clicks "Render Video" button
- **Handler**: `renderProject()` in `editor.js` (Line 628)
- **Backend**: `/api/project/render` in `app.py` (Line 276)
- **Process**: 
  - Saves `temp_render_manifest.json`
  - Launches `render_timeline.py` as subprocess (async)
  - Logs output to `render_output.log`
  - Returns immediately with PID and log file path
  - **No progress tracking implemented**

### Render Output
- **Output directory**: `Output_Video/`
- **Filename**: `{project_name}.mp4` (from manifest)
- **Completion signal**: Log message "=== Rendering Completed in X seconds ===" (Line 192 in render_timeline.py)
- **Output path logged**: `Output: {final_video}` (Line 194 in render_timeline.py)

### Render Logging
- **Log file**: `render_output.log` (created by Flask backend)
- **Progress indicators**: 
  - Every 5 seconds: `Progress: X% (Ys)` (Line 1037 in render_timeline.py)
  - Layer-specific: `Layer 0 (green screen) Progress: X% (Ys)` (Line 1690)
- **Stage markers**:
  - `--- Rendering Layer 1: Shaders & Transitions ---`
  - `--- Rendering Layer 0: Green Screen Videos ---`
  - `--- Compositing Layers ---`
  - `--- Adding Audio Track ---`
  - `=== Rendering Completed in X seconds ===`
- **Error detection**: `Rendering failed:` followed by traceback (Line 199)

---

## 🔧 Implementation Tasks

### **TASK 1: Clear Video Overlay on Music Selection**

**Priority**: High  
**Complexity**: Low  
**Files**: `web_editor/static/js/editor.js`, `web_editor/static/css/editor.css`

#### Subtasks:
1. **Add overlay element reference** (editor.js)
   - Line ~42: Add `this.viewerOverlay = document.querySelector('.viewer-overlay');`
   
2. **Hide overlay in `selectAudio()` method** (editor.js)
   - Line ~211: Add `this.viewerOverlay.style.display = 'none';`
   - Alternative: Add CSS class `.hidden` and toggle it
   
3. **Optional: Add fade-out animation** (editor.css)
   - Add transition to `.viewer-overlay`: `transition: opacity 0.3s ease-out;`
   - Use `opacity: 0` instead of `display: none` for smooth fade

#### Acceptance Criteria:
- ✅ Overlay disappears immediately when music is selected
- ✅ Video element becomes visible (black screen until render completes)
- ✅ Overlay does NOT reappear when switching audio files

---

### **TASK 2: Add Render Progress UI Components**

**Priority**: High  
**Complexity**: Medium  
**Files**: `web_editor/templates/editor.html`, `web_editor/static/css/editor.css`

#### Subtasks:
1. **Add progress container to HTML** (editor.html)
   - Insert after `.viewer-overlay` (Line ~88)
   ```html
   <div class="render-progress-overlay" style="display: none;">
       <div class="render-progress-container">
           <h3>Rendering Video...</h3>
           <div class="progress-bar-container">
               <div class="progress-bar" id="renderProgressBar"></div>
           </div>
           <p class="progress-text" id="renderProgressText">Initializing...</p>
           <p class="progress-stage" id="renderProgressStage">Starting render process</p>
           <button id="cancelRenderBtn" class="btn btn-secondary">Cancel Render</button>
       </div>
   </div>
   ```

2. **Add CSS styling** (editor.css)
   ```css
   .render-progress-overlay {
       position: absolute;
       top: 0; left: 0; right: 0; bottom: 0;
       background-color: rgba(0, 0, 0, 0.85);
       display: flex;
       align-items: center;
       justify-content: center;
       z-index: 100;
   }
   
   .render-progress-container {
       background-color: var(--bg-medium);
       border: 2px solid var(--border-color);
       border-radius: 8px;
       padding: 30px;
       min-width: 400px;
       text-align: center;
   }
   
   .progress-bar-container {
       width: 100%;
       height: 30px;
       background-color: var(--bg-dark);
       border-radius: 15px;
       overflow: hidden;
       margin: 20px 0;
   }
   
   .progress-bar {
       height: 100%;
       background: linear-gradient(90deg, #2196F3, #4CAF50);
       width: 0%;
       transition: width 0.3s ease;
   }
   
   .progress-text {
       font-size: 18px;
       font-weight: bold;
       color: var(--text-primary);
       margin: 10px 0;
   }
   
   .progress-stage {
       font-size: 14px;
       color: var(--text-secondary);
       margin: 5px 0;
   }
   ```

3. **Add element references to editor.js**
   - Line ~42: Add references to all progress elements
   ```javascript
   this.renderProgressOverlay = document.querySelector('.render-progress-overlay');
   this.renderProgressBar = document.getElementById('renderProgressBar');
   this.renderProgressText = document.getElementById('renderProgressText');
   this.renderProgressStage = document.getElementById('renderProgressStage');
   this.cancelRenderBtn = document.getElementById('cancelRenderBtn');
   ```

#### Acceptance Criteria:
- ✅ Progress overlay is hidden by default
- ✅ Progress bar animates smoothly (CSS transition)
- ✅ Text is readable with good contrast
- ✅ Cancel button is styled consistently with app theme

---

### **TASK 3: Implement Backend Progress Polling API**

**Priority**: High  
**Complexity**: Medium  
**Files**: `web_editor/app.py`

#### Subtasks:
1. **Add render status tracking** (app.py)
   - Add global dict to track active renders:
   ```python
   # After line 32
   active_renders = {}  # {process_id: {'status': 'running', 'log_file': 'path', 'start_time': timestamp}}
   ```

2. **Update `/api/project/render` endpoint** (Line 276)
   - Store render info in `active_renders` dict
   - Include project name in response

3. **Create `/api/render/status/<process_id>` endpoint**
   ```python
   @app.route('/api/render/status/<int:process_id>')
   def get_render_status(process_id):
       """Get current render progress by reading log file."""
       try:
           if process_id not in active_renders:
               return jsonify({'success': False, 'error': 'Unknown process ID'}), 404
           
           render_info = active_renders[process_id]
           log_file = Path(render_info['log_file'])
           
           if not log_file.exists():
               return jsonify({
                   'success': True,
                   'status': 'starting',
                   'progress': 0,
                   'stage': 'Initializing render process...'
               })
           
           # Read last 100 lines of log file
           with open(log_file, 'r', encoding='utf-8', errors='ignore') as f:
               lines = f.readlines()
               last_lines = lines[-100:] if len(lines) > 100 else lines
           
           # Parse log for progress indicators
           status = 'running'
           progress = 0
           stage = 'Starting...'
           error = None
           
           for line in reversed(last_lines):
               # Check for completion
               if '=== Rendering Completed' in line:
                   status = 'completed'
                   progress = 100
                   stage = 'Render complete!'
                   break
               
               # Check for errors
               if 'Rendering failed:' in line or 'ERROR' in line:
                   status = 'failed'
                   error = line.strip()
                   break
               
               # Parse progress percentage
               if 'Progress:' in line:
                   import re
                   match = re.search(r'Progress: ([\d.]+)%', line)
                   if match:
                       progress = float(match.group(1))
               
               # Parse stage information
               if '--- Rendering Layer 1' in line:
                   stage = 'Rendering shaders and transitions...'
               elif '--- Rendering Layer 0' in line:
                   stage = 'Rendering green screen videos...'
               elif '--- Compositing Layers' in line:
                   stage = 'Compositing video layers...'
               elif '--- Adding Audio Track' in line:
                   stage = 'Adding audio track...'
           
           # Check if process is still running
           import psutil
           try:
               process = psutil.Process(process_id)
               if not process.is_running():
                   if status == 'running':
                       status = 'failed'
                       error = 'Render process terminated unexpectedly'
           except psutil.NoSuchProcess:
               if status == 'running':
                   status = 'failed'
                   error = 'Render process not found'
           
           return jsonify({
               'success': True,
               'status': status,
               'progress': progress,
               'stage': stage,
               'error': error
           })
       
       except Exception as e:
           logger.error(f"Error getting render status: {e}")
           return jsonify({'success': False, 'error': str(e)}), 500
   ```

4. **Create `/api/render/output/<project_name>` endpoint**
   ```python
   @app.route('/api/render/output/<path:project_name>')
   def serve_render_output(project_name):
       """Serve the rendered video file."""
       try:
           output_dir = BASE_DIR / "Output_Video"
           return send_from_directory(output_dir, f"{project_name}.mp4")
       except Exception as e:
           logger.error(f"Error serving output video: {e}")
           return jsonify({'success': False, 'error': str(e)}), 404
   ```

5. **Add psutil dependency**
   - Add to requirements.txt: `psutil>=5.9.0`
   - Install: `pip install psutil`

#### Acceptance Criteria:
- ✅ Status endpoint returns valid JSON with progress/stage/status
- ✅ Log parsing correctly extracts progress percentages
- ✅ Stage detection identifies all render phases
- ✅ Error detection catches failures and process crashes
- ✅ Output endpoint serves completed video files

---

### **TASK 4: Implement Frontend Progress Polling**

**Priority**: High  
**Complexity**: Medium  
**Files**: `web_editor/static/js/editor.js`, `web_editor/static/js/api.js`

#### Subtasks:
1. **Add API method for status polling** (api.js)
   ```javascript
   // After line 143
   async getRenderStatus(processId) {
       try {
           const response = await fetch(`${this.baseUrl}/api/render/status/${processId}`);
           const data = await response.json();
           if (!data.success) {
               throw new Error(data.error || 'Failed to get render status');
           }
           return data;
       } catch (error) {
           console.error('Error getting render status:', error);
           throw error;
       }
   },
   ```

2. **Add render state tracking** (editor.js)
   ```javascript
   // After line 17
   this.currentRenderProcess = null;
   this.renderPollInterval = null;
   ```

3. **Update `renderProject()` method** (editor.js, Line 628)
   ```javascript
   // After line 690 (after API.renderProject call)
   const response = await API.renderProject(renderManifest);
   
   // Store process ID and start polling
   this.currentRenderProcess = {
       processId: response.process_id,
       projectName: renderManifest.project_name,
       startTime: Date.now()
   };
   
   // Show progress overlay
   this.showRenderProgress();
   
   // Start polling every 2 seconds
   this.startRenderPolling();
   ```

4. **Implement `showRenderProgress()` method**
   ```javascript
   showRenderProgress() {
       this.renderProgressOverlay.style.display = 'flex';
       this.renderProgressBar.style.width = '0%';
       this.renderProgressText.textContent = '0%';
       this.renderProgressStage.textContent = 'Starting render process...';
   }
   ```

5. **Implement `startRenderPolling()` method**
   ```javascript
   startRenderPolling() {
       // Clear any existing interval
       if (this.renderPollInterval) {
           clearInterval(this.renderPollInterval);
       }
       
       // Poll every 2 seconds
       this.renderPollInterval = setInterval(async () => {
           try {
               const status = await API.getRenderStatus(this.currentRenderProcess.processId);
               this.updateRenderProgress(status);
               
               // Stop polling if completed or failed
               if (status.status === 'completed' || status.status === 'failed') {
                   this.stopRenderPolling();
                   this.handleRenderComplete(status);
               }
           } catch (error) {
               console.error('Error polling render status:', error);
               // Continue polling even on error (might be temporary)
           }
       }, 2000);
   }
   ```

6. **Implement `updateRenderProgress()` method**
   ```javascript
   updateRenderProgress(status) {
       // Update progress bar
       this.renderProgressBar.style.width = `${status.progress}%`;
       
       // Update progress text
       this.renderProgressText.textContent = `${Math.round(status.progress)}%`;
       
       // Update stage text
       this.renderProgressStage.textContent = status.stage;
       
       // Change color if error
       if (status.status === 'failed') {
           this.renderProgressBar.style.background = 'linear-gradient(90deg, #f44336, #d32f2f)';
       }
   }
   ```

7. **Implement `stopRenderPolling()` method**
   ```javascript
   stopRenderPolling() {
       if (this.renderPollInterval) {
           clearInterval(this.renderPollInterval);
           this.renderPollInterval = null;
       }
   }
   ```

8. **Implement `handleRenderComplete()` method**
   ```javascript
   async handleRenderComplete(status) {
       if (status.status === 'completed') {
           // Hide progress overlay after 1 second
           setTimeout(() => {
               this.renderProgressOverlay.style.display = 'none';
           }, 1000);
           
           // Load video into preview
           const videoUrl = `/api/render/output/${this.currentRenderProcess.projectName}.mp4`;
           this.videoPreview.src = videoUrl;
           
           // Auto-play (optional - ask user preference)
           // this.videoPreview.play();
           
           alert('Rendering completed! Video loaded in preview.');
       } else if (status.status === 'failed') {
           this.renderProgressOverlay.style.display = 'none';
           alert(`Rendering failed: ${status.error || 'Unknown error'}`);
       }
       
       this.currentRenderProcess = null;
   }
   ```

9. **Add cancel render handler**
   ```javascript
   // In setupEventListeners()
   this.cancelRenderBtn.addEventListener('click', () => this.cancelRender());
   
   // New method
   async cancelRender() {
       if (!this.currentRenderProcess) return;
       
       if (confirm('Are you sure you want to cancel the render?')) {
           this.stopRenderPolling();
           this.renderProgressOverlay.style.display = 'none';
           
           // TODO: Add backend endpoint to kill process
           // await API.cancelRender(this.currentRenderProcess.processId);
           
           this.currentRenderProcess = null;
           alert('Render cancelled.');
       }
   }
   ```

#### Acceptance Criteria:
- ✅ Progress overlay appears immediately after clicking "Render Video"
- ✅ Progress bar updates every 2 seconds
- ✅ Stage text reflects current render phase
- ✅ Completed renders load video into preview automatically
- ✅ Failed renders show error message
- ✅ Cancel button stops polling (process termination optional)

---

## 🤔 Design Decisions & Questions

### **Q1: When should the video overlay be cleared?**
**Decision**: Clear immediately when music is selected and placed into timeline.
- **Rationale**: User has committed to editing, overlay is no longer needed
- **Alternative**: Clear only when first element is added to timeline (more conservative)

### **Q2: What polling interval for render progress?**
**Decision**: 2 seconds (configurable)
- **Rationale**: Balance between responsiveness and server load
- **Considerations**:
  - Too fast (< 1s): Unnecessary server load, log file I/O overhead
  - Too slow (> 5s): Poor user experience, feels unresponsive
  - 2s provides ~30 updates per minute, smooth progress bar animation

### **Q3: Should we auto-play the video when render completes?**
**Decision**: Load video but do NOT auto-play (show alert instead)
- **Rationale**: 
  - User may not be at computer when render completes
  - Unexpected audio playback is jarring
  - User can manually click play when ready
- **Alternative**: Add user preference toggle in Settings

### **Q4: How to detect render completion?**
**Decision**: Multi-signal approach
1. **Primary**: Log file contains "=== Rendering Completed"
2. **Secondary**: Output file exists in `Output_Video/`
3. **Tertiary**: Process has exited with code 0
- **Rationale**: Redundancy prevents false positives/negatives

### **Q5: How to handle render errors?**
**Decision**: Parse log for error keywords, check process status
- **Error indicators**:
  - Log contains "Rendering failed:" or "ERROR"
  - Process terminated with non-zero exit code
  - Process crashed (no longer running but no completion signal)
- **User feedback**: Show error message in alert, keep last log lines visible

### **Q6: Should we implement render cancellation?**
**Decision**: Phase 1 - UI only (stop polling), Phase 2 - Add process termination
- **Rationale**: 
  - Stopping polling is trivial, prevents UI confusion
  - Process termination requires careful cleanup (temp files, partial output)
  - Can be added later as enhancement

### **Q7: What if user refreshes page during render?**
**Decision**: Render continues in background, progress is lost
- **Rationale**: 
  - Tracking renders across sessions requires persistent storage
  - User can check `render_output.log` manually
  - Enhancement: Store active renders in JSON file, restore on page load

---

## 📦 Dependencies

### New Python Packages
- `psutil>=5.9.0` - Process monitoring for render status

### Existing Dependencies (No Changes)
- Flask, librosa, moderngl, numpy, PIL, ffmpeg

---

## 🧪 Testing Checklist

### Manual Testing
- [ ] Select music → Overlay disappears
- [ ] Click "Render Video" → Progress overlay appears
- [ ] Progress bar updates during render
- [ ] Stage text changes through render phases
- [ ] Completed render loads video into preview
- [ ] Failed render shows error message
- [ ] Cancel button stops polling
- [ ] Multiple renders in sequence work correctly
- [ ] Page refresh during render (progress lost but render continues)

### Edge Cases
- [ ] Render with empty timeline (should be blocked by existing validation)
- [ ] Render with no shaders (warning already implemented)
- [ ] Very short render (< 5 seconds) - progress updates correctly
- [ ] Very long render (> 5 minutes) - polling continues
- [ ] Log file doesn't exist yet (status returns "starting")
- [ ] Log file is locked/unreadable (graceful error handling)
- [ ] Process crashes mid-render (detected as "failed")

---

## 🚀 Future Enhancements

### Phase 2 Features
1. **Render queue system** - Queue multiple renders, process sequentially
2. **Render history** - Show list of past renders with thumbnails
3. **Persistent render tracking** - Restore progress after page refresh
4. **Real-time log viewer** - Show live log output in expandable panel
5. **Render presets** - Save/load resolution and quality settings
6. **Estimated time remaining** - Calculate ETA based on progress rate
7. **Desktop notifications** - Notify user when render completes (if browser supports)
8. **Render cancellation** - Terminate process and clean up temp files

### Performance Optimizations
- Cache log file position, only read new lines (avoid re-parsing entire file)
- Use WebSockets instead of polling for real-time updates
- Compress/rotate log files for long renders

---

## 📝 Implementation Order

1. ✅ **TASK 1** - Clear video overlay (quick win, improves UX immediately)
2. ✅ **TASK 2** - Add progress UI components (visual foundation)
3. ✅ **TASK 3** - Backend status API (data source for progress)
4. ✅ **TASK 4** - Frontend polling (connect UI to backend)
5. 🔄 **Testing** - Manual testing and edge case validation
6. 📚 **Documentation** - Update user guide with new features

---

## 📄 Files to Modify

| File | Changes | Lines Affected |
|------|---------|----------------|
| `web_editor/templates/editor.html` | Add progress overlay HTML | ~88 (insert) |
| `web_editor/static/css/editor.css` | Add progress styling | ~975 (append) |
| `web_editor/static/js/editor.js` | Add progress logic, polling | ~42, 211, 628, 751 (append) |
| `web_editor/static/js/api.js` | Add status API method | ~143 (append) |
| `web_editor/app.py` | Add status/output endpoints | ~330 (append) |
| `requirements.txt` | Add psutil | (append) |

**Total estimated changes**: ~300 lines of new code, ~10 lines modified

---

**Document Version**: 1.0  
**Last Updated**: 2025-10-05  
**Status**: Ready for Implementation

