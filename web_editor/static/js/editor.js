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
        this.viewerOverlay = document.querySelector('.viewer-overlay');
        this.playBtn = document.getElementById('playBtn');
        this.pauseBtn = document.getElementById('pauseBtn');
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
        this.saveProjectBtn = document.getElementById('saveProjectBtn');
        this.renderBtn = document.getElementById('renderBtn');
        
        // Timeline controls
        this.zoomInBtn = document.getElementById('zoomInBtn');
        this.zoomOutBtn = document.getElementById('zoomOutBtn');
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
        
        // Timeline controls
        this.zoomInBtn.addEventListener('click', () => this.zoomTimeline(1.5));
        this.zoomOutBtn.addEventListener('click', () => this.zoomTimeline(0.67));
        this.undoBtn.addEventListener('click', () => this.timeline.undo());
        this.redoBtn.addEventListener('click', () => this.timeline.redo());
        
        // Playback controls
        this.playBtn.addEventListener('click', () => this.play());
        this.pauseBtn.addEventListener('click', () => this.pause());
        
        // Header buttons
        this.saveProjectBtn.addEventListener('click', () => this.saveProject());
        this.renderBtn.addEventListener('click', () => this.renderProject());

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
            const audioFiles = await API.getAudioFiles();
            this.renderAudioList(audioFiles);

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
        this.playBtn.disabled = false;
        this.pauseBtn.disabled = false;
        this.zoomInBtn.disabled = false;
        this.zoomOutBtn.disabled = false;
        this.undoBtn.disabled = false;
        this.redoBtn.disabled = false;

        // Initialize button states (paused by default)
        this.playBtn.style.opacity = '1';
        this.pauseBtn.style.opacity = '0.5';
        
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
        // All other layers accept any type
        return true;
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

            // Validate drop for specialized layers
            if (!this.isValidDropForLayer(data.type, targetLayer)) {
                if (targetLayer === 0) {
                    alert(`Layer 0 (Green Screen Videos) only accepts videos.\nPlease drop shaders and transitions on Layer 1.`);
                } else if (targetLayer === 1) {
                    alert(`Layer 1 (Shaders & Transitions) only accepts shaders and transitions.\nPlease drop videos on Layer 0.`);
                }
                return;
            }

            // Add element to timeline with auto-concatenation
            // The targetLayer is just a hint - the system will find the best placement
            this.timeline.addElement(data.type, data.data, targetLayer);
        } catch (error) {
            console.error('Error handling drop:', error);
        }
    }

    /**
     * Zoom timeline
     */
    zoomTimeline(factor) {
        const oldZoom = this.timeline.zoom;
        this.timeline.zoom *= factor;

        // Clamp zoom between 0.1 and 20.0
        this.timeline.zoom = Math.max(0.1, Math.min(20.0, this.timeline.zoom));

        console.log(`Timeline zoom: ${oldZoom.toFixed(2)} → ${this.timeline.zoom.toFixed(2)} (factor: ${factor})`);

        // Update zoom display
        this.zoomDisplay.textContent = `Zoom: ${this.timeline.zoom.toFixed(1)}x`;

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
        // Set audio source if not already set (and no rendered video loaded)
        if (!this.hasRenderedVideo && (!this.videoPreview.src || !this.videoPreview.src.includes(this.selectedAudio.name))) {
            this.videoPreview.src = this.selectedAudio.path;
        }

        // Start from current playhead position
        this.videoPreview.currentTime = this.timeline.playheadPosition;

        // Play audio/video
        this.videoPreview.play().then(() => {
            this.isPlaying = true;

            // Update button states
            this.playBtn.style.opacity = '0.5';
            this.pauseBtn.style.opacity = '1';

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

        // Update button states
        this.playBtn.style.opacity = '1';
        this.pauseBtn.style.opacity = '0.5';

        // Stop playhead updates
        if (this.playbackInterval) {
            clearInterval(this.playbackInterval);
            this.playbackInterval = null;
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

        // If playing, the playback interval will continue updating from new position
        // If paused, just update the position
    }

    /**
     * Save project
     */
    async saveProject() {
        try {
            const projectData = {
                audio: this.selectedAudio,
                timeline: this.timeline.getTimelineData()
            };
            
            await API.saveProject(projectData);
            alert('Project saved successfully!');
        } catch (error) {
            alert('Failed to save project: ' + error.message);
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

            // Poll every 10 seconds
            this.renderPollInterval = setInterval(() => this.pollRenderStatus(), 10000);
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

            // Update UI
            this.renderProgressBar.style.width = `${data.progress}%`;
            this.renderProgressText.textContent = `${Math.round(data.progress)}%`;
            this.renderStageText.textContent = data.stage;

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

