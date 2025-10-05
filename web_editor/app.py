#!/usr/bin/env python3
"""
OneOffRender Web Editor - Flask Backend
Provides API endpoints for the web-based video editor interface.
"""

import os
import json
import logging
from pathlib import Path
from flask import Flask, render_template, jsonify, request, send_from_directory
from flask_cors import CORS
import subprocess
import librosa

app = Flask(__name__)
CORS(app)

# Configure paths
BASE_DIR = Path(__file__).parent.parent
SHADERS_DIR = BASE_DIR / "Shaders"
TRANSITIONS_DIR = BASE_DIR / "Transitions"
INPUT_AUDIO_DIR = BASE_DIR / "Input_Audio"
INPUT_VIDEO_DIR = BASE_DIR / "Input_Video"
THUMBNAILS_DIR = INPUT_VIDEO_DIR / "thumbnails"

# Ensure thumbnails directory exists
THUMBNAILS_DIR.mkdir(exist_ok=True)

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


@app.route('/')
def index():
    """Serve the main editor interface."""
    return render_template('editor.html')


@app.route('/api/audio/list')
def list_audio_files():
    """List all available audio files."""
    try:
        audio_extensions = ['.mp3', '.wav', '.flac', '.m4a', '.aac', '.ogg']
        audio_files = []

        for ext in audio_extensions:
            for file_path in INPUT_AUDIO_DIR.glob(f'*{ext}'):
                # Get audio duration
                try:
                    duration = librosa.get_duration(path=str(file_path))
                except Exception as e:
                    logger.warning(f"Could not get duration for {file_path.name}: {e}")
                    duration = 0

                audio_files.append({
                    'name': file_path.name,
                    'path': f'/api/audio/file/{file_path.name}',  # URL path for serving
                    'duration': duration,
                    'size': file_path.stat().st_size
                })

        return jsonify({'success': True, 'files': audio_files})
    except Exception as e:
        logger.error(f"Error listing audio files: {e}")
        return jsonify({'success': False, 'error': str(e)}), 500


@app.route('/api/audio/file/<path:filename>')
def serve_audio_file(filename):
    """Serve an audio file."""
    try:
        return send_from_directory(INPUT_AUDIO_DIR, filename)
    except Exception as e:
        logger.error(f"Error serving audio file {filename}: {e}")
        return jsonify({'success': False, 'error': str(e)}), 404


@app.route('/api/shaders/list')
def list_shaders():
    """List all available shaders with metadata."""
    try:
        metadata_path = SHADERS_DIR / "metadata.json"
        
        if not metadata_path.exists():
            return jsonify({'success': False, 'error': 'metadata.json not found'}), 404
        
        with open(metadata_path, 'r') as f:
            shaders = json.load(f)
        
        # Add full paths for preview images
        for shader in shaders:
            shader['preview_path'] = f"/api/shaders/preview/{shader['preview_image']}"
        
        return jsonify({'success': True, 'shaders': shaders})
    except Exception as e:
        logger.error(f"Error listing shaders: {e}")
        return jsonify({'success': False, 'error': str(e)}), 500


@app.route('/api/shaders/preview/<path:filename>')
def get_shader_preview(filename):
    """Serve shader preview images."""
    return send_from_directory(SHADERS_DIR, filename)


@app.route('/api/shaders/update', methods=['POST'])
def update_shader_metadata():
    """Update shader metadata (stars and description)."""
    try:
        data = request.json
        shader_name = data.get('name')
        stars = data.get('stars')
        description = data.get('description')
        
        if not shader_name:
            return jsonify({'success': False, 'error': 'Shader name required'}), 400
        
        # Validate description length
        if description and len(description) > 256:
            return jsonify({'success': False, 'error': 'Description must be 256 characters or less'}), 400
        
        # Load current metadata
        metadata_path = SHADERS_DIR / "metadata.json"
        with open(metadata_path, 'r') as f:
            shaders = json.load(f)
        
        # Find and update the shader
        shader_found = False
        for shader in shaders:
            if shader['name'] == shader_name:
                if stars is not None:
                    shader['stars'] = int(stars)
                if description is not None:
                    shader['description'] = description
                shader_found = True
                break
        
        if not shader_found:
            return jsonify({'success': False, 'error': 'Shader not found'}), 404
        
        # Save updated metadata
        with open(metadata_path, 'w') as f:
            json.dump(shaders, f, indent=2)
        
        return jsonify({'success': True, 'message': 'Shader metadata updated'})
    except Exception as e:
        logger.error(f"Error updating shader metadata: {e}")
        return jsonify({'success': False, 'error': str(e)}), 500


