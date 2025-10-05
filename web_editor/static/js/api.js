/**
 * API Module - Handles all backend communication
 */

const API = {
    baseUrl: '',

    /**
     * Fetch all available audio files
     */
    async getAudioFiles() {
        try {
            const response = await fetch(`${this.baseUrl}/api/audio/list`);
            const data = await response.json();
            if (!data.success) {
                throw new Error(data.error || 'Failed to fetch audio files');
            }
            return data.files;
        } catch (error) {
            console.error('Error fetching audio files:', error);
            throw error;
        }
    },

    /**
     * Fetch all available shaders with metadata
     */
    async getShaders() {
        try {
            const response = await fetch(`${this.baseUrl}/api/shaders/list`);
            const data = await response.json();
            if (!data.success) {
                throw new Error(data.error || 'Failed to fetch shaders');
            }
            return data.shaders;
        } catch (error) {
            console.error('Error fetching shaders:', error);
            throw error;
        }
    },

    /**
     * Update shader metadata (stars and description)
     */
    async updateShaderMetadata(name, stars, description) {
        try {
            const response = await fetch(`${this.baseUrl}/api/shaders/update`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({ name, stars, description })
            });
            const data = await response.json();
            if (!data.success) {
                throw new Error(data.error || 'Failed to update shader metadata');
            }
            return data;
        } catch (error) {
            console.error('Error updating shader metadata:', error);
            throw error;
        }
    },

    /**
     * Fetch all available videos with thumbnails
     */
    async getVideos() {
        try {
            const response = await fetch(`${this.baseUrl}/api/videos/list`);
            const data = await response.json();
            if (!data.success) {
                throw new Error(data.error || 'Failed to fetch videos');
            }
            return data.videos;
        } catch (error) {
            console.error('Error fetching videos:', error);
            throw error;
        }
    },

    /**
     * Fetch all available transitions
     */
    async getTransitions() {
        try {
            const response = await fetch(`${this.baseUrl}/api/transitions/list`);
            const data = await response.json();
            if (!data.success) {
                throw new Error(data.error || 'Failed to fetch transitions');
            }
            return data.transitions;
        } catch (error) {
            console.error('Error fetching transitions:', error);
            throw error;
        }
    },

    /**
     * Save the current project
     */
    async saveProject(projectData) {
        try {
            const response = await fetch(`${this.baseUrl}/api/project/save`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(projectData)
            });
            const data = await response.json();
            if (!data.success) {
                throw new Error(data.error || 'Failed to save project');
            }
            return data;
        } catch (error) {
            console.error('Error saving project:', error);
            throw error;
        }
    },

    /**
     * Render the timeline to video
     */
    async renderProject(timelineData) {
        try {
            const response = await fetch(`${this.baseUrl}/api/project/render`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(timelineData)
            });
            const data = await response.json();
            if (!data.success) {
                throw new Error(data.error || 'Failed to render project');
            }
            return data;
        } catch (error) {
            console.error('Error rendering project:', error);
            throw error;
        }
    },

    /**
     * Format duration in seconds to MM:SS format
     */
    formatDuration(seconds) {
        const mins = Math.floor(seconds / 60);
        const secs = Math.floor(seconds % 60);
        return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
    },

    /**
     * Format file size to human-readable format
     */
    formatFileSize(bytes) {
        if (bytes === 0) return '0 Bytes';
        const k = 1024;
        const sizes = ['Bytes', 'KB', 'MB', 'GB'];
        const i = Math.floor(Math.log(bytes) / Math.log(k));
        return Math.round(bytes / Math.pow(k, i) * 100) / 100 + ' ' + sizes[i];
    }
};

// Export for use in other modules
window.API = API;

