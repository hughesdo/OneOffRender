/**
 * Main Editor Module - Coordinates all editor functionality
 */

class VideoEditor {
    constructor() {
        this.timeline = new Timeline();
        this.selectedAudio = null;
        this.shaders = [];
        this.videos = [];
        this.transitions = [];
        this.currentShader = null;

        // Playback state (using single video element for both audio and video)
        this.isPlaying = false;
        this.playbackInterval = null;
        this.hasRenderedVideo = false; // Track if we have a rendered video loaded

        this.initializeUI();
        this.loadAssets();
    }

    /**
     * Initialize UI elements and event listeners
     */
    initializeUI() {
        // Music panel elements
        this.musicPanel = document.getElementById('musicPanel');
        this.audioFileList = document.getElementById('audioFileList');
        this.collapseMusicBtn = document.getElementById('collapseMusicBtn');

        // Settings elements
        this.resolutionSelect = document.getElementById('resolutionSelect');
        this.frameRateInput = document.getElementById('frameRateInput');
        
        // Center panel elements
        this.centerPanel = document.querySelector('.center-panel');
        this.videoPreview = document.getElementById('videoPreview');
        this.greenScreenPreview = document.getElementById('greenScreenPreview');
        this.viewerOverlay = document.querySelector('.viewer-overlay');
        this.playPauseBtn = document.getElementById('playPauseBtn');
        this.currentTimeDisplay = document.getElementById('currentTime');
        this.totalTimeDisplay = document.getElementById('totalTime');
        
        // Right panel elements
        this.rightPanel = document.querySelector('.right-panel');
        this.shaderSelect = document.getElementById('shaderSelect');
        this.shaderPreview = document.getElementById('shaderPreview');
        this.shaderPreviewImage = document.getElementById('shaderPreviewImage');
        this.shaderDescription = document.getElementById('shaderDescription');
        this.descCharCount = document.getElementById('descCharCount');
        this.saveShaderMetadata = document.getElementById('saveShaderMetadata');
        this.audioIcon = document.getElementById('audioIcon');
        this.videoGrid = document.getElementById('videoGrid');
        this.transitionList = document.getElementById('transitionList');
        
        // Header buttons
        this.loadProjectBtn = document.getElementById('loadProjectBtn');
        this.saveProjectBtn = document.getElementById('saveProjectBtn');
        this.renderBtn = document.getElementById('renderBtn');

        // Timeline controls
        this.zoomInBtn = document.getElementById('zoomInBtn');
        this.zoomOutBtn = document.getElementById('zoomOutBtn');
        this.zoomResetBtn = document.getElementById('zoomResetBtn');
        this.zoomDisplay = document.getElementById('zoomDisplay');
        this.undoBtn = document.getElementById('undoBtn');
        this.redoBtn = document.getElementById('redoBtn');

        // Overlay
        this.disabledOverlay = document.getElementById('disabledOverlay');

        // Render progress elements
        this.renderProgressOverlay = document.getElementById('renderProgressOverlay');
        this.renderProgressBar = document.getElementById('renderProgressBar');
        this.renderProgressText = document.getElementById('renderProgressText');
        this.renderStageText = document.getElementById('renderStageText');
        this.currentRenderPID = null;
        this.renderPollInterval = null;

        // Green screen preview state
        this.currentGreenScreen = null; // Currently active green screen element
        this.greenScreenVideoPath = null; // Path to green screen video file

        // Save/Load modal elements
        this.saveProjectModal = document.getElementById('saveProjectModal');
        this.loadProjectModal = document.getElementById('loadProjectModal');
        this.projectNameInput = document.getElementById('projectNameInput');
        this.projectList = document.getElementById('projectList');

        // Current project name (for re-save)
        this.currentProjectName = '';

        this.setupEventListeners();
    }

