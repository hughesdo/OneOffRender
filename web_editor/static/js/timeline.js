/**
 * Timeline Module - Manages timeline state and rendering
 */

class Timeline {
    constructor() {
        this.duration = 0; // Total duration in seconds (locked to audio)
        this.layers = []; // Array of timeline layers
        this.selectedElement = null;
        this.zoom = 1.0; // Pixels per second
        this.playheadPosition = 0; // Current playhead position in seconds
        this.history = []; // Undo history
        this.historyIndex = -1;
        this.isDragging = false;
        this.isResizing = false;
        this.dragStartX = 0;
        this.dragStartTime = 0;
        this.audioFileName = ''; // Store audio file name for display

        // Zoom thresholds for dynamic tick mark scaling
        this.ZOOM_THRESHOLDS = {
            SHOW_10S: 1.0,
            SHOW_5S: 2.5,
            SHOW_1S: 5.0,
            SHOW_FRAMES: 10.0
        };
        this.FRAME_RATE = 30; // Assume 30fps for frame-level ticks

        this.container = document.querySelector('.timeline-tracks');
        this.rulerContainer = document.querySelector('.timeline-ruler');
        this.playhead = document.querySelector('.timeline-playhead');
        this.namesColumn = document.querySelector('.timeline-names-column');

        this.setupEventListeners();
    }

    /**
     * Initialize timeline with audio duration
     */
    initialize(audioDuration, audioFileName = '') {
        this.duration = audioDuration;
        this.audioFileName = audioFileName;
        this.layers = [];
        this.selectedElement = null;
        this.playheadPosition = 0;
        this.history = [];
        this.historyIndex = -1;

        this.render();
        this.renderRuler();
    }

    /**
     * Add a new element to the timeline with auto-placement
     */
    addElement(type, data, targetLayer = null) {
        const duration = this.calculateDefaultDuration(type, data, 0);

        // Find the best placement using auto-concatenation logic
        const placement = this.findAutoConcatenationPlacement(type, duration, targetLayer);

        const element = {
            id: this.generateId(),
            type: type, // 'shader', 'video', or 'transition'
            name: data.name,
            data: data,
            startTime: placement.startTime,
            duration: placement.duration,
            layer: placement.layer
        };

        this.layers.push(element);
        this.saveState();
        this.render();

        return element;
    }