@app.route('/api/videos/list')
def list_videos():
    """List all available video files with thumbnails."""
    try:
        video_extensions = ['.mp4', '.avi', '.mov', '.mkv', '.webm']
        videos = []
        
        for ext in video_extensions:
            for file_path in INPUT_VIDEO_DIR.glob(f'*{ext}'):
                # Generate thumbnail if it doesn't exist
                thumbnail_name = f"{file_path.stem}_thumb.jpg"
                thumbnail_path = THUMBNAILS_DIR / thumbnail_name
                
                if not thumbnail_path.exists():
                    generate_thumbnail(file_path, thumbnail_path)
                
                # Get video duration using ffprobe
                try:
                    result = subprocess.run(
                        ['ffprobe', '-v', 'error', '-show_entries', 'format=duration',
                         '-of', 'default=noprint_wrappers=1:nokey=1', str(file_path)],
                        capture_output=True, text=True, check=True
                    )
                    duration = float(result.stdout.strip())
                except Exception as e:
                    logger.warning(f"Could not get duration for {file_path.name}: {e}")
                    duration = 0
                
                videos.append({
                    'name': file_path.name,
                    'path': str(file_path.relative_to(BASE_DIR)),
                    'duration': duration,
                    'size': file_path.stat().st_size,
                    'thumbnail': f"/api/videos/thumbnail/{thumbnail_name}"
                })
        
        return jsonify({'success': True, 'videos': videos})
    except Exception as e:
        logger.error(f"Error listing videos: {e}")
        return jsonify({'success': False, 'error': str(e)}), 500


@app.route('/api/videos/thumbnail/<path:filename>')
def get_video_thumbnail(filename):
    """Serve video thumbnail images."""
    return send_from_directory(THUMBNAILS_DIR, filename)


@app.route('/api/transitions/list')
def list_transitions():
    """List all available transition shaders from metadata JSON with filtering and sorting."""
    try:
        transitions = []

        # Load metadata JSON
        metadata_path = TRANSITIONS_DIR / 'Transitions_Metadata.json'
        if not metadata_path.exists():
            logger.warning(f"Transitions metadata file not found: {metadata_path}")
            # Fallback to filesystem scan
            for file_path in TRANSITIONS_DIR.glob('*.glsl'):
                transitions.append({
                    'name': file_path.stem,
                    'filename': file_path.name,
                    'path': str(file_path.relative_to(BASE_DIR)),
                    'preference': 'Low',
                    'status': 'Unknown'
                })
        else:
            with open(metadata_path, 'r', encoding='utf-8') as f:
                metadata = json.load(f)

            # Process each transition from metadata
            for filename, data in metadata.items():
                # Skip transitions with "Broken" status
                status = data.get('status', 'Unknown')
                if status == 'Broken':
                    continue

                # Check if the actual file exists
                file_path = TRANSITIONS_DIR / filename
                if not file_path.exists():
                    logger.warning(f"Transition file not found: {filename}")
                    continue

                transitions.append({
                    'name': file_path.stem,
                    'filename': filename,
                    'path': str(file_path.relative_to(BASE_DIR)),
                    'preference': data.get('preference', 'Low'),
                    'status': status
                })

        # Sort by preference (Highly Desired -> Mid -> Low), then alphabetically
        preference_order = {'Highly Desired': 0, 'Mid': 1, 'Low': 2}
        transitions.sort(key=lambda x: (
            preference_order.get(x['preference'], 3),  # Unknown preferences go last
            x['name'].lower()  # Alphabetical within each preference group
        ))

        return jsonify({'success': True, 'transitions': transitions})
    except Exception as e:
        logger.error(f"Error listing transitions: {e}")
        return jsonify({'success': False, 'error': str(e)}), 500


@app.route('/api/project/save', methods=['POST'])
def save_project():
    """Save the current timeline project."""
    try:
        project_data = request.json

        # TODO: Implement project saving logic
        # For now, just return success

        return jsonify({'success': True, 'message': 'Project saved'})
    except Exception as e:
        logger.error(f"Error saving project: {e}")
        return jsonify({'success': False, 'error': str(e)}), 500


@app.route('/api/render/test', methods=['GET'])
def test_render():
    """Test render endpoint - renders test_render_manifest.json"""
    try:
        import subprocess
        import sys

        manifest_path = Path('test_render_manifest.json')
        if not manifest_path.exists():
            return jsonify({'success': False, 'error': 'test_render_manifest.json not found'}), 404

        python_exe = sys.executable
        log_file = open('test_render_output.log', 'w')

        process = subprocess.Popen(
            [python_exe, 'render_timeline.py', str(manifest_path)],
            stdout=log_file,
            stderr=subprocess.STDOUT,
            text=True,
            cwd=str(Path.cwd())
        )

        logger.info(f"Started TEST render process (PID: {process.pid})")

        return jsonify({
            'success': True,
            'message': 'Test render started',
            'process_id': process.pid,
            'log_file': 'test_render_output.log'
        })

    except Exception as e:
        logger.error(f"Error starting test render: {e}")
        import traceback
        traceback.print_exc()
        return jsonify({'success': False, 'error': str(e)}), 500