    /**
     * Setup all event listeners
     */
    setupEventListeners() {
        // Tab switching
        document.querySelectorAll('.tab-btn').forEach(btn => {
            btn.addEventListener('click', (e) => this.switchTab(e.target.dataset.tab));
        });
        
        // Shader selection
        this.shaderSelect.addEventListener('change', (e) => this.onShaderSelected(e.target.value));
        
        // Shader metadata editing
        this.shaderDescription.addEventListener('input', (e) => {
            this.descCharCount.textContent = e.target.value.length;
        });
        
        document.querySelectorAll('.star').forEach(star => {
            star.addEventListener('click', (e) => this.onStarClick(e.target));
        });
        
        this.saveShaderMetadata.addEventListener('click', () => this.saveShaderMetadata_handler());
        
        // Shader drag and drop
        this.shaderPreviewImage.addEventListener('dragstart', (e) => this.onShaderDragStart(e));
        
        // Timeline controls - finer zoom increments (0.1x steps)
        this.zoomInBtn.addEventListener('click', () => this.zoomIn());
        this.zoomOutBtn.addEventListener('click', () => this.zoomOut());
        this.zoomResetBtn.addEventListener('click', () => this.resetZoom());
        this.undoBtn.addEventListener('click', () => this.timeline.undo());
        this.redoBtn.addEventListener('click', () => this.timeline.redo());
        
        // Playback controls - single toggle button
        this.playPauseBtn.addEventListener('click', () => this.togglePlayPause());

        // Recalculate zoom limits on window resize
        window.addEventListener('resize', () => {
            if (this.timeline.duration > 0) {
                this.timeline.calculateMinZoom();
            }
        });
        
        // Header buttons
        this.loadProjectBtn.addEventListener('click', () => this.showLoadProjectModal());
        this.saveProjectBtn.addEventListener('click', () => this.showSaveProjectModal());
        this.renderBtn.addEventListener('click', () => this.renderProject());

        // Save project modal buttons
        document.getElementById('closeSaveModal').addEventListener('click', () => this.hideSaveProjectModal());
        document.getElementById('cancelSaveBtn').addEventListener('click', () => this.hideSaveProjectModal());
        document.getElementById('confirmSaveBtn').addEventListener('click', () => this.confirmSaveProject());
        this.projectNameInput.addEventListener('keydown', (e) => {
            if (e.key === 'Enter') this.confirmSaveProject();
            if (e.key === 'Escape') this.hideSaveProjectModal();
        });

        // Load project modal buttons
        document.getElementById('closeLoadModal').addEventListener('click', () => this.hideLoadProjectModal());
        document.getElementById('cancelLoadBtn').addEventListener('click', () => this.hideLoadProjectModal());

        // Close modals on overlay click
        this.saveProjectModal.addEventListener('click', (e) => {
            if (e.target === this.saveProjectModal) this.hideSaveProjectModal();
        });
        this.loadProjectModal.addEventListener('click', (e) => {
            if (e.target === this.loadProjectModal) this.hideLoadProjectModal();
        });

        // Settings controls
        this.resolutionSelect.addEventListener('change', () => this.onResolutionChange());

        // Music panel controls
        this.collapseMusicBtn.addEventListener('click', () => this.collapseMusicPanel());

        // Collapsed label click to expand
        const collapsedLabel = this.musicPanel.querySelector('.collapsed-label');
        if (collapsedLabel) {
            collapsedLabel.addEventListener('click', () => this.expandMusicPanel());
        }

        // Timeline drop zone
        const timelineTracks = document.querySelector('.timeline-tracks-container');
        timelineTracks.addEventListener('dragover', (e) => this.onTimelineDragOver(e));
        timelineTracks.addEventListener('dragleave', (e) => this.onTimelineDragLeave(e));
        timelineTracks.addEventListener('drop', (e) => this.onTimelineDrop(e));

        // Keyboard shortcuts
        document.addEventListener('keydown', (e) => this.handleKeyboard(e));
    }

    /**
     * Handle resolution change
     */
    onResolutionChange() {
        const resolution = this.resolutionSelect.value;
        console.log(`Resolution changed to: ${resolution}`);
        // Resolution will be read when rendering
    }

    /**
     * Load all assets from the backend
     */
    async loadAssets() {
        try {
            // Load audio files with loading indicator
            this.audioFileList.innerHTML = '<p class="loading-message">Loading audio files...</p>';
            this.audioFiles = await API.getAudioFiles();
            this.renderAudioList(this.audioFiles);

            // Load shaders
            this.shaders = await API.getShaders();
            this.renderShaderList();

            // Load videos
            this.videos = await API.getVideos();
            this.renderVideoGrid();

            // Load transitions
            this.transitions = await API.getTransitions();
            this.renderTransitionList();
        } catch (error) {
            console.error('Error loading assets:', error);
            this.audioFileList.innerHTML = `
                <div class="error-message">
                    <p>Failed to load audio files</p>
                    <p class="help-text">Please check your connection and refresh the page</p>
                </div>
            `;
        }
    }

    /**
     * Render audio file list
     */
    renderAudioList(audioFiles) {
        this.audioFileList.innerHTML = '';

        if (audioFiles.length === 0) {
            this.audioFileList.innerHTML = `
                <div class="no-files-message">
                    <p>No audio files found</p>
                    <p class="help-text">Place audio files in the Music folder to get started</p>
                </div>
            `;
            return;
        }
        
        audioFiles.forEach(audio => {
            const item = document.createElement('div');
            item.className = 'audio-file-item';
            item.dataset.path = audio.path;
            item.dataset.duration = audio.duration;
            
            item.innerHTML = `
                <div class="audio-file-name">${audio.name}</div>
                <div class="audio-file-info">
                    ${API.formatDuration(audio.duration)} • ${API.formatFileSize(audio.size)}
                </div>
            `;
            
            item.addEventListener('click', () => this.selectAudio(audio, item));
            this.audioFileList.appendChild(item);
        });
    }

    /**
     * Handle audio file selection
     */
    selectAudio(audio, itemElement) {
        // Remove previous selection
        document.querySelectorAll('.audio-file-item').forEach(el => el.classList.remove('selected'));

        // Mark as selected
        itemElement.classList.add('selected');
        this.selectedAudio = audio;

        // Initialize timeline with audio duration and file name
        this.timeline.initialize(audio.duration, audio.name);

        // Enable the interface
        this.enableInterface();

        // Hide video overlay
        this.viewerOverlay.style.display = 'none';

        // Update time display
        this.totalTimeDisplay.textContent = API.formatDuration(audio.duration);
        this.currentTimeDisplay.textContent = '00:00';

        // Initialize zoom display
        this.zoomDisplay.textContent = `Zoom: ${this.timeline.zoom.toFixed(1)}x`;

        // Collapse music panel
        this.collapseMusicPanel();
    }