    /**
     * Find optimal placement for auto-concatenation
     * Places elements at the end of existing content on the same layer
     */
    findAutoConcatenationPlacement(elementType, duration, targetLayer = null) {
        // Get all unique layer numbers, sorted
        const existingLayers = [...new Set(this.layers.map(el => el.layer))].sort((a, b) => a - b);

        // Check layer restrictions (Layer 0 = Videos, Layer 1 = Shaders/Transitions)
        const canUseLayer0 = elementType === 'video';
        const canUseLayer1 = elementType === 'shader' || elementType === 'transition';

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

        // If target layer is specified, try that first (respecting layer restrictions)
        if (targetLayer !== null && existingLayers.includes(targetLayer)) {
            // Check if element type is allowed on target layer
            const isAllowed = (targetLayer === 0 && canUseLayer0) ||
                            (targetLayer === 1 && canUseLayer1) ||
                            (targetLayer >= 2);

            if (isAllowed) {
                const placement = this.findEndOfLayer(targetLayer, duration);
                if (placement) {
                    return placement;
                }
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

            const placement = this.findEndOfLayer(layerNum, duration);
            if (placement) {
                return placement;
            }
        }

        // All existing layers are full or skipped, create a new layer starting at time 0
        // First, check if we can use the dedicated layers (0 or 1) if they don't exist yet
        let newLayerNum;

        if (canUseLayer0 && !existingLayers.includes(0)) {
            // Videos should use Layer 0 if it doesn't exist yet
            newLayerNum = 0;
        } else if (canUseLayer1 && !existingLayers.includes(1)) {
            // Shaders/transitions should use Layer 1 if it doesn't exist yet
            newLayerNum = 1;
        } else {
            // Both dedicated layers exist or are not applicable, use next available layer
            newLayerNum = existingLayers.length > 0 ? Math.max(...existingLayers) + 1 : 2;
        }

        return {
            layer: newLayerNum,
            startTime: 0,
            duration: Math.min(duration, this.duration)
        };
    }

    /**
     * Find the end position of a layer for concatenation
     * Returns null if the layer is full (spans entire timeline)
     */
    findEndOfLayer(layerNum, duration) {
        const elementsInLayer = this.layers.filter(el => el.layer === layerNum);

        if (elementsInLayer.length === 0) {
            // Empty layer, start at beginning
            return {
                layer: layerNum,
                startTime: 0,
                duration: Math.min(duration, this.duration)
            };
        }

        // Find the rightmost element in this layer
        let maxEndTime = 0;
        for (const el of elementsInLayer) {
            const endTime = el.startTime + el.duration;
            if (endTime > maxEndTime) {
                maxEndTime = endTime;
            }
        }

        // Check if there's room for the new element
        if (maxEndTime >= this.duration) {
            // Layer is full
            return null;
        }

        // Place at the end of the rightmost element
        const startTime = maxEndTime;
        const availableSpace = this.duration - startTime;
        const finalDuration = Math.min(duration, availableSpace);

        return {
            layer: layerNum,
            startTime: startTime,
            duration: finalDuration
        };
    }

    /**
     * Calculate default duration for an element
     */
    calculateDefaultDuration(type, data, dropTime) {
        if (type === 'transition') {
            return 1.6; // Fixed duration for transitions
        } else if (type === 'video') {
            // Use video duration, but cap at 10 seconds
            return Math.min(data.duration || 10, 10);
        } else if (type === 'shader') {
            // Default to 10 seconds for shaders
            return 10;
        }
        return 10; // Default fallback
    }

    /**
     * Find an available layer for the element
     */
    findAvailableLayer(startTime, duration = 10) {
        // Try to find an existing layer where this element can fit
        const endTime = startTime + duration;

        // Get all unique layer numbers
        const existingLayers = [...new Set(this.layers.map(el => el.layer))].sort((a, b) => a - b);

        // Try each existing layer
        for (const layerNum of existingLayers) {
            const elementsInLayer = this.layers.filter(el => el.layer === layerNum);
            const hasCollision = elementsInLayer.some(el => {
                const elEnd = el.startTime + el.duration;
                // Check if there's overlap
                return !(endTime <= el.startTime || startTime >= elEnd);
            });

            if (!hasCollision) {
                return layerNum; // Found a layer with no collision
            }
        }

        // No available layer found, create a new one
        return existingLayers.length > 0 ? Math.max(...existingLayers) + 1 : 0;
    }

    /**
     * Remove an element from the timeline
     */
    removeElement(elementId) {
        const index = this.layers.findIndex(el => el.id === elementId);
        if (index !== -1) {
            this.layers.splice(index, 1);
            this.saveState();
            this.render();
        }
    }

    /**
     * Update element position
     */
    updateElementPosition(elementId, newStartTime) {
        const element = this.layers.find(el => el.id === elementId);
        if (element) {
            // Ensure element stays within timeline bounds
            newStartTime = Math.max(0, Math.min(newStartTime, this.duration - element.duration));
            element.startTime = newStartTime;
            this.render();
        }
    }

    /**
     * Update element duration
     */
    updateElementDuration(elementId, newDuration) {
        const element = this.layers.find(el => el.id === elementId);
        if (element && element.type !== 'transition') {
            // Ensure duration is valid
            const maxDuration = this.duration - element.startTime;
            
            if (element.type === 'video') {
                // Video can't exceed its source duration
                newDuration = Math.min(newDuration, element.data.duration, maxDuration);
            } else {
                newDuration = Math.min(newDuration, maxDuration);
            }
            
            newDuration = Math.max(0.1, newDuration); // Minimum 0.1 seconds
            element.duration = newDuration;
            this.render();
        }
    }

    /**
     * Select an element
     */
    selectElement(elementId) {
        this.selectedElement = elementId;
        this.render();
    }

    /**
     * Deselect current element
     */
    deselectElement() {
        this.selectedElement = null;
        this.render();
    }

    /**
     * Render the timeline
     */
    render() {
        if (!this.container) return;

        // Clear existing content
        this.container.innerHTML = '';
        this.namesColumn.innerHTML = '';

        // Add spacer to align with ruler (30px)
        const rulerSpacer = document.createElement('div');
        rulerSpacer.className = 'ruler-spacer';
        this.namesColumn.appendChild(rulerSpacer);

        // Calculate timeline width based on duration and zoom
        const timelineWidth = this.duration * this.zoom * 100; // 100 pixels per second at zoom 1.0
        this.container.style.width = `${timelineWidth}px`;

        // Render music layer first (at the top)
        this.renderMusicLayer();

        // Group elements by layer
        const layerGroups = {};
        this.layers.forEach(element => {
            if (!layerGroups[element.layer]) {
                layerGroups[element.layer] = [];
            }
            layerGroups[element.layer].push(element);
        });

        // Render each layer
        const layerCount = Math.max(Object.keys(layerGroups).length, 5); // Minimum 5 layers
        for (let i = 0; i < layerCount; i++) {
            const layerDiv = document.createElement('div');
            layerDiv.className = 'timeline-layer';
            layerDiv.dataset.layer = i;

            // Render elements in this layer
            if (layerGroups[i]) {
                layerGroups[i].forEach(element => {
                    const elementDiv = this.createElementDiv(element);
                    layerDiv.appendChild(elementDiv);
                });
            }

            this.container.appendChild(layerDiv);

            // Add layer name
            const nameDiv = document.createElement('div');
            nameDiv.className = 'layer-name';
            // Layer 0 is dedicated to green screen videos (top visual layer)
            if (i === 0) {
                nameDiv.classList.add('green-screen-videos-layer');
                nameDiv.textContent = 'Green Screen Videos';
                nameDiv.dataset.layer = '0';
            }
            // Layer 1 is dedicated to shaders and transitions (bottom visual layer)
            else if (i === 1) {
                nameDiv.classList.add('shaders-transitions-layer');
                nameDiv.textContent = 'Shaders & Transitions';
                nameDiv.dataset.layer = '1';
            }
            else {
                nameDiv.textContent = `Layer ${i + 1}`;
            }
            this.namesColumn.appendChild(nameDiv);
        }

        // Update playhead position
        this.updatePlayhead();
    }

    /**
     * Render the music layer (fixed red bar at top)
     */
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

    /**
     * Create a DOM element for a timeline element
     */
    createElementDiv(element) {
        const div = document.createElement('div');
        div.className = `timeline-element ${element.type}`;
        div.dataset.id = element.id;
        
        if (this.selectedElement === element.id) {
            div.classList.add('selected');
        }

        // Calculate position and width
        const left = (element.startTime / this.duration) * 100;
        const width = (element.duration / this.duration) * 100;
        
        div.style.left = `${left}%`;
        div.style.width = `${width}%`;

        // Add element name
        const nameSpan = document.createElement('span');
        nameSpan.className = 'element-name';
        nameSpan.textContent = element.name;
        div.appendChild(nameSpan);

        // Add resize handles (not for transitions)
        if (element.type !== 'transition') {
            const leftHandle = document.createElement('div');
            leftHandle.className = 'resize-handle left';
            div.appendChild(leftHandle);

            const rightHandle = document.createElement('div');
            rightHandle.className = 'resize-handle right';
            div.appendChild(rightHandle);
        }

        return div;
    }

    /**
     * Render the timeline ruler with dynamic tick marks based on zoom level
     */
    renderRuler() {
        if (!this.rulerContainer) return;

        this.rulerContainer.innerHTML = '';

        const timelineWidth = this.duration * this.zoom * 100;
        this.rulerContainer.style.width = `${timelineWidth}px`;

        console.log(`renderRuler: zoom=${this.zoom.toFixed(2)}, timelineWidth=${timelineWidth}px`);

        // Always draw 30s major ticks (base layer)
        this.drawTickLayer(30, {
            className: 'tick-30s',
            labeled: true
        });
        console.log('✓ Drew 30s ticks');

        // Conditionally draw finer layers based on zoom
        if (this.zoom >= this.ZOOM_THRESHOLDS.SHOW_10S) {
            this.drawTickLayer(10, {
                className: 'tick-10s',
                labeled: false
            });
            console.log('✓ Drew 10s ticks (zoom >= 1.0)');
        }

        if (this.zoom >= this.ZOOM_THRESHOLDS.SHOW_5S) {
            this.drawTickLayer(5, {
                className: 'tick-5s',
                labeled: false
            });
            console.log('✓ Drew 5s ticks (zoom >= 2.5)');
        }

        if (this.zoom >= this.ZOOM_THRESHOLDS.SHOW_1S) {
            this.drawTickLayer(1, {
                className: 'tick-1s',
                labeled: false
            });
            console.log('✓ Drew 1s ticks (zoom >= 5.0)');
        }

        if (this.zoom >= this.ZOOM_THRESHOLDS.SHOW_FRAMES) {
            const frameInterval = 1 / this.FRAME_RATE; // 1/30s for 30fps
            this.drawTickLayer(frameInterval, {
                className: 'tick-frame',
                labeled: false
            });
            console.log('✓ Drew frame ticks (zoom >= 10.0)');
        }

        console.log(`renderRuler complete: ${this.rulerContainer.children.length} elements added`);
    }

    /**
     * Draw a layer of tick marks at specified interval
     */
    drawTickLayer(interval, options) {
        // Safety check for valid interval
        if (interval <= 0 || !isFinite(interval)) {
            console.warn(`Invalid tick interval: ${interval}`);
            return;
        }

        console.log(`drawTickLayer: interval=${interval}s, className=${options.className}`);

        // Performance optimization: only render visible ticks for very fine intervals
        let startTime = 0;
        let endTime = this.duration;

        // Only use viewport optimization for very fine intervals (< 1 second)
        if (interval < 1) {
            try {
                const containerRect = this.rulerContainer.getBoundingClientRect();
                const scrollLeft = this.rulerContainer.parentElement.scrollLeft || 0;
                const viewportWidth = this.rulerContainer.parentElement.clientWidth || containerRect.width;

                // Calculate visible time range
                startTime = Math.max(0, (scrollLeft / (this.zoom * 100)) * this.duration);
                endTime = Math.min(this.duration, ((scrollLeft + viewportWidth) / (this.zoom * 100)) * this.duration);

                // Extend range slightly to ensure smooth scrolling
                startTime = Math.max(0, startTime - interval * 5);
                endTime = Math.min(this.duration, endTime + interval * 5);
            } catch (e) {
                // Fallback to full range if viewport calculation fails
                startTime = 0;
                endTime = this.duration;
            }
        }

        // Find first tick position (align to interval boundaries)
        const firstTick = Math.floor(startTime / interval) * interval;

        // Limit maximum number of ticks to prevent performance issues
        const maxTicks = 10000;
        let tickCount = 0;

        for (let time = firstTick; time <= endTime && tickCount < maxTicks; time += interval) {
            // Round to avoid floating point precision issues
            time = Math.round(time * this.FRAME_RATE) / this.FRAME_RATE;

            // Skip if this exact time already has a 30s tick (avoid duplicates)
            if (interval !== 30 && Math.abs(time % 30) < 0.001) {
                continue;
            }

            // Skip negative times
            if (time < 0) {
                continue;
            }

            const marker = document.createElement('div');
            marker.className = `time-marker ${options.className}`;
            marker.style.left = `${(time / this.duration) * 100}%`;
            this.rulerContainer.appendChild(marker);

            // Add time label only for 30s ticks
            if (options.labeled && Math.abs(time % 30) < 0.001) {
                const label = document.createElement('div');
                label.className = 'time-label';
                label.textContent = API.formatDuration(time);
                label.style.left = `${(time / this.duration) * 100}%`;
                this.rulerContainer.appendChild(label);
            }

            tickCount++;
        }

        // Warn if we hit the tick limit
        if (tickCount >= maxTicks) {
            console.warn(`Tick limit reached for interval ${interval}s. Some ticks may not be visible.`);
        }

        console.log(`drawTickLayer complete: ${tickCount} ticks created for ${options.className}`);
    }

    /**
     * Update playhead position
     */
    updatePlayhead() {
        if (this.playhead && this.duration > 0) {
            const position = (this.playheadPosition / this.duration) * 100;
            this.playhead.style.left = `${position}%`;
        }
    }

    /**
     * Set playhead position
     */
    setPlayheadPosition(time) {
        this.playheadPosition = Math.max(0, Math.min(time, this.duration));
        this.updatePlayhead();
    }

    /**
     * Setup event listeners for drag and drop
     */
    setupEventListeners() {
        if (!this.container) return;

        // Use event delegation for timeline elements
        this.container.addEventListener('mousedown', (e) => {
            const elementDiv = e.target.closest('.timeline-element');

            // If clicking on empty timeline area (not on an element), seek playhead
            if (!elementDiv) {
                this.seekToPosition(e);
                return;
            }

            const elementId = elementDiv.dataset.id;
            const element = this.layers.find(el => el.id === elementId);
            if (!element) return;

            // Check if clicking on resize handle
            if (e.target.classList.contains('resize-handle')) {
                this.startResize(e, element, e.target.classList.contains('left'));
            } else {
                // Start dragging the element
                this.startDrag(e, element);
            }

            e.preventDefault();
        });

        // Right-click context menu for delete
        this.container.addEventListener('contextmenu', (e) => {
            const elementDiv = e.target.closest('.timeline-element');
            if (elementDiv) {
                e.preventDefault();
                const elementId = elementDiv.dataset.id;
                if (confirm('Delete this element?')) {
                    this.removeElement(elementId);
                }
            }
        });

        // Global mouse move and up handlers
        document.addEventListener('mousemove', (e) => {
            if (this.isDragging) {
                this.handleDrag(e);
            } else if (this.isResizing) {
                this.handleResize(e);
            }
        });

        document.addEventListener('mouseup', (e) => {
            if (this.isDragging || this.isResizing) {
                this.endDragOrResize();
            }
        });

        // Click on ruler to seek
        if (this.rulerContainer) {
            this.rulerContainer.addEventListener('click', (e) => {
                this.seekToPosition(e);
            });
        }
    }

    /**
     * Seek playhead to clicked position on timeline
     */
    seekToPosition(e) {
        const rect = this.container.getBoundingClientRect();
        const clickX = e.clientX - rect.left;
        const timelineWidth = this.container.offsetWidth;
        const clickedTime = (clickX / timelineWidth) * this.duration;

        // Clamp to valid range
        const newTime = Math.max(0, Math.min(clickedTime, this.duration));

        // Update playhead position
        this.setPlayheadPosition(newTime);

        // Notify editor to update video/audio position
        if (window.editor) {
            window.editor.seekTo(newTime);
        }
    }

    /**
     * Start dragging an element
     */
    startDrag(e, element) {
        this.isDragging = true;
        this.draggedElement = element;
        this.dragStartX = e.clientX;
        this.dragStartTime = element.startTime;
        this.selectElement(element.id);
        document.body.style.cursor = 'grabbing';
    }

    /**
     * Handle dragging an element
     */
    handleDrag(e) {
        if (!this.isDragging || !this.draggedElement) return;

        const deltaX = e.clientX - this.dragStartX;
        const timelineWidth = this.container.offsetWidth;
        const deltaTime = (deltaX / timelineWidth) * this.duration;

        let newStartTime = this.dragStartTime + deltaTime;

        // Clamp to timeline bounds
        newStartTime = Math.max(0, Math.min(newStartTime, this.duration - this.draggedElement.duration));

        // Check for collisions with other elements on the same layer
        newStartTime = this.checkCollisions(this.draggedElement, newStartTime, this.draggedElement.duration);

        this.draggedElement.startTime = newStartTime;
        this.render();
    }

    /**
     * Start resizing an element
     */
    startResize(e, element, isLeftHandle) {
        this.isResizing = true;
        this.resizedElement = element;
        this.resizeLeft = isLeftHandle;
        this.dragStartX = e.clientX;
        this.dragStartTime = element.startTime;
        this.dragStartDuration = element.duration;
        this.selectElement(element.id);
        document.body.style.cursor = isLeftHandle ? 'w-resize' : 'e-resize';
    }

    /**
     * Handle resizing an element
     */
    handleResize(e) {
        if (!this.isResizing || !this.resizedElement) return;

        const deltaX = e.clientX - this.dragStartX;
        const timelineWidth = this.container.offsetWidth;
        const deltaTime = (deltaX / timelineWidth) * this.duration;

        if (this.resizeLeft) {
            // Resizing from the left
            let newStartTime = this.dragStartTime + deltaTime;
            let newDuration = this.dragStartDuration - deltaTime;

            // Clamp to bounds
            newStartTime = Math.max(0, newStartTime);
            newDuration = Math.max(0.1, newDuration);

            // Ensure doesn't exceed timeline
            if (newStartTime + newDuration > this.duration) {
                newDuration = this.duration - newStartTime;
            }

            // Check collision on the left
            const leftCollision = this.findLeftCollision(this.resizedElement, newStartTime);
            if (leftCollision !== null) {
                newStartTime = leftCollision;
                newDuration = this.dragStartTime + this.dragStartDuration - newStartTime;
            }

            this.resizedElement.startTime = newStartTime;
            this.resizedElement.duration = newDuration;
        } else {
            // Resizing from the right
            let newDuration = this.dragStartDuration + deltaTime;

            // Clamp to bounds
            newDuration = Math.max(0.1, newDuration);

            // Ensure doesn't exceed timeline
            if (this.resizedElement.startTime + newDuration > this.duration) {
                newDuration = this.duration - this.resizedElement.startTime;
            }

            // Check collision on the right
            const rightCollision = this.findRightCollision(this.resizedElement, this.resizedElement.startTime + newDuration);
            if (rightCollision !== null) {
                newDuration = rightCollision - this.resizedElement.startTime;
            }

            this.resizedElement.duration = newDuration;
        }

        this.render();
    }

    /**
     * End drag or resize operation
     */
    endDragOrResize() {
        if (this.isDragging || this.isResizing) {
            this.saveState();
        }
        this.isDragging = false;
        this.isResizing = false;
        this.draggedElement = null;
        this.resizedElement = null;
        document.body.style.cursor = 'default';
    }

    /**
     * Check for collisions and adjust position
     */
    checkCollisions(element, newStartTime, duration) {
        const newEndTime = newStartTime + duration;

        // Find elements on the same layer
        const sameLayerElements = this.layers.filter(el =>
            el.layer === element.layer && el.id !== element.id
        );

        for (const other of sameLayerElements) {
            const otherEnd = other.startTime + other.duration;

            // Check if there's overlap
            if (newStartTime < otherEnd && newEndTime > other.startTime) {
                // Collision detected - snap to edge
                if (newStartTime < other.startTime) {
                    // Moving right into element, snap to left edge
                    return other.startTime - duration;
                } else {
                    // Moving left into element, snap to right edge
                    return otherEnd;
                }
            }
        }

        return newStartTime;
    }

    /**
     * Find collision on the left side
     */
    findLeftCollision(element, newStartTime) {
        const sameLayerElements = this.layers.filter(el =>
            el.layer === element.layer && el.id !== element.id
        );

        for (const other of sameLayerElements) {
            const otherEnd = other.startTime + other.duration;
            if (otherEnd > newStartTime && other.startTime < newStartTime) {
                return otherEnd; // Snap to right edge of colliding element
            }
        }

        return null;
    }

    /**
     * Find collision on the right side
     */
    findRightCollision(element, newEndTime) {
        const sameLayerElements = this.layers.filter(el =>
            el.layer === element.layer && el.id !== element.id
        );

        for (const other of sameLayerElements) {
            if (other.startTime < newEndTime && other.startTime > element.startTime) {
                return other.startTime; // Snap to left edge of colliding element
            }
        }

        return null;
    }

    /**
     * Save current state for undo
     */
    saveState() {
        const state = JSON.parse(JSON.stringify(this.layers));
        this.history = this.history.slice(0, this.historyIndex + 1);
        this.history.push(state);
        this.historyIndex++;
    }

    /**
     * Undo last action
     */
    undo() {
        if (this.historyIndex > 0) {
            this.historyIndex--;
            this.layers = JSON.parse(JSON.stringify(this.history[this.historyIndex]));
            this.render();
        }
    }

    /**
     * Redo last undone action
     */
    redo() {
        if (this.historyIndex < this.history.length - 1) {
            this.historyIndex++;
            this.layers = JSON.parse(JSON.stringify(this.history[this.historyIndex]));
            this.render();
        }
    }

    /**
     * Generate unique ID
     */
    generateId() {
        return `element_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    }

    /**
     * Get timeline data for export
     */
    getTimelineData() {
        return {
            duration: this.duration,
            layers: this.layers
        };
    }
}

// Export for use in other modules
window.Timeline = Timeline;