@app.route('/api/project/render', methods=['POST'])
def render_project():
    """Render the timeline to a video file."""
    try:
        render_manifest = request.json

        # Validate manifest structure
        if 'audio' not in render_manifest or 'timeline' not in render_manifest:
            return jsonify({'success': False, 'error': 'Invalid manifest structure'}), 400

        # Save manifest to temporary file
        manifest_path = Path("temp_render_manifest.json")
        with open(manifest_path, 'w') as f:
            json.dump(render_manifest, f, indent=2)

        logger.info(f"Saved render manifest: {manifest_path}")
        logger.info(f"Timeline elements: {len(render_manifest['timeline'].get('elements', []))}")

        # Launch render_timeline.py as subprocess (async rendering)
        import subprocess
        import sys

        # Use the same Python interpreter that's running Flask
        python_exe = sys.executable

        # Create log file for render output
        log_file = open('render_output.log', 'w')

        process = subprocess.Popen(
            [python_exe, 'render_timeline.py', str(manifest_path)],
            stdout=log_file,
            stderr=subprocess.STDOUT,
            text=True,
            cwd=str(Path.cwd())
        )

        logger.info(f"Started render process (PID: {process.pid})")
        logger.info(f"Python executable: {python_exe}")
        logger.info(f"Working directory: {Path.cwd()}")
        logger.info(f"Render output will be logged to: render_output.log")

        # Return immediately (async rendering)
        return jsonify({
            'success': True,
            'message': 'Rendering started',
            'manifest_path': str(manifest_path),
            'process_id': process.pid,
            'log_file': 'render_output.log'
        })

    except Exception as e:
        logger.error(f"Error rendering project: {e}")
        import traceback
        traceback.print_exc()
        return jsonify({'success': False, 'error': str(e)}), 500


def generate_thumbnail(video_path, thumbnail_path):
    """Generate a thumbnail for a video at the 3-second mark."""
    try:
        subprocess.run(
            ['ffmpeg', '-i', str(video_path), '-ss', '00:00:03', '-vframes', '1',
             '-vf', 'scale=320:-1', str(thumbnail_path)],
            capture_output=True, check=True
        )
        logger.info(f"Generated thumbnail for {video_path.name}")
    except subprocess.CalledProcessError as e:
        logger.error(f"Failed to generate thumbnail for {video_path.name}: {e}")
        # Create a placeholder thumbnail
        from PIL import Image, ImageDraw, ImageFont
        img = Image.new('RGB', (320, 180), color=(50, 50, 50))
        draw = ImageDraw.Draw(img)
        draw.text((10, 80), "No Preview", fill=(200, 200, 200))
        img.save(thumbnail_path)


@app.route('/api/render/status/<int:process_id>')
def get_render_status(process_id):
    """Read render_output.log and return progress."""
    try:
        log_file = Path('render_output.log')
        if not log_file.exists():
            return jsonify({'status': 'starting', 'progress': 0, 'stage': 'Initializing...'})

        # Read last 50 lines only (efficient)
        with open(log_file, 'r', encoding='utf-8', errors='ignore') as f:
            lines = f.readlines()[-50:]

        progress = 0
        stage = 'Starting...'
        status = 'running'

        for line in reversed(lines):
            if '=== Rendering Completed' in line:
                return jsonify({'status': 'completed', 'progress': 100, 'stage': 'Complete!'})
            if 'Rendering failed:' in line or 'ERROR' in line:
                return jsonify({'status': 'failed', 'progress': progress, 'stage': 'Error occurred', 'error': line.strip()})
            if 'Progress:' in line:
                import re
                match = re.search(r'Progress: ([\d.]+)%', line)
                if match:
                    progress = float(match.group(1))
            if '--- Rendering Layer 1' in line:
                stage = 'Rendering shaders...'
            elif '--- Rendering Layer 0' in line:
                stage = 'Rendering videos...'
            elif '--- Compositing' in line:
                stage = 'Compositing layers...'
            elif '--- Adding Audio' in line:
                stage = 'Adding audio...'

        return jsonify({'status': status, 'progress': progress, 'stage': stage})
    except Exception as e:
        logger.error(f"Error getting render status: {e}")
        return jsonify({'status': 'error', 'error': str(e)}), 500


@app.route('/api/render/output/<path:filename>')
def serve_output_video(filename):
    """Serve completed video from Output_Video folder."""
    try:
        output_dir = BASE_DIR / 'Output_Video'
        return send_from_directory(output_dir, filename)
    except Exception as e:
        logger.error(f"Error serving output video {filename}: {e}")
        return jsonify({'success': False, 'error': str(e)}), 404


if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)