    /**
     * Enable the interface after audio selection
     */
    enableInterface() {
        this.disabledOverlay.classList.add('hidden');
        this.centerPanel.classList.remove('disabled');
        this.rightPanel.classList.remove('disabled');
        
        // Enable buttons
        this.saveProjectBtn.disabled = false;
        this.renderBtn.disabled = false;
        this.playPauseBtn.disabled = false;
        this.zoomInBtn.disabled = false;
        this.zoomOutBtn.disabled = false;
        this.zoomResetBtn.disabled = false;
        this.undoBtn.disabled = false;
        this.redoBtn.disabled = false;

        // Initialize button state (paused by default - show play icon)
        this.updatePlayPauseButton(false);
        
        // Show collapse button
        this.collapseMusicBtn.style.display = 'block';
    }

    /**
     * Collapse music panel
     */
    collapseMusicPanel() {
        this.musicPanel.classList.add('collapsed');
        this.musicPanel.querySelector('.collapsed-label').style.display = 'block';
    }

    /**
     * Expand music panel (from collapsed state)
     */
    expandMusicPanel() {
        this.musicPanel.classList.remove('collapsed');
        this.musicPanel.querySelector('.collapsed-label').style.display = 'none';
    }

    /**
     * Switch between asset tabs
     */
    switchTab(tabName) {
        // Update tab buttons
        document.querySelectorAll('.tab-btn').forEach(btn => {
            btn.classList.toggle('active', btn.dataset.tab === tabName);
        });
        
        // Update tab content
        document.querySelectorAll('.tab-content').forEach(content => {
            content.classList.toggle('active', content.id === `${tabName}Tab`);
        });
    }

    /**
     * Render shader list in dropdown
     */
    renderShaderList() {
        this.shaderSelect.innerHTML = '<option value="">Select a shader...</option>';
        
        this.shaders.forEach((shader, index) => {
            const option = document.createElement('option');
            option.value = index;
            option.textContent = shader.name;
            this.shaderSelect.appendChild(option);
        });
    }

    /**
     * Handle shader selection
     */
    onShaderSelected(index) {
        if (index === '') {
            this.shaderPreview.style.display = 'none';
            this.currentShader = null;
            return;
        }

        const shader = this.shaders[index];
        this.currentShader = shader;

        // Show preview
        this.shaderPreview.style.display = 'flex';
        this.shaderPreviewImage.src = shader.preview_path;
        this.shaderDescription.value = shader.description || '';
        this.descCharCount.textContent = (shader.description || '').length;

        // Update star rating
        this.updateStarRating(shader.stars || 0);

        // Show/hide audio-reactive icon
        if (shader.audio_reactive) {
            this.audioIcon.style.display = 'inline';
        } else {
            this.audioIcon.style.display = 'none';
        }
    }

    /**
     * Update star rating display
     */
    updateStarRating(rating) {
        document.querySelectorAll('.star').forEach((star, index) => {
            star.classList.toggle('filled', index < rating);
            star.textContent = index < rating ? '★' : '☆';
        });
    }

    /**
     * Handle star click
     */
    onStarClick(starElement) {
        const rating = parseInt(starElement.dataset.value);
        this.updateStarRating(rating);
    }

    /**
     * Save shader metadata
     */
    async saveShaderMetadata_handler() {
        if (!this.currentShader) return;
        
        const rating = document.querySelectorAll('.star.filled').length;
        const description = this.shaderDescription.value;
        
        try {
            await API.updateShaderMetadata(this.currentShader.name, rating, description);
            
            // Update local data
            this.currentShader.stars = rating;
            this.currentShader.description = description;
            
            alert('Shader metadata saved successfully!');
        } catch (error) {
            alert('Failed to save shader metadata: ' + error.message);
        }
    }

    /**
     * Handle shader drag start
     */
    onShaderDragStart(e) {
        if (!this.currentShader) return;
        
        e.dataTransfer.effectAllowed = 'copy';
        e.dataTransfer.setData('application/json', JSON.stringify({
            type: 'shader',
            data: this.currentShader
        }));
    }

    /**
     * Render video grid
     */
    renderVideoGrid() {
        this.videoGrid.innerHTML = '';
        
        if (this.videos.length === 0) {
            this.videoGrid.innerHTML = '<p class="loading-message">No videos found</p>';
            return;
        }
        
        this.videos.forEach(video => {
            const item = document.createElement('div');
            item.className = 'video-item';
            item.draggable = true;
            
            item.innerHTML = `
                <img src="${video.thumbnail}" alt="${video.name}" class="video-thumbnail">
                <div class="video-info">
                    <div class="video-name" title="${video.name}">${video.name}</div>
                    <div class="video-duration">${API.formatDuration(video.duration)}</div>
                </div>
            `;
            
            item.addEventListener('dragstart', (e) => {
                e.dataTransfer.effectAllowed = 'copy';
                e.dataTransfer.setData('application/json', JSON.stringify({
                    type: 'video',
                    data: video
                }));
            });
            
            this.videoGrid.appendChild(item);
        });
    }

    /**
     * Render transition list with preference-based grouping and star ratings
     */
    renderTransitionList() {
        this.transitionList.innerHTML = '';

        if (this.transitions.length === 0) {
            this.transitionList.innerHTML = '<p class="loading-message">No transitions found</p>';
            return;
        }

        // Group transitions by preference
        const groups = {
            'Highly Desired': [],
            'Mid': [],
            'Low': []
        };

        this.transitions.forEach(transition => {
            const preference = transition.preference || 'Low';
            if (groups[preference]) {
                groups[preference].push(transition);
            } else {
                // Handle unknown preferences by putting them in Low
                groups['Low'].push(transition);
            }
        });

        // Render each group
        Object.entries(groups).forEach(([preference, transitions]) => {
            if (transitions.length === 0) return;

            // Create group header
            const groupHeader = document.createElement('div');
            groupHeader.className = 'transition-group-header';
            groupHeader.textContent = `${preference} Transitions:`;
            this.transitionList.appendChild(groupHeader);

            // Render transitions in this group
            transitions.forEach(transition => {
                const item = document.createElement('div');
                item.className = 'transition-item';
                item.draggable = true;

                // Generate star rating based on preference
                const stars = this.getStarRating(transition.preference || 'Low');

                item.innerHTML = `
                    <div class="transition-content">
                        <span class="transition-stars">${stars}</span>
                        <span class="transition-name">${transition.name}</span>
                    </div>
                `;

                item.addEventListener('dragstart', (e) => {
                    e.dataTransfer.effectAllowed = 'copy';
                    e.dataTransfer.setData('application/json', JSON.stringify({
                        type: 'transition',
                        data: transition
                    }));
                });

                this.transitionList.appendChild(item);
            });
        });
    }

    /**
     * Get star rating string based on preference level
     */
    getStarRating(preference) {
        switch (preference) {
            case 'Highly Desired':
                return '***';
            case 'Mid':
                return '**';
            case 'Low':
                return '*';
            default:
                return '*';
        }
    }

    /**
     * Handle drag over timeline
     */
    onTimelineDragOver(e) {
        e.preventDefault();

        try {
            const data = JSON.parse(e.dataTransfer.getData('application/json'));
            const targetLayer = this.calculateTargetLayer(e);

            // Clear previous drag-over states
            this.clearDragOverStates();

            // Check if this is a valid drop for layer 0 (Shaders & Transitions only)
            const isValid = this.isValidDropForLayer(data.type, targetLayer);

            // Apply visual feedback
            const layerElements = document.querySelectorAll('.timeline-layer');
            const layerNameElements = document.querySelectorAll('.layer-name');

            if (layerElements[targetLayer + 1]) { // +1 to account for music layer
                layerElements[targetLayer + 1].classList.add(isValid ? 'drag-over-valid' : 'drag-over-invalid');
            }

            if (layerNameElements[targetLayer + 1]) { // +1 to account for ruler spacer
                layerNameElements[targetLayer + 1].classList.add(isValid ? 'drag-over-valid' : 'drag-over-invalid');
            }

            // Change cursor
            e.dataTransfer.dropEffect = isValid ? 'copy' : 'none';
        } catch (error) {
            // If we can't parse the data, allow the drop
            e.dataTransfer.dropEffect = 'copy';
        }
    }

    /**
     * Handle drag leave timeline
     */
    onTimelineDragLeave(e) {
        // Only clear if we're leaving the timeline container entirely
        if (e.target === e.currentTarget) {
            this.clearDragOverStates();
        }
    }

    /**
     * Clear all drag-over visual states
     */
    clearDragOverStates() {
        document.querySelectorAll('.drag-over-valid, .drag-over-invalid').forEach(el => {
            el.classList.remove('drag-over-valid', 'drag-over-invalid');
        });
    }

    /**
     * Calculate target layer from mouse position
     */
    calculateTargetLayer(e) {
        const rect = e.currentTarget.getBoundingClientRect();
        const y = e.clientY - rect.top;

        // Account for ruler height (30px) and music layer (40px)
        const adjustedY = y - 30 - 40;

        // Each layer is 60px tall
        const layerHeight = 60;
        return Math.max(0, Math.floor(adjustedY / layerHeight));
    }

    /**
     * Check if element type is valid for target layer
     * NOTE: With strict enforcement, items will auto-correct to proper layer
     * This validation is mainly for user feedback
     */
    isValidDropForLayer(elementType, targetLayer) {
        // Layer 0 is dedicated to green screen videos only (top visual layer)
        if (targetLayer === 0) {
            return elementType === 'video';
        }
        // Layer 1 is dedicated to shaders and transitions only (bottom visual layer)
        if (targetLayer === 1) {
            return elementType === 'shader' || elementType === 'transition';
        }
        // Layers 2+ are not currently used - redirect to proper layer
        return false;
    }

    /**
     * Calculate drop time from mouse X position on timeline
     */
    calculateDropTime(e) {
        const rect = e.currentTarget.getBoundingClientRect();
        const x = e.clientX - rect.left;
        const timelineWidth = this.timeline.container.offsetWidth;
        const dropTime = (x / timelineWidth) * this.timeline.duration;
        return Math.max(0, Math.min(dropTime, this.timeline.duration));
    }

    /**
     * Handle drop on timeline
     */
    onTimelineDrop(e) {
        e.preventDefault();

        // Clear drag-over states
        this.clearDragOverStates();

        try {
            const data = JSON.parse(e.dataTransfer.getData('application/json'));
            const targetLayer = this.calculateTargetLayer(e);
            const dropTime = this.calculateDropTime(e);

            // Determine the correct layer for this element type
            const correctLayer = (data.type === 'video') ? 0 : 1;

            // Validate drop and provide feedback if dropped on wrong layer
            if (!this.isValidDropForLayer(data.type, targetLayer)) {
                if (targetLayer === 0 && data.type !== 'video') {
                    // Dropped shader/transition on video layer - auto-correct with notification
                    console.log(`Auto-correcting: Shaders and transitions belong on Layer 1`);
                } else if (targetLayer === 1 && data.type === 'video') {
                    // Dropped video on shader layer - auto-correct with notification
                    console.log(`Auto-correcting: Videos belong on Layer 0`);
                } else if (targetLayer >= 2) {
                    // Dropped on unused layer - auto-correct
                    console.log(`Auto-correcting to proper layer: ${data.type === 'video' ? 'Layer 0' : 'Layer 1'}`);
                }
            }

            // Add element to timeline - it will automatically go to the correct layer
            // The timeline.addElement() now enforces strict layer assignment
            this.timeline.addElement(data.type, data.data, correctLayer, dropTime);
        } catch (error) {
            console.error('Error handling drop:', error);
        }
    }

    /**
     * Zoom in with fine granularity (0.1x steps)
     */
    zoomIn() {
        const oldZoom = this.timeline.zoom;

        // Use adaptive zoom steps: smaller steps at lower zoom, larger at higher zoom
        let step;
        if (this.timeline.zoom < 1.0) {
            step = 0.1;  // Fine control when zoomed out
        } else if (this.timeline.zoom < 5.0) {
            step = 0.25; // Medium steps at medium zoom
        } else {
            step = 0.5;  // Larger steps at high zoom
        }

        this.timeline.zoom += step;

        // Clamp to max zoom (frame level)
        this.timeline.zoom = Math.min(this.timeline.MAX_ZOOM, this.timeline.zoom);

        this.updateZoomDisplay(oldZoom);
    }

    /**
     * Zoom out with fine granularity (0.1x steps)
     */
    zoomOut() {
        const oldZoom = this.timeline.zoom;

        // Use adaptive zoom steps
        let step;
        if (this.timeline.zoom <= 1.0) {
            step = 0.1;  // Fine control when zoomed out
        } else if (this.timeline.zoom <= 5.0) {
            step = 0.25; // Medium steps at medium zoom
        } else {
            step = 0.5;  // Larger steps at high zoom
        }

        this.timeline.zoom -= step;

        // Clamp to min zoom (full timeline view)
        this.timeline.zoom = Math.max(this.timeline.MIN_ZOOM, this.timeline.zoom);

        this.updateZoomDisplay(oldZoom);
    }

    /**
     * Reset zoom to default 1.0x
     */
    resetZoom() {
        const oldZoom = this.timeline.zoom;
        this.timeline.zoom = 1.0;
        this.updateZoomDisplay(oldZoom);
    }

    /**
     * Update zoom display and re-render timeline
     */
    updateZoomDisplay(oldZoom) {
        console.log(`Timeline zoom: ${oldZoom.toFixed(2)} → ${this.timeline.zoom.toFixed(2)}`);

        // Update zoom display with percentage
        this.zoomDisplay.textContent = `Zoom: ${this.timeline.zoom.toFixed(1)}x`;

        // Highlight reset button when at default zoom
        if (Math.abs(this.timeline.zoom - 1.0) < 0.01) {
            this.zoomResetBtn.classList.add('at-default');
        } else {
            this.zoomResetBtn.classList.remove('at-default');
        }

        // Re-render timeline and ruler
        this.timeline.render();
        this.timeline.renderRuler();

        console.log('Timeline render and renderRuler called');
    }

    /**
     * Play audio/video (unified player)
     */
    play() {
        if (!this.selectedAudio) {
            console.warn('No audio selected');
            return;
        }

        if (this.isPlaying) {
            return; // Already playing
        }

        // Use the video element for both audio-only and video playback
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

        // Play audio/video
        this.videoPreview.play().then(() => {
            this.isPlaying = true;

            // Update button to show pause icon
            this.updatePlayPauseButton(true);

            // Update playhead position as media plays
            this.playbackInterval = setInterval(() => {
                if (this.videoPreview.currentTime >= this.selectedAudio.duration) {
                    // Reached end of audio/video
                    this.pause();
                    // Reset playhead to beginning
                    this.timeline.playheadPosition = 0;
                    this.timeline.updatePlayhead();
                    this.currentTimeDisplay.textContent = '00:00';
                } else {
                    this.timeline.playheadPosition = this.videoPreview.currentTime;
                    this.timeline.updatePlayhead();

                    // Update current time display
                    this.currentTimeDisplay.textContent = API.formatDuration(this.videoPreview.currentTime);

                    // Check for green screen video at current playhead position
                    this.updateGreenScreenPreview(this.timeline.playheadPosition);
                }
            }, 50); // Update every 50ms
        }).catch(error => {
            console.error('Error playing media:', error);
            alert('Failed to play: ' + error.message);
        });
    }

    /**
     * Pause audio/video (unified player)
     */
    pause() {
        if (!this.isPlaying) {
            return; // Already paused
        }

        // Pause audio/video
        this.videoPreview.pause();
        this.isPlaying = false;

        // Pause green screen preview if playing
        if (this.greenScreenPreview && !this.greenScreenPreview.paused) {
            this.greenScreenPreview.pause();
        }

        // Update button to show play icon
        this.updatePlayPauseButton(false);

        // Stop playhead updates
        if (this.playbackInterval) {
            clearInterval(this.playbackInterval);
            this.playbackInterval = null;
        }
    }

    /**
     * Toggle between play and pause
     */
    togglePlayPause() {
        if (this.isPlaying) {
            this.pause();
        } else {
            this.play();
        }
    }

    /**
     * Update play/pause button icon and state
     */
    updatePlayPauseButton(isPlaying) {
        if (isPlaying) {
            // Show pause icon when playing
            this.playPauseBtn.textContent = '⏸';
            this.playPauseBtn.classList.add('playing');
            this.playPauseBtn.title = 'Pause (Space)';
        } else {
            // Show play icon when paused
            this.playPauseBtn.textContent = '▶';
            this.playPauseBtn.classList.remove('playing');
            this.playPauseBtn.title = 'Play (Space)';
        }
    }

    /**
     * Seek to specific time position
     */
    seekTo(time) {
        if (!this.selectedAudio) {
            return;
        }

        // Update video/audio current time
        this.videoPreview.currentTime = time;

        // Update time display
        this.currentTimeDisplay.textContent = API.formatDuration(time);

        // Update green screen preview at new position
        this.updateGreenScreenPreview(time);

        // If playing, the playback interval will continue updating from new position
        // If paused, just update the position
    }

    /**
     * Update green screen video preview based on playhead position
     * Handles visual display and audio playback of green screen videos
     */
    updateGreenScreenPreview(currentTime) {
        // Check if there's a green screen video at current playhead position
        const greenScreen = this.timeline.getGreenScreenAtTime(currentTime);

        // Check if preview is enabled for this green screen video (default to enabled)
        const previewEnabled = !greenScreen || greenScreen.previewEnabled !== false;

        // Compare by element ID to avoid reloading same video
        const currentId = this.currentGreenScreen ? this.currentGreenScreen.id : null;
        const newId = greenScreen ? greenScreen.id : null;

        // If green screen changed (entered/exited a segment or different video)
        if (currentId !== newId) {
            if (greenScreen && previewEnabled) {
                // Entered a green screen segment or switched to different video (with preview enabled)
                this.startGreenScreenPreview(greenScreen, currentTime);
            } else {
                // Exited green screen segment or preview is disabled
                this.stopGreenScreenPreview();
            }
            this.currentGreenScreen = greenScreen;
        } else if (greenScreen && previewEnabled && this.isPlaying) {
            // Still in same green screen segment with preview enabled, ensure video is synced
            this.syncGreenScreenAudio(greenScreen, currentTime);
        } else if (greenScreen && !previewEnabled && this.greenScreenPreview.style.display !== 'none') {
            // Preview was disabled while in segment, stop preview
            this.stopGreenScreenPreview();
        }
    }

    /**
     * Handle green screen preview toggle event from timeline
     */
    onGreenScreenPreviewToggled(element) {
        // If this is the currently active green screen, update preview immediately
        if (this.currentGreenScreen && this.currentGreenScreen.id === element.id) {
            if (element.previewEnabled === false) {
                // Preview was disabled, stop showing it
                this.stopGreenScreenPreview();
                this.currentGreenScreen = null;
            } else {
                // Preview was enabled, start showing it
                this.startGreenScreenPreview(element, this.timeline.playheadPosition);
            }
        }
    }

    /**
     * Start green screen video preview
     */
    startGreenScreenPreview(greenScreen, currentTime) {
        console.log(`Starting green screen preview: ${greenScreen.data.name} at ${currentTime.toFixed(2)}s`);

        // Calculate offset within the green screen video
        const offset = currentTime - greenScreen.startTime;

        // Load green screen video source into overlay video element
        const videoPath = `/api/videos/file/${greenScreen.data.name}`;

        // Only change source if different video (avoid reloading same video)
        const needsSourceChange = this.greenScreenVideoPath !== videoPath;

        if (needsSourceChange) {
            console.log(`Loading new green screen video: ${greenScreen.data.name}`);
            this.greenScreenPreview.src = videoPath;
            this.greenScreenVideoPath = videoPath;

            // Wait for video to load before seeking
            this.greenScreenPreview.addEventListener('loadedmetadata', () => {
                this.greenScreenPreview.currentTime = offset;

                // Show green screen overlay
                this.greenScreenPreview.style.display = 'block';

                // Play video if currently playing
                if (this.isPlaying) {
                    this.greenScreenPreview.play().catch(err => {
                        console.warn('Failed to play green screen video:', err);
                    });
                }
            }, { once: true });
        } else {
            // Same video, just seek to correct position
            this.greenScreenPreview.currentTime = offset;

            // Show green screen overlay (in case it was hidden)
            this.greenScreenPreview.style.display = 'block';

            // Play video if currently playing
            if (this.isPlaying && this.greenScreenPreview.paused) {
                this.greenScreenPreview.play().catch(err => {
                    console.warn('Failed to play green screen video:', err);
                });
            }
        }
    }

    /**
     * Stop green screen video preview
     */
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

    /**
     * Sync green screen video with current playback position
     */
    syncGreenScreenAudio(greenScreen, currentTime) {
        const offset = currentTime - greenScreen.startTime;

        // Check if video is significantly out of sync (> 200ms to avoid constant seeking)
        const drift = Math.abs(this.greenScreenPreview.currentTime - offset);
        if (drift > 0.2) {
            console.log(`Green screen sync drift detected: ${drift.toFixed(3)}s, correcting...`);
            this.greenScreenPreview.currentTime = offset;
        }

        // Ensure video is playing if main playback is playing
        if (this.isPlaying && this.greenScreenPreview.paused) {
            this.greenScreenPreview.play().catch(err => {
                console.warn('Failed to sync green screen video:', err);
            });
        }
    }

    /**
     * Show save project modal
     */
    showSaveProjectModal() {
        // Pre-fill with current project name if re-saving
        this.projectNameInput.value = this.currentProjectName;
        this.saveProjectModal.style.display = 'flex';
        this.projectNameInput.focus();
        this.projectNameInput.select();
    }

    /**
     * Hide save project modal
     */
    hideSaveProjectModal() {
        this.saveProjectModal.style.display = 'none';
        this.projectNameInput.value = '';
    }

    /**
     * Confirm and save project
     */
    async confirmSaveProject() {
        const projectName = this.projectNameInput.value.trim();
        if (!projectName) {
            alert('Please enter a project name');
            this.projectNameInput.focus();
            return;
        }

        try {
            // Gather project data
            const projectData = {
                audio: this.selectedAudio,
                settings: {
                    resolution: this.resolutionSelect.value,
                    frameRate: parseInt(this.frameRateInput.value)
                },
                timeline: this.timeline.getTimelineData()
            };

            // Save via API
            await API.saveProject(projectName, projectData);

            // Update current project name
            this.currentProjectName = projectName;

            // Close modal and show success
            this.hideSaveProjectModal();
            alert('Project saved successfully!');
        } catch (error) {
            alert('Failed to save project: ' + error.message);
        }
    }

    /**
     * Show load project modal
     */
    async showLoadProjectModal() {
        this.loadProjectModal.style.display = 'flex';
        await this.loadProjectList();
    }

    /**
     * Hide load project modal
     */
    hideLoadProjectModal() {
        this.loadProjectModal.style.display = 'none';
    }

    /**
     * Load and display project list
     */
    async loadProjectList() {
        try {
            this.projectList.innerHTML = '<p class="loading-message">Loading projects...</p>';
            const projects = await API.listProjects();

            if (projects.length === 0) {
                this.projectList.innerHTML = `
                    <div class="no-projects-message">
                        <p>No saved projects found</p>
                        <p class="help-text">Save your current project to get started</p>
                    </div>
                `;
                return;
            }

            // Render project list
            this.projectList.innerHTML = '';
            projects.forEach(project => {
                const item = this.createProjectListItem(project);
                this.projectList.appendChild(item);
            });
        } catch (error) {
            this.projectList.innerHTML = `
                <div class="no-projects-message">
                    <p>Failed to load projects</p>
                    <p class="help-text">${error.message}</p>
                </div>
            `;
        }
    }

    /**
     * Create project list item element
     */
    createProjectListItem(project) {
        const item = document.createElement('div');
        item.className = 'project-item';

        const modifiedDate = project.modified ? new Date(project.modified).toLocaleString() : 'Unknown';

        item.innerHTML = `
            <div class="project-info">
                <div class="project-name">${project.name}</div>
                <div class="project-meta">
                    Audio: ${project.audio} • Modified: ${modifiedDate}
                </div>
            </div>
            <div class="project-actions">
                <button class="btn btn-primary btn-sm load-btn">Load</button>
                <button class="btn btn-danger btn-sm delete-btn">Delete</button>
            </div>
        `;

        // Load button handler
        item.querySelector('.load-btn').addEventListener('click', (e) => {
            e.stopPropagation();
            this.loadProjectFromFile(project.filename, project.name);
        });

        // Delete button handler
        item.querySelector('.delete-btn').addEventListener('click', (e) => {
            e.stopPropagation();
            this.deleteProjectFile(project.filename);
        });

        return item;
    }

    /**
     * Load project from file
     */
    async loadProjectFromFile(filename, projectName) {
        try {
            const projectData = await API.loadProject(filename);

            // Find matching audio file from stored audioFiles
            if (projectData.audio && projectData.audio.name) {
                const audioFile = this.audioFiles.find(a => a.name === projectData.audio.name);

                if (audioFile) {
                    // Find the corresponding DOM element
                    const audioItems = this.audioFileList.querySelectorAll('.audio-file-item');
                    const audioItem = Array.from(audioItems).find(item => item.dataset.path === audioFile.path);

                    if (audioItem) {
                        this.selectAudio(audioFile, audioItem);
                    }
                } else {
                    console.warn(`Audio file not found: ${projectData.audio.name}`);
                    alert(`Warning: Audio file "${projectData.audio.name}" was not found. Timeline may be empty.`);
                }
            }

            // Restore settings
            if (projectData.settings) {
                if (projectData.settings.resolution) {
                    this.resolutionSelect.value = projectData.settings.resolution;
                }
                if (projectData.settings.frameRate) {
                    this.frameRateInput.value = projectData.settings.frameRate;
                }
            }

            // Restore timeline after a short delay (to allow audio selection to complete)
            setTimeout(() => {
                if (projectData.timeline && projectData.timeline.layers) {
                    this.timeline.layers = projectData.timeline.layers;
                    this.timeline.render();
                }
            }, 100);

            // Update current project name
            this.currentProjectName = projectName;

            // Close modal
            this.hideLoadProjectModal();

            console.log(`Project "${projectName}" loaded successfully`);
        } catch (error) {
            alert('Failed to load project: ' + error.message);
        }
    }

    /**
     * Delete project file
     */
    async deleteProjectFile(filename) {
        if (!confirm('Are you sure you want to delete this project?')) {
            return;
        }

        try {
            await API.deleteProject(filename);
            await this.loadProjectList(); // Refresh list
        } catch (error) {
            alert('Failed to delete project: ' + error.message);
        }
    }

    /**
     * Render project to video
     */
    async renderProject() {
        if (!this.selectedAudio) {
            alert('Please select an audio file first.');
            return;
        }

        if (this.timeline.layers.length === 0) {
            alert('Timeline is empty. Please add some elements first.');
            return;
        }

        if (!confirm('Start rendering the video? This may take several minutes.')) {
            return;
        }

        // Enable all green screen previews before rendering
        // This ensures green screen videos are included in the render
        this.timeline.enableAllGreenScreenPreviews();

        try {
            // Get resolution from settings
            const resolutionValue = this.resolutionSelect.value;
            const [width, height] = resolutionValue.split('x').map(Number);

            // Get frame rate from settings
            const frameRate = parseInt(this.frameRateInput.value);

            // Generate render manifest
            const renderManifest = {
                version: "1.0",
                project_name: this.selectedAudio.name.replace(/\.[^/.]+$/, ""),
                audio: {
                    path: `Input_Audio/${this.selectedAudio.name}`,
                    duration: this.selectedAudio.duration
                },
                resolution: {
                    width: width,
                    height: height
                },
                frame_rate: frameRate,
                timeline: {
                    duration: this.timeline.duration,
                    elements: this.timeline.layers.map(el => ({
                        id: el.id,
                        type: el.type,
                        name: el.name,
                        startTime: el.startTime,
                        endTime: el.startTime + el.duration,
                        duration: el.duration,
                        layer: el.layer,
                        path: this.getElementPath(el),
                        // Add greenscreen config for videos on layer 1
                        ...(el.type === 'video' && el.layer === 1 ? {
                            greenscreen: {
                                enabled: true,
                                color: [0, 255, 0],
                                threshold: 0.4,
                                smoothness: 0.1
                            }
                        } : {})
                    }))
                }
            };

            console.log('Render manifest:', renderManifest);

            const response = await API.renderProject(renderManifest);

            // Show progress overlay
            this.renderProgressOverlay.style.display = 'flex';
            this.currentRenderPID = response.process_id;

            // Poll every 2 seconds for responsive progress updates
            this.renderPollInterval = setInterval(() => this.pollRenderStatus(), 2000);
            this.pollRenderStatus(); // Call immediately
        } catch (error) {
            console.error('Render error:', error);
            alert('Failed to start rendering: ' + error.message);
        }
    }

    /**
     * Get full file path for a timeline element
     */
    getElementPath(element) {
        const data = element.data;

        if (element.type === 'shader') {
            return `Shaders/${data.name}`;
        } else if (element.type === 'transition') {
            // Transitions need .glsl extension
            const name = data.name.endsWith('.glsl') ? data.name : `${data.name}.glsl`;
            return `Transitions/${name}`;
        } else if (element.type === 'video') {
            return `Input_Video/${data.name}`;
        }

        return data.name;
    }

    /**
     * Handle keyboard shortcuts
     */
    handleKeyboard(e) {
        // Space: Play/Pause
        if (e.code === 'Space' && e.target.tagName !== 'TEXTAREA' && e.target.tagName !== 'INPUT') {
            e.preventDefault();
            if (this.isPlaying) {
                this.pause();
            } else {
                this.play();
            }
        }
        
        // Delete: Remove selected element
        if (e.code === 'Delete' && this.timeline.selectedElement) {
            this.timeline.removeElement(this.timeline.selectedElement);
        }
        
        // Ctrl+Z: Undo
        if (e.ctrlKey && e.code === 'KeyZ') {
            e.preventDefault();
            this.timeline.undo();
        }
        
        // Ctrl+Y: Redo
        if (e.ctrlKey && e.code === 'KeyY') {
            e.preventDefault();
            this.timeline.redo();
        }
    }

    /**
     * Poll render status and update progress UI
     */
    async pollRenderStatus() {
        if (!this.currentRenderPID) return;

        try {
            const response = await fetch(`/api/render/status/${this.currentRenderPID}`);
            const data = await response.json();

            // Update progress bar
            this.renderProgressBar.style.width = `${data.progress}%`;

            // Update percentage text
            this.renderProgressText.textContent = `${Math.round(data.progress)}%`;

            // Update stage text with detailed information
            if (data.current_item && data.current_item !== 'None' && data.current_item !== '') {
                // Show detailed status with current item
                this.renderStageText.textContent = `${data.stage}: ${data.current_item}`;
            } else {
                // Show just the stage
                this.renderStageText.textContent = data.stage;
            }

            // Handle completion
            if (data.status === 'completed') {
                clearInterval(this.renderPollInterval);
                this.renderProgressOverlay.style.display = 'none';

                // Load rendered video into player
                const projectName = this.timeline.audioFileName.replace(/\.[^/.]+$/, ''); // Remove extension
                this.videoPreview.src = `/api/render/output/${projectName}.mp4`;
                this.hasRenderedVideo = true; // Mark that we now have a rendered video

                // Hide the overlay since we now have video content
                this.viewerOverlay.style.display = 'none';

                // Disable all green screen previews after render completes
                // This allows user to preview the rendered composite without green screen overlays
                this.timeline.disableAllGreenScreenPreviews();

                alert('Rendering complete! Video loaded in preview.');
                this.currentRenderPID = null;
            }

            // Handle failure
            if (data.status === 'failed') {
                clearInterval(this.renderPollInterval);
                this.renderProgressOverlay.style.display = 'none';
                alert(`Rendering failed: ${data.error || 'Check render_output.log for details'}`);
                this.currentRenderPID = null;
            }
        } catch (error) {
            console.error('Error polling render status:', error);
            // Don't stop polling on network errors - might be temporary
        }
    }
}

// Initialize editor when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
    window.editor = new VideoEditor();
});

