#!/usr/bin/env python3
"""
OneOffRender Timeline Renderer
Renders videos from timeline JSON manifests with precise timing control.
Supports multi-layer compositing including shaders, transitions, and green screen videos.
"""

import json
import logging
import sys
import time
from pathlib import Path
import subprocess
import tempfile
import shutil

import numpy as np
import moderngl
from PIL import Image
import librosa
import ffmpeg


class TimelineRenderer:
    """Renders videos from timeline JSON manifests with layer-based compositing."""
    
    def __init__(self, manifest_path):
        """Initialize the timeline renderer with a manifest file."""
        self.manifest_path = Path(manifest_path)
        self.manifest = self.load_manifest()
        self.setup_logging()
        self.ctx = None
        self.temp_dir = Path(tempfile.mkdtemp(prefix="timeline_render_"))
        self.logger.info(f"Temporary directory: {self.temp_dir}")

        # Track current transition for logging (only log start/end)
        self.current_transition_name = None
        self.current_transition_pair = None  # (from_shader, to_shader)
        
    def load_manifest(self):
        """Load timeline render manifest from JSON file."""
        if not self.manifest_path.exists():
            raise FileNotFoundError(f"Manifest file not found: {self.manifest_path}")
        
        with open(self.manifest_path, 'r') as f:
            manifest = json.load(f)
        
        # Validate manifest structure
        required_keys = ['version', 'audio', 'timeline']
        for key in required_keys:
            if key not in manifest:
                raise ValueError(f"Missing required key in manifest: {key}")
        
        return manifest
    
    def setup_logging(self):
        """Setup logging for the renderer."""
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(levelname)s - %(message)s',
            datefmt='%H:%M:%S'
        )
        self.logger = logging.getLogger(__name__)
    
    def validate_manifest(self):
        """Validate that all referenced files exist."""
        self.logger.info("Validating manifest...")
        
        # Check audio file
        audio_path = Path(self.manifest['audio']['path'])
        if not audio_path.exists():
            raise FileNotFoundError(f"Audio file not found: {audio_path}")
        
        # Check all timeline elements
        for element in self.manifest['timeline']['elements']:
            if 'path' in element:
                element_path = Path(element['path'])
                if not element_path.exists():
                    raise FileNotFoundError(
                        f"{element['type']} file not found: {element_path} "
                        f"(element: {element['name']})"
                    )
        
        self.logger.info("✓ Manifest validation passed")
    
    def get_elements_by_layer(self, layer_num):
        """Get all elements on a specific layer, sorted by startTime."""
        elements = [
            el for el in self.manifest['timeline']['elements']
            if el['layer'] == layer_num
        ]
        elements.sort(key=lambda x: x['startTime'])
        return elements
    
    def get_resolution(self):
        """Get render resolution from manifest."""
        res = self.manifest.get('resolution', {'width': 2560, 'height': 1440})
        return res['width'], res['height']
    
    def get_frame_rate(self):
        """Get frame rate from manifest."""
        return self.manifest.get('frame_rate', 30)
    
    def render(self):
        """Main render pipeline."""
        self.logger.info("=== Timeline Rendering Started ===")
        start_time = time.time()

        try:
            # Validate manifest
            self.validate_manifest()

            # Check if there's any content to render
            layer0_elements = self.get_elements_by_layer(0)
            layer1_elements = self.get_elements_by_layer(1)

            if not layer0_elements and not layer1_elements:
                error_msg = (
                    "❌ No content to render!\n"
                    "Please add at least one of the following:\n"
                    "  - Shaders/transitions on Layer 1 (bottom layer)\n"
                    "  - Green screen videos on Layer 0 (top layer)"
                )
                self.logger.error(error_msg)
                raise ValueError("No content to render. Timeline is empty.")

            # Log what will be rendered
            if layer1_elements:
                self.logger.info(f"✓ Layer 1 (Shaders): {len(layer1_elements)} elements")
            else:
                self.logger.info("⚠ Layer 1 (Shaders): Empty - will create black background")

            if layer0_elements:
                self.logger.info(f"✓ Layer 0 (Green Screen): {len(layer0_elements)} elements")
            else:
                self.logger.info("ℹ Layer 0 (Green Screen): Empty - Layer 1 will be used directly")

            # Get render parameters
            duration = self.manifest['timeline']['duration']
            width, height = self.get_resolution()
            frame_rate = self.get_frame_rate()

            self.logger.info(f"Duration: {duration}s")
            self.logger.info(f"Resolution: {width}x{height}")
            self.logger.info(f"Frame Rate: {frame_rate} fps")
            
            # Render Layer 1 (Shaders & Transitions) - Bottom visual layer
            self.logger.info("\n" + "="*80)
            self.logger.info("--- Rendering Layer 1: Shaders & Transitions ---")
            self.logger.info("="*80)
            self.logger.info(f"PROGRESS: 0.0% | STAGE: Starting Layer 1 | ITEM: Shaders & Transitions | TIME: 0.0s/{duration:.1f}s")
            layer1_start = time.time()
            layer1_video = self.render_shader_layer()
            layer1_elapsed = time.time() - layer1_start
            self.logger.info(f"✓ Layer 1 rendered in {layer1_elapsed:.1f}s")
            self.log_file_info(layer1_video, "Layer 1 (Shaders)")

            # Render Layer 0 (Green Screen Videos) - Top visual layer
            self.logger.info("\n" + "="*80)
            self.logger.info("--- Rendering Layer 0: Green Screen Videos ---")
            self.logger.info("="*80)
            self.logger.info(f"PROGRESS: 60.0% | STAGE: Starting Layer 0 | ITEM: Green Screen Videos | TIME: 0.0s/{duration:.1f}s")
            layer0_start = time.time()
            layer0_video = self.render_greenscreen_layer()
            layer0_elapsed = time.time() - layer0_start
            if layer0_video:
                self.logger.info(f"✓ Layer 0 rendered in {layer0_elapsed:.1f}s")
                self.log_file_info(layer0_video, "Layer 0 (Green Screen)")
            else:
                self.logger.info(f"✓ Layer 0 skipped (no videos) in {layer0_elapsed:.1f}s")

            # Composite layers (shader layer on bottom, green screen on top)
            self.logger.info("\n" + "="*80)
            self.logger.info("--- Compositing Layers ---")
            self.logger.info("="*80)
            self.logger.info(f"PROGRESS: 75.0% | STAGE: Compositing layers | ITEM: Applying chroma key | TIME: 0.0s/{duration:.1f}s")
            composite_start = time.time()
            composite_video = self.composite_layers(layer1_video, layer0_video)
            composite_elapsed = time.time() - composite_start
            self.logger.info(f"✓ Composite created in {composite_elapsed:.1f}s")
            self.log_file_info(composite_video, "Composite")

            # Add audio
            self.logger.info("\n" + "="*80)
            self.logger.info("--- Adding Audio Track ---")
            self.logger.info("="*80)
            self.logger.info(f"PROGRESS: 85.0% | STAGE: Adding audio | ITEM: Muxing with FFmpeg | TIME: 0.0s/{duration:.1f}s")
            audio_start = time.time()
            final_video = self.add_audio(composite_video)
            audio_elapsed = time.time() - audio_start
            self.logger.info(f"✓ Audio added in {audio_elapsed:.1f}s")
            self.log_file_info(final_video, "Final Video")

            elapsed = time.time() - start_time
            self.logger.info("\n" + "="*80)
            self.logger.info(f"=== Rendering Completed in {elapsed:.1f} seconds ===")
            self.logger.info("="*80)
            self.logger.info(f"Output: {final_video}")
            
            return final_video
            
        except Exception as e:
            self.logger.error(f"Rendering failed: {e}")
            import traceback
            traceback.print_exc()
            return None
        
        finally:
            # Cleanup temporary files after render
            self.logger.info(f"\n=== Cleaning up temporary files from: {self.temp_dir} ===")
            self.cleanup()  # Re-enabled - removes temp files after successful render
    
    def log_file_info(self, file_path, description):
        """Log detailed information about a generated file."""
        if file_path and Path(file_path).exists():
            size_bytes = Path(file_path).stat().st_size
            size_mb = size_bytes / (1024 * 1024)
            self.logger.info(f"📁 {description}: {file_path}")
            self.logger.info(f"📊 File size: {size_mb:.2f} MB ({size_bytes:,} bytes)")

            # Try to get pixel format using ffprobe
            try:
                probe_cmd = [
                    'ffprobe', '-v', 'quiet', '-select_streams', 'v:0',
                    '-show_entries', 'stream=pix_fmt', '-of', 'default=noprint_wrappers=1:nokey=1',
                    str(file_path)
                ]
                result = subprocess.run(probe_cmd, capture_output=True, text=True, timeout=5)
                if result.returncode == 0 and result.stdout.strip():
                    pix_fmt = result.stdout.strip()
                    self.logger.info(f"🎨 Pixel format: {pix_fmt}")
                    if 'yuva' in pix_fmt or 'rgba' in pix_fmt:
                        self.logger.info("   ✓ Has alpha channel (transparency)")
                    else:
                        self.logger.info("   ℹ No alpha channel")
            except Exception as e:
                self.logger.debug(f"Could not probe pixel format: {e}")
        else:
            self.logger.warning(f"⚠️ {description}: File not found or None")

    def convert_web_interface_timeline(self, elements):
        """Convert web interface timeline (sequential elements) to overlapping format for transitions."""
        converted_elements = []
        shader_elements = [el for el in elements if el['type'] == 'shader']
        transition_elements = [el for el in elements if el['type'] == 'transition']

        # Store transition mapping for later use
        self.transition_mapping = {}

        for i, shader in enumerate(shader_elements):
            shader_element = shader.copy()

            # Check if there's a transition after this shader
            transition_after = None
            for trans in transition_elements:
                if trans['startTime'] == shader['endTime']:
                    transition_after = trans
                    break

            # Check if there's a transition before this shader
            transition_before = None
            for trans in transition_elements:
                if trans['endTime'] == shader['startTime']:
                    transition_before = trans
                    break

            # Extend shader times to create overlaps during transitions
            if transition_after:
                # Extend this shader to end when transition ends
                shader_element['endTime'] = transition_after['endTime']
                # Store which transition to use for this overlap period
                overlap_key = f"{shader['id']}->{shader_elements[i+1]['id'] if i+1 < len(shader_elements) else 'end'}"
                self.transition_mapping[overlap_key] = transition_after['name']
                self.logger.debug(f"Extended shader '{shader['name']}' end from {shader['endTime']}s to {transition_after['endTime']}s using transition '{transition_after['name']}'")

            if transition_before:
                # Start this shader when transition starts
                shader_element['startTime'] = transition_before['startTime']
                self.logger.debug(f"Extended shader '{shader['name']}' start from {shader['startTime']}s to {transition_before['startTime']}s")

            converted_elements.append(shader_element)

        return converted_elements

    def render_shader_layer(self):
        """Render all shaders and transitions on Layer 1 (bottom visual layer)."""
        layer1_elements = self.get_elements_by_layer(1)

        if not layer1_elements:
            self.logger.warning("No elements on Layer 1, creating black video")
            return self.create_black_video()

        self.logger.info(f"Found {len(layer1_elements)} elements on Layer 1")

        # Convert web interface timeline to overlapping format for transitions
        original_count = len(layer1_elements)
        layer1_elements = self.convert_web_interface_timeline(layer1_elements)
        self.logger.info(f"Converted from {original_count} elements to {len(layer1_elements)} overlapping shader elements")

        # Initialize OpenGL context
        self.ctx = moderngl.create_standalone_context()

        # Load audio for audio-reactive effects
        audio_path = Path(self.manifest['audio']['path'])
        audio_data = self.load_audio(audio_path)

        # Precompile all shaders and transitions
        compiled_shaders = self.precompile_shaders(layer1_elements)

        # Render the layer
        output_path = self.temp_dir / "layer1_raw.mp4"
        self.render_layer1_timeline(layer1_elements, compiled_shaders, audio_data, output_path)

        return output_path
    
    def render_greenscreen_layer(self):
        """Render green screen videos on Layer 0 (top visual layer).

        Returns path to raw RGB file (not MP4) - chroma key will be applied during compositing.
        """
        layer0_elements = self.get_elements_by_layer(0)

        if not layer0_elements:
            self.logger.info("No elements on Layer 0, skipping green screen processing")
            return None

        self.logger.info(f"Found {len(layer0_elements)} video elements on Layer 0")

        # Render to raw RGB file (chroma key applied later during compositing)
        raw_rgb_path = self.render_video_layer(layer0_elements, None)

        return raw_rgb_path
    
    def composite_layers(self, shader_layer_path, greenscreen_layer_path):
        """Composite all layers together using FFmpeg with chroma key applied during compositing.

        This method combines chroma key and compositing into a single FFmpeg command to avoid
        alpha channel loss that occurs when creating intermediate files.

        Args:
            shader_layer_path: Path to Layer 1 (shaders/transitions - bottom layer)
            greenscreen_layer_path: Path to Layer 0 raw RGB file or None
        """
        if greenscreen_layer_path is None:
            self.logger.info("No Layer 0 (green screen) content, using Layer 1 (shaders) only")
            return shader_layer_path

        output_path = self.temp_dir / "composite.mp4"

        # Get resolution and frame rate from manifest
        width, height = self.get_resolution()
        frame_rate = self.get_frame_rate()

        self.logger.info("\n🎬 COMPOSITING LAYERS WITH CHROMA KEY")
        self.logger.info(f"Background (Layer 1 - Shaders): {shader_layer_path}")
        self.logger.info(f"Overlay (Layer 0 - Green Screen Raw): {greenscreen_layer_path}")
        self.logger.info(f"Output: {output_path}")
        self.logger.info(f"Resolution: {width}x{height} @ {frame_rate}fps")
        self.logger.info("Chroma key color: 0x00d600 (rgb(0, 214, 0))")
        self.logger.info("Similarity: 0.38, Blend: 0.0")
        self.logger.info("Alpha processing: Extract → Blur (2:1) → Merge (reduces jaggies)")

        # Single-pass FFmpeg command that:
        # 1. Takes layer1_raw.mp4 (shaders) as input [0]
        # 2. Takes layer0_raw.rgb (raw green screen) as input [1]
        # 3. Applies chroma key to remove green from [1]
        # 4. Extracts alpha, blurs it to soften edges, reapplies it
        # 5. Overlays result on [0]
        cmd = [
            'ffmpeg',
            '-y',
            '-i', str(shader_layer_path),  # Input 0: Layer 1 (shaders)
            '-f', 'rawvideo',
            '-pixel_format', 'rgb24',
            '-video_size', f'{width}x{height}',
            '-framerate', str(frame_rate),
            '-i', str(greenscreen_layer_path),  # Input 1: Layer 0 raw RGB
            '-filter_complex',
            '[1:v]format=rgba,colorkey=0x00d600:0.38:0.0,split[fga][fgc];'
            '[fga]alphaextract,boxblur=2:1[matte];'
            '[fgc][matte]alphamerge[fg];'
            '[0:v][fg]overlay=0:0:format=auto',
            '-c:v', 'libx264',
            '-crf', '18',
            '-preset', 'medium',
            '-pix_fmt', 'yuv420p',
            str(output_path)
        ]

        # Log the full command for manual testing
        cmd_str = ' '.join(str(c) for c in cmd)
        self.logger.info("\n📋 FFmpeg Command (copy/paste to test manually):")
        self.logger.info(cmd_str)

        self.logger.info("\n⏳ Running FFmpeg composite with chroma key...")
        result = subprocess.run(cmd, capture_output=True, text=True)

        if result.returncode != 0:
            self.logger.error(f"❌ FFmpeg composite failed!")
            self.logger.error(f"Return code: {result.returncode}")
            self.logger.error(f"stderr: {result.stderr}")
            raise subprocess.CalledProcessError(result.returncode, cmd, result.stderr)

        # Log FFmpeg output for debugging
        if result.stderr:
            self.logger.debug("FFmpeg stderr output:")
            for line in result.stderr.split('\n'):
                if line.strip() and ('frame=' in line or 'error' in line.lower() or 'warning' in line.lower()):
                    self.logger.debug(f"  {line}")

        self.logger.info("✓ Layers composited with chroma key applied")

        return output_path
    
    def add_audio(self, video_path):
        """Add audio track to final video."""
        audio_path = Path(self.manifest['audio']['path'])

        # Generate output filename
        project_name = self.manifest.get('project_name', 'timeline_render')
        output_dir = Path('Output_Video')
        output_dir.mkdir(parents=True, exist_ok=True)
        output_path = output_dir / f"{project_name}.mp4"

        self.logger.info("\n🎬 ADDING AUDIO TRACK")
        self.logger.info(f"Video input: {video_path}")
        self.logger.info(f"Audio input: {audio_path}")
        self.logger.info(f"Output: {output_path}")
        self.logger.info("Video codec: copy (no re-encoding)")
        self.logger.info("Audio codec: aac @ 192k")

        cmd = [
            'ffmpeg',
            '-y',
            '-i', str(video_path),
            '-i', str(audio_path),
            '-c:v', 'copy',
            '-c:a', 'aac',
            '-b:a', '192k',
            '-shortest',
            str(output_path)
        ]

        # Log the full command for manual testing
        cmd_str = ' '.join(str(c) for c in cmd)
        self.logger.info("\n📋 FFmpeg Command (copy/paste to test manually):")
        self.logger.info(cmd_str)

        self.logger.info("\n⏳ Running FFmpeg audio merge...")
        result = subprocess.run(cmd, capture_output=True, text=True)

        if result.returncode != 0:
            self.logger.error(f"❌ FFmpeg audio merge failed!")
            self.logger.error(f"Return code: {result.returncode}")
            self.logger.error(f"stderr: {result.stderr}")
            raise subprocess.CalledProcessError(result.returncode, cmd, result.stderr)

        # Log FFmpeg output for debugging
        if result.stderr:
            self.logger.debug("FFmpeg stderr output:")
            for line in result.stderr.split('\n'):
                if line.strip() and ('frame=' in line or 'error' in line.lower() or 'warning' in line.lower()):
                    self.logger.debug(f"  {line}")

        self.logger.info(f"✓ Audio added")

        return output_path
    
    def cleanup(self):
        """Clean up temporary files."""
        if self.temp_dir.exists():
            self.logger.info(f"Cleaning up temporary directory: {self.temp_dir}")
            shutil.rmtree(self.temp_dir)
    
    def load_audio(self, audio_path):
        """Analyze audio file for reactivity data with high-resolution 1024-point FFT (matching render_shader.py)."""
        self.logger.info(f"Loading audio: {audio_path.name}")

        try:
            # Load audio
            duration = self.manifest['timeline']['duration']
            y, sr = librosa.load(str(audio_path), sr=None, duration=duration)

            # Calculate frame parameters
            frame_rate = 30  # Fixed frame rate for timeline rendering
            total_frames = int(duration * frame_rate)
            hop_length = len(y) // total_frames

            self.logger.info(f"Audio: {duration:.2f}s, {sr}Hz, {total_frames} frames")
            self.logger.info(f"FFT: 1024-point, {sr//2}Hz Nyquist, {sr/1024:.1f}Hz per bin")

            # High-resolution 1024-point FFT (Shadertoy-compatible)
            stft_data = librosa.stft(y, hop_length=hop_length, n_fft=1024)

            # Get magnitude spectrum (512 usable bins from 1024-point FFT)
            magnitude_spectrum = np.abs(stft_data[:512, :])  # Only first 512 bins (magnitude only)

            # Apply smoothing similar to Shadertoy (0.8 smoothing factor)
            smoothed_spectrum = np.zeros_like(magnitude_spectrum)
            smoothing_factor = 0.8

            for frame_idx in range(magnitude_spectrum.shape[1]):
                if frame_idx == 0:
                    smoothed_spectrum[:, frame_idx] = magnitude_spectrum[:, frame_idx]
                else:
                    smoothed_spectrum[:, frame_idx] = (
                        smoothing_factor * smoothed_spectrum[:, frame_idx - 1] +
                        (1.0 - smoothing_factor) * magnitude_spectrum[:, frame_idx]
                    )

            # Normalize to [0.0, 1.0] range
            if smoothed_spectrum.max() > 0:
                smoothed_spectrum = smoothed_spectrum / smoothed_spectrum.max()

            # Extract legacy bass/treble for backward compatibility
            bass_power = np.mean(smoothed_spectrum[:32, :], axis=0)  # 0-32 bins (low frequencies)
            treble_power = np.mean(smoothed_spectrum[256:, :], axis=0)  # 256+ bins (high frequencies)

            # Ensure we have the right number of frames
            if smoothed_spectrum.shape[1] != total_frames:
                # Interpolate full spectrum
                new_spectrum = np.zeros((512, total_frames))
                for bin_idx in range(512):
                    new_spectrum[bin_idx, :] = np.interp(
                        np.linspace(0, smoothed_spectrum.shape[1]-1, total_frames),
                        np.arange(smoothed_spectrum.shape[1]),
                        smoothed_spectrum[bin_idx, :]
                    )
                smoothed_spectrum = new_spectrum

                # Interpolate legacy values
                bass_power = np.interp(np.linspace(0, len(bass_power)-1, total_frames),
                                     np.arange(len(bass_power)), bass_power)
                treble_power = np.interp(np.linspace(0, len(treble_power)-1, total_frames),
                                       np.arange(len(treble_power)), treble_power)

            # Extract raw waveform samples for oscilloscope
            waveform_samples = []
            oscilloscope_duration = 1.0 / 30.0  # 1/30th second window
            samples_per_window = max(int(sr * oscilloscope_duration), 256)

            for frame_idx in range(total_frames):
                frame_time = frame_idx / frame_rate
                center_sample = int(frame_time * sr)
                start_sample = max(0, center_sample - samples_per_window // 2)
                end_sample = min(len(y), start_sample + samples_per_window)

                if end_sample - start_sample < samples_per_window:
                    start_sample = max(0, end_sample - samples_per_window)

                frame_audio = y[start_sample:end_sample]

                # Downsample to exactly 256 samples for texture width
                if len(frame_audio) >= 256:
                    indices = np.linspace(0, len(frame_audio) - 1, 256)
                    frame_waveform = np.interp(indices, np.arange(len(frame_audio)), frame_audio)
                else:
                    frame_waveform = np.pad(frame_audio, (0, 256 - len(frame_audio)), 'constant')

                # Normalize to [0, 1] range
                frame_waveform = (frame_waveform + 1.0) * 0.5
                waveform_samples.append(frame_waveform)

            self.logger.info(f"✓ Audio loaded: {len(y)/sr:.1f}s, {sr}Hz")

            return {
                'bass': bass_power,  # Legacy compatibility
                'treble': treble_power,  # Legacy compatibility
                'fft_spectrum': smoothed_spectrum,  # New: Full 512-bin spectrum
                'waveform': waveform_samples,
                'total_frames': total_frames,
                'frame_rate': frame_rate,
                'sample_rate': sr,
                'nyquist_freq': sr // 2,
                'freq_per_bin': sr / 1024.0
            }

        except Exception as e:
            self.logger.error(f"Failed to load audio: {e}")
            return None

    def load_metadata(self):
        """Load shader metadata from Shaders/metadata.json."""
        metadata_path = Path("Shaders") / "metadata.json"
        if not metadata_path.exists():
            self.logger.warning("Shaders/metadata.json not found")
            return {}

        try:
            with open(metadata_path, 'r') as f:
                metadata_list = json.load(f)

            # Convert list to dict keyed by shader name
            metadata_dict = {}
            for entry in metadata_list:
                metadata_dict[entry['name']] = entry

            return metadata_dict
        except Exception as e:
            self.logger.error(f"Failed to load metadata: {e}")
            return {}

    def load_cubemap_from_files(self, basename, filter_mode='linear', mipmap=False):
        """Load 6 images as a cubemap texture from the Cubemaps/ folder."""
        try:
            from PIL import Image
            import numpy as np

            cubemaps_dir = Path("Cubemaps")

            # Define face suffixes in ModernGL order: +X, -X, +Y, -Y, +Z, -Z
            face_suffixes = ['px', 'nx', 'py', 'ny', 'pz', 'nz']
            face_names = ['positive X (right)', 'negative X (left)',
                         'positive Y (top)', 'negative Y (bottom)',
                         'positive Z (front)', 'negative Z (back)']

            # Load all 6 faces
            faces = []
            face_size = None

            for suffix, name in zip(face_suffixes, face_names):
                # Try common image extensions
                face_path = None
                for ext in ['.png', '.jpg', '.jpeg', '.bmp', '.tga']:
                    potential_path = cubemaps_dir / f"{basename}_{suffix}{ext}"
                    if potential_path.exists():
                        face_path = potential_path
                        break

                if not face_path:
                    self.logger.error(f"Cubemap face not found: {basename}_{suffix}.* ({name})")
                    return None

                # Load image
                img = Image.open(face_path)
                img = img.convert('RGB')

                # Validate size
                if img.size[0] != img.size[1]:
                    self.logger.error(f"Cubemap face must be square: {face_path.name} is {img.size[0]}x{img.size[1]}")
                    return None

                if face_size is None:
                    face_size = img.size[0]
                elif img.size[0] != face_size:
                    self.logger.error(f"All cubemap faces must be same size: {face_path.name} is {img.size[0]}x{img.size[0]}, expected {face_size}x{face_size}")
                    return None

                # Convert to numpy array
                img_data = np.array(img, dtype=np.uint8)

                # Flip vertically for OpenGL coordinate system
                img_data = np.flipud(img_data)

                faces.append(img_data)
                self.logger.info(f"    Loaded cubemap face: {face_path.name} ({name})")

            # Concatenate all 6 faces into single data array
            combined_data = b''.join([face.tobytes() for face in faces])

            # Create cubemap texture
            cubemap = self.ctx.texture_cube(
                size=(face_size, face_size),
                components=3,
                data=combined_data,
                dtype='f1'
            )

            # Set filtering
            if filter_mode == 'linear':
                cubemap.filter = (moderngl.LINEAR, moderngl.LINEAR)
            else:
                cubemap.filter = (moderngl.NEAREST, moderngl.NEAREST)

            # Generate mipmaps if requested
            if mipmap:
                cubemap.build_mipmaps()

            self.logger.info(f"    ✓ Loaded cubemap: {basename} ({face_size}x{face_size}, 6 faces)")
            return cubemap

        except Exception as e:
            self.logger.error(f"Failed to load cubemap {basename}: {e}")
            import traceback
            self.logger.error(traceback.format_exc())
            return None

    def load_texture_from_file(self, texture_path, filter_mode='linear', wrap_mode='repeat', mipmap=False):
        """Load an image file as a ModernGL texture."""
        try:
            from PIL import Image
            import numpy as np

            # Load image
            img = Image.open(texture_path)
            img = img.convert('RGB')  # Ensure RGB format
            img_data = np.array(img, dtype=np.uint8)

            # Flip vertically (OpenGL expects bottom-left origin)
            img_data = np.flipud(img_data)

            # Create texture
            texture = self.ctx.texture(img.size, 3, img_data.tobytes())

            # Set filtering
            if filter_mode == 'linear':
                texture.filter = (moderngl.LINEAR, moderngl.LINEAR)
            else:
                texture.filter = (moderngl.NEAREST, moderngl.NEAREST)

            # Set wrapping
            if wrap_mode == 'repeat':
                texture.repeat_x = True
                texture.repeat_y = True
            elif wrap_mode == 'clamp':
                texture.repeat_x = False
                texture.repeat_y = False

            # Generate mipmaps if requested
            if mipmap:
                texture.build_mipmaps()

            self.logger.info(f"    ✓ Loaded texture: {texture_path.name} ({img.size[0]}x{img.size[1]})")
            return texture

        except Exception as e:
            self.logger.error(f"    Failed to load texture {texture_path}: {e}")
            return None

    def detect_and_load_textures(self, shader_path, metadata=None):
        """Detect and load texture files for a shader from metadata."""
        textures = {}

        if not metadata or not metadata.get('texture'):
            return textures

        texture_config = metadata['texture']
        textures_dir = Path("Textures")

        # Phase 1: Simple string (single texture)
        if isinstance(texture_config, str):
            texture_file = textures_dir / texture_config
            if texture_file.exists():
                texture = self.load_texture_from_file(texture_file)
                if texture:
                    textures['iChannel1'] = texture
                    self.logger.info(f"    Loaded texture to iChannel1: {texture_config}")
            else:
                self.logger.warning(f"    Texture file not found: {texture_file}")

        # Phase 2/3: Dict mapping channels to filenames or config
        elif isinstance(texture_config, dict):
            for channel, config in texture_config.items():
                # Simple filename string
                if isinstance(config, str):
                    texture_file = textures_dir / config
                    if texture_file.exists():
                        texture = self.load_texture_from_file(texture_file)
                        if texture:
                            textures[channel] = texture
                            self.logger.info(f"    Loaded texture to {channel}: {config}")
                    else:
                        self.logger.warning(f"    Texture file not found: {texture_file}")

                # Phase 3: Advanced config dict (includes cubemap support)
                elif isinstance(config, dict):
                    # Check if this is a cubemap
                    if config.get('type') == 'cubemap':
                        # Load cubemap using basename
                        basename = config.get('basename')
                        if basename:
                            cubemap = self.load_cubemap_from_files(
                                basename,
                                filter_mode=config.get('filter', 'linear'),
                                mipmap=config.get('mipmap', False)
                            )
                            if cubemap:
                                textures[channel] = cubemap
                                self.logger.info(f"    Loaded cubemap to {channel}: {basename}")
                        else:
                            self.logger.error(f"    Cubemap config missing 'basename' for {channel}")

                    # Regular 2D texture with advanced config
                    elif 'file' in config:
                        texture_file = textures_dir / config['file']
                        if texture_file.exists():
                            texture = self.load_texture_from_file(
                                texture_file,
                                filter_mode=config.get('filter', 'linear'),
                                wrap_mode=config.get('wrap', 'repeat'),
                                mipmap=config.get('mipmap', False)
                            )
                            if texture:
                                textures[channel] = texture
                                self.logger.info(f"    Loaded texture to {channel}: {config['file']}")
                        else:
                            self.logger.warning(f"    Texture file not found: {texture_file}")

        return textures

    def precompile_shaders(self, elements):
        """Precompile all shaders and transitions for the layer, including buffer support."""
        self.logger.info("Precompiling shaders and transitions...")

        # Load metadata once for all shaders
        metadata_dict = self.load_metadata()

        compiled = {}
        shader_elements = [el for el in elements if el['type'] in ['shader', 'transition']]

        for element in shader_elements:
            shader_path = Path(element['path'])
            shader_name = element['name']

            self.logger.info(f"  Compiling {shader_name}...")

            try:
                # Compile main shader
                program = self.load_shader_from_file(shader_path)
                if not program:
                    self.logger.warning(f"  ✗ Failed to compile {shader_name}")
                    continue

                # Load textures for this shader
                textures = {}
                if element['type'] == 'shader':  # Only main shaders have textures
                    metadata = metadata_dict.get(shader_name)
                    if metadata:
                        textures = self.detect_and_load_textures(shader_path, metadata)

                # Detect and compile buffer shaders (only for shader elements, not transitions)
                buffers = {}
                if element['type'] == 'shader':
                    buffer_ids = self.detect_shader_buffers(shader_path)

                    if buffer_ids:
                        self.logger.info(f"    Detected buffers: {', '.join(buffer_ids)}")
                        for buffer_id in buffer_ids:
                            buffer_file = shader_path.parent / f"{shader_path.stem}.buffer.{buffer_id}.glsl"
                            self.logger.info(f"    Compiling buffer {buffer_id}...")
                            buffer_program = self.load_shader_from_file(buffer_file)

                            if buffer_program is not None:
                                buffers[buffer_id] = {
                                    'program': buffer_program,
                                    'path': buffer_file,
                                    'texture_current': None,
                                    'texture_previous': None,
                                    'fbo_current': None,
                                    'fbo_previous': None
                                }
                                self.logger.info(f"    ✓ Buffer {buffer_id} compiled successfully")
                            else:
                                self.logger.warning(f"    ✗ Failed to compile buffer {buffer_id}")

                compiled[element['id']] = {
                    'program': program,
                    'element': element,
                    'path': shader_path,
                    'buffers': buffers,
                    'textures': textures
                }
                self.logger.info(f"  ✓ {shader_name}")

            except Exception as e:
                self.logger.error(f"  ✗ Error compiling {shader_name}: {e}")

        self.logger.info(f"✓ Compiled {len(compiled)}/{len(shader_elements)} shaders")
        return compiled

    def precompile_transitions(self):
        """Precompile all available transition shaders."""
        self.logger.info("Precompiling transition shaders...")

        transitions_dir = Path("Transitions")
        if not transitions_dir.exists():
            self.logger.warning("Transitions directory not found")
            return {}

        # Load transition configuration data once (matching render_shader.py)
        transition_config_data = self.load_transition_config()

        compiled_transitions = {}
        transition_files = list(transitions_dir.glob("*.glsl"))

        for transition_file in transition_files:
            transition_name = transition_file.stem
            self.logger.info(f"  Compiling transition: {transition_name}")

            try:
                transition_data = self.load_transition_shader(transition_file, transition_config_data)
                if transition_data:
                    compiled_transitions[transition_name] = transition_data
                    self.logger.info(f"  ✓ {transition_name}")
                else:
                    self.logger.warning(f"  ✗ Failed to compile {transition_name}")
            except Exception as e:
                self.logger.error(f"  ✗ Error compiling {transition_name}: {e}")

        self.logger.info(f"✓ Compiled {len(compiled_transitions)}/{len(transition_files)} transitions")
        return compiled_transitions

    def precompile_used_transitions(self, elements):
        """Precompile only the transition shaders that are actually used in the timeline.

        This is more efficient than precompiling all transitions, especially when
        the timeline uses only a few transitions or none at all.

        Note: After timeline conversion, transition elements are removed and their names
        are stored in self.transition_mapping. We need to check that mapping instead of
        looking for transition elements.
        """
        # Find all unique transition names from the transition mapping
        # (created during timeline conversion)
        used_transition_names = set()

        if hasattr(self, 'transition_mapping') and self.transition_mapping:
            for overlap_key, transition_name in self.transition_mapping.items():
                # Remove .glsl extension if present
                clean_name = transition_name.replace('.glsl', '')
                if clean_name:
                    used_transition_names.add(clean_name)
                    self.logger.debug(f"Found transition in mapping: {clean_name} (key: {overlap_key})")

        # If no transitions are used, return empty dict
        if not used_transition_names:
            self.logger.info("No transitions used in timeline, skipping transition precompilation")
            return {}

        self.logger.info(f"Precompiling {len(used_transition_names)} transition(s) used in timeline: {', '.join(used_transition_names)}")

        transitions_dir = Path("Transitions")
        if not transitions_dir.exists():
            self.logger.warning("Transitions directory not found")
            return {}

        # Load transition configuration data once
        transition_config_data = self.load_transition_config()

        compiled_transitions = {}

        # Only compile the transitions that are actually used
        for transition_name in used_transition_names:
            transition_file = transitions_dir / f"{transition_name}.glsl"

            if not transition_file.exists():
                self.logger.warning(f"  ✗ Transition file not found: {transition_file}")
                continue

            self.logger.info(f"  Compiling transition: {transition_name}")

            try:
                transition_data = self.load_transition_shader(transition_file, transition_config_data)
                if transition_data:
                    compiled_transitions[transition_name] = transition_data
                    self.logger.info(f"  ✓ {transition_name}")
                else:
                    self.logger.warning(f"  ✗ Failed to compile {transition_name}")
            except Exception as e:
                self.logger.error(f"  ✗ Error compiling {transition_name}: {e}")

        self.logger.info(f"✓ Compiled {len(compiled_transitions)}/{len(used_transition_names)} used transitions")
        return compiled_transitions

    def load_transition_config(self):
        """Load transition shader configurations from Transitions_Metadata.json."""
        config_file = Path("Transitions/Transitions_Metadata.json")

        if not config_file.exists():
            self.logger.warning(f"Transition metadata file not found: {config_file}")
            return {}

        try:
            with open(config_file, 'r') as f:
                import json
                return json.load(f)
        except Exception as e:
            self.logger.error(f"Failed to load transition config: {e}")
            return {}

    def load_transition_shader(self, transition_file, config_data):
        """Load and compile a transition shader with its configuration (matching render_shader.py)."""
        try:
            with open(transition_file, 'r') as f:
                fragment_source = f.read()

            # Basic vertex shader for full-screen quad
            vertex_source = """
            #version 330 core
            in vec2 in_vert;
            void main() {
                gl_Position = vec4(in_vert, 0.0, 1.0);
            }
            """

            # Create shader program
            program = self.ctx.program(
                vertex_shader=vertex_source,
                fragment_shader=fragment_source
            )

            # Get shader-specific configuration
            shader_name = transition_file.name
            shader_config = config_data.get(shader_name, {})

            return {
                'program': program,
                'config': shader_config,
                'name': shader_name
            }

        except Exception as e:
            self.logger.error(f"Failed to load transition shader {transition_file.name}: {e}")
            return None

    def create_audio_texture(self, bass_value, treble_value, waveform_data=None, fft_spectrum=None):
        """Create/Update audio texture for shaders (Shadertoy-compatible).

        PATCHED on 2025-10-04:
        - Rows: 0=spectrum, 1=spectrum duplicate, 2..4=waveform guard band, 5..255=waveform copy
        - LINEAR filtering, CLAMP_TO_EDGE wrapping
        - Creates new texture each frame (timeline render doesn't use persistent texture)
        - Uint8 R8 normalized upload (0..255)

        This prevents linear filtering near the spectrum→waveform seam from blending across rows,
        which caused the 'leftmost dip/ghost line' artifacts you saw.

        For more details, see: "README STFT COMPATABILITY.md"
        """
        import numpy as _np
        import moderngl as _mgl  # only to access enums; already imported elsewhere

        # --- Pack a 512x256 single-channel image ---
        H, W = 256, 512
        audio_img = _np.zeros((H, W), dtype=_np.float32)

        # Spectrum rows (0 and 1)
        if fft_spectrum is not None:
            spec = _np.asarray(fft_spectrum, dtype=_np.float32)
            # Ensure length 512 (interpolate if needed)
            if spec.shape[0] != W:
                x = _np.linspace(0.0, 1.0, spec.shape[0], endpoint=True)
                xi = _np.linspace(0.0, 1.0, W, endpoint=True)
                spec = _np.interp(xi, x, spec).astype(_np.float32)
            spec = _np.clip(spec, 0.0, 1.0)
            audio_img[0, :] = spec
            audio_img[1, :] = spec
        else:
            # Legacy fallback: place bass & treble bands in row 0
            row = _np.zeros((W,), dtype=_np.float32)
            row[:64] = float(bass_value)
            row[256:320] = float(treble_value)
            audio_img[0, :] = row
            audio_img[1, :] = row

        # Waveform rows (2..255), with seam guard band in rows 2..4
        if waveform_data is not None:
            wave = _np.asarray(waveform_data, dtype=_np.float32)
            # Normalize/clamp (expecting 0..1 already)
            wave = _np.clip(wave, 0.0, 1.0)
            # Interp to 512 if 256
            if wave.shape[0] != W:
                x = _np.linspace(0.0, 1.0, wave.shape[0], endpoint=True)
                xi = _np.linspace(0.0, 1.0, W, endpoint=True)
                wave = _np.interp(xi, x, wave).astype(_np.float32)
            # Guard band near seam
            audio_img[2:5, :] = wave[None, :]
            # Repeat waveform for remaining rows
            audio_img[5:, :] = wave[None, :]

        # Convert to R8 bytes
        audio_bytes = (audio_img * 255.0 + 0.5).clip(0, 255).astype(_np.uint8).tobytes()

        # Create new texture each frame (timeline render doesn't use persistent texture)
        texture = self.ctx.texture((W, H), 1, audio_bytes)

        # Enforce Shadertoy-like sampling params
        texture.filter = (_mgl.LINEAR, _mgl.LINEAR)
        texture.repeat_x = False
        texture.repeat_y = False

        return texture

    def select_transition_shader(self, compiled_transitions, specific_transition_name=None, from_shader=None, to_shader=None):
        """Select a transition shader - use specific name if provided, otherwise first available.

        Tracks transition state and logs only when a new transition starts.
        """
        if not compiled_transitions:
            self.logger.warning("No compiled transitions available")
            return None

        selected_shader = None
        selected_name = None

        if specific_transition_name:
            # Try to find the EXACT transition the user selected
            for name, shader in compiled_transitions.items():
                if name == specific_transition_name:
                    selected_shader = shader
                    selected_name = specific_transition_name
                    break

            # Try without .glsl extension if not found
            if not selected_shader:
                base_name = specific_transition_name.replace('.glsl', '')
                for name, shader in compiled_transitions.items():
                    if name.replace('.glsl', '') == base_name:
                        selected_shader = shader
                        selected_name = name
                        break

            if not selected_shader:
                self.logger.error(f"USER-SELECTED TRANSITION '{specific_transition_name}' NOT FOUND! Available: {list(compiled_transitions.keys())}")
                # Fallback to first available
                selected_name = list(compiled_transitions.keys())[0]
                selected_shader = compiled_transitions[selected_name]
        else:
            # Fallback to first available transition
            selected_name = list(compiled_transitions.keys())[0]
            selected_shader = compiled_transitions[selected_name]

        # Check if this is a NEW transition (log only once at start)
        transition_pair = (from_shader, to_shader) if from_shader and to_shader else None
        if selected_name != self.current_transition_name or transition_pair != self.current_transition_pair:
            # New transition starting
            if from_shader and to_shader:
                self.logger.info(f"▶️ Starting transition: {selected_name} ({from_shader} → {to_shader})")
            else:
                self.logger.info(f"▶️ Starting transition: {selected_name}")

            self.current_transition_name = selected_name
            self.current_transition_pair = transition_pair

        return selected_shader

    def detect_shader_buffers(self, shader_path, metadata=None):
        """
        Detect buffer files for a shader using hybrid approach.

        Args:
            shader_path: Path to main shader file
            metadata: Optional metadata dict for this shader

        Returns:
            List of buffer IDs ['A', 'B', ...] or empty list
        """
        # 1. Check metadata first
        if metadata and metadata.get('buffer'):
            buffer_config = metadata['buffer']
            if isinstance(buffer_config, bool) and buffer_config:
                # Phase 1: Boolean, auto-discover files
                pass
            elif isinstance(buffer_config, dict):
                # Phase 2/3: Explicit configuration
                if 'files' in buffer_config:
                    # Extract buffer IDs from filenames
                    found_buffers = []
                    for file in buffer_config['files']:
                        # Extract buffer ID from filename like "Shader.buffer.A.glsl"
                        if '.buffer.' in file:
                            buffer_id = file.split('.buffer.')[1].split('.')[0]
                            found_buffers.append(buffer_id)
                    return found_buffers

        # 2. Fallback: Auto-discover by file naming
        base_name = shader_path.stem
        found_buffers = []
        for buffer_id in ['A', 'B', 'C', 'D']:
            buffer_file = shader_path.parent / f"{base_name}.buffer.{buffer_id}.glsl"
            if buffer_file.exists():
                found_buffers.append(buffer_id)

        return found_buffers

    def load_shader_from_file(self, shader_path):
        """Load and compile a GLSL shader."""
        try:
            with open(shader_path, 'r') as f:
                fragment_source = f.read()

            # Vertex shader for full-screen quad
            vertex_source = """
            #version 330 core
            in vec2 in_vert;
            void main() {
                gl_Position = vec4(in_vert, 0.0, 1.0);
            }
            """

            # Create shader program
            program = self.ctx.program(
                vertex_shader=vertex_source,
                fragment_shader=fragment_source
            )

            return program

        except Exception as e:
            self.logger.error(f"Failed to load shader {shader_path}: {e}")
            return None

    def render_layer1_timeline(self, elements, compiled_shaders, audio_data, output_path):
        """Render Layer 1 (shaders/transitions) with precise timeline timing and transitions."""
        self.logger.info("Rendering shader timeline with transitions...")

        width, height = self.get_resolution()
        frame_rate = self.get_frame_rate()
        duration = self.manifest['timeline']['duration']
        total_frames = int(duration * frame_rate)

        # Transition configuration
        transition_duration = 1.6  # seconds
        transition_frames = int(transition_duration * frame_rate)
        overlap_duration = 0.45  # seconds - each shader overlaps by this amount
        overlap_frames = int(overlap_duration * frame_rate)

        self.logger.info(f"Total frames: {total_frames}")
        self.logger.info(f"Transition duration: {transition_duration}s ({transition_frames} frames)")
        self.logger.info(f"Overlap duration: {overlap_duration}s ({overlap_frames} frames)")

        # Create framebuffer
        fbo = self.ctx.framebuffer(
            color_attachments=[self.ctx.texture((width, height), 4)]
        )

        # Initialize buffer textures for all shaders with buffers
        resolution = (width, height)
        for shader_id, shader_data in compiled_shaders.items():
            if shader_data.get('buffers'):
                self.logger.info(f"Initializing buffers for {shader_data['element']['name']}")
                self.initialize_buffer_textures(shader_data, resolution)

        # Create vertex buffer for full-screen quad
        vertices = np.array([
            -1.0, -1.0,
             1.0, -1.0,
            -1.0,  1.0,
            -1.0,  1.0,
             1.0, -1.0,
             1.0,  1.0,
        ], dtype=np.float32)
        vbo = self.ctx.buffer(vertices.tobytes())

        # Precompile only the transitions that are actually used in the timeline
        compiled_transitions = self.precompile_used_transitions(elements)

        # Open raw video file for writing
        raw_file = open(self.temp_dir / "layer1_raw.rgb", 'wb')

        try:
            # Render each frame
            for frame_idx in range(total_frames):
                time_seconds = frame_idx / frame_rate

                # Find current and next elements for transition handling
                result = self.find_transition_state(
                    elements, time_seconds, transition_duration, overlap_duration
                )

                if len(result) == 4:
                    current_element, next_element, transition_progress, transition_name = result
                else:
                    # Legacy format for backward compatibility
                    current_element, next_element, transition_progress = result
                    transition_name = None

                if transition_progress is not None:
                    # We're in a transition - blend two shaders
                    if (current_element and current_element['id'] in compiled_shaders and
                        next_element and next_element['id'] in compiled_shaders):

                        # Select the SPECIFIC transition shader chosen by user
                        # Pass shader names for transition tracking
                        transition_shader = self.select_transition_shader(
                            compiled_transitions,
                            transition_name,
                            from_shader=current_element['name'],
                            to_shader=next_element['name']
                        )

                        # Check if transition is ending (progress >= 0.99)
                        if transition_progress >= 0.99 and self.current_transition_name:
                            self.logger.info(f"✓ Completed transition: {self.current_transition_name} (progress: {transition_progress:.3f})")
                            # Clear transition state
                            self.current_transition_name = None
                            self.current_transition_pair = None

                        # DEBUG: Log transition details periodically
                        if frame_idx % 15 == 0:  # Log every 15 frames (0.5s at 30fps)
                            transition_used = transition_name if transition_name else (transition_shader['name'] if transition_shader else "None")
                            self.logger.debug(f"TRANSITION FRAME: {time_seconds:.2f}s - {current_element['name']} -> {next_element['name']} (progress: {transition_progress:.3f}) using transition: {transition_used}")

                        self.logger.debug(f"Rendering transition frame at {time_seconds:.2f}s: {current_element['name']} -> {next_element['name']} (progress: {transition_progress:.3f})")

                        if transition_shader:
                            self.logger.debug(f"Using complex transition shader at {time_seconds:.2f}s")
                            self.render_transition_frame(
                                compiled_shaders[current_element['id']],
                                compiled_shaders[next_element['id']],
                                transition_shader,
                                vbo, fbo, audio_data, frame_idx, frame_rate,
                                transition_progress, raw_file
                            )
                        else:
                            # Fallback to simple alpha blend if no transition shader
                            self.logger.debug(f"Using simple alpha blend transition at {time_seconds:.2f}s")
                            self.render_simple_transition_frame(
                                compiled_shaders[current_element['id']],
                                compiled_shaders[next_element['id']],
                                vbo, fbo, audio_data, frame_idx, frame_rate,
                                transition_progress, raw_file
                            )
                    else:
                        # Fallback to single shader or black
                        self.logger.warning(f"Transition fallback at {time_seconds:.2f}s - missing shaders: current={current_element['name'] if current_element else 'None'}, next={next_element['name'] if next_element else 'None'}")
                        if current_element and current_element['id'] in compiled_shaders:
                            self.render_shader_frame(
                                compiled_shaders[current_element['id']], vbo, fbo,
                                audio_data, frame_idx, frame_rate, raw_file
                            )
                        else:
                            self.logger.warning(f"Rendering black frame at {time_seconds:.2f}s - no valid shader")
                            self.render_black_frame(fbo, raw_file)
                else:
                    # Normal single shader rendering (not in transition)
                    # Clear transition state if we were in one
                    if self.current_transition_name:
                        self.logger.info(f"✓ Transition ended: {self.current_transition_name}")
                        self.current_transition_name = None
                        self.current_transition_pair = None

                    if current_element and current_element['id'] in compiled_shaders:
                        self.logger.debug(f"Rendering normal shader frame at {time_seconds:.2f}s: {current_element['name']}")
                        self.render_shader_frame(
                            compiled_shaders[current_element['id']], vbo, fbo,
                            audio_data, frame_idx, frame_rate, raw_file
                        )
                    else:
                        self.logger.warning(f"No shader found at {time_seconds:.2f}s - rendering black")
                        self.render_black_frame(fbo, raw_file)

                # Progress indicator - more frequent and detailed
                if frame_idx % (frame_rate * 2) == 0:  # Every 2 seconds
                    # Layer 1 (shaders) represents 0-60% of total progress
                    layer_progress = (frame_idx / total_frames) * 100
                    progress = (layer_progress * 0.60)  # Scale to 60% of total
                    # Structured progress output for web UI parsing
                    current_shader_name = current_element['name'] if current_element else "None"
                    self.logger.info(f"PROGRESS: {progress:.1f}% | STAGE: Rendering shader | ITEM: {current_shader_name} | TIME: {time_seconds:.1f}s/{duration:.1f}s")

            raw_file.close()

            # Convert raw video to MP4
            self.logger.info("Converting raw video to MP4...")
            self.convert_raw_to_mp4(
                self.temp_dir / "layer1_raw.rgb",
                output_path,
                width, height, frame_rate
            )

            self.logger.info("✓ Layer 1 (shaders) rendering complete")

        except Exception as e:
            raw_file.close()
            raise e

    def find_element_at_time(self, elements, time_seconds):
        """Find which element should be active at a given time."""
        for element in elements:
            if element['startTime'] <= time_seconds < element['endTime']:
                return element
        return None

    def find_transition_state(self, elements, time_seconds, transition_duration, overlap_duration):
        """Find if we're in a transition and return current/next elements with progress.

        Transition logic: Detect overlapping periods between consecutive shaders.
        When two shaders overlap in time, that's the transition period.
        """
        # Sort elements by start time
        sorted_elements = sorted(elements, key=lambda x: x['startTime'])

        for i, element in enumerate(sorted_elements):
            if i + 1 < len(sorted_elements):
                next_element = sorted_elements[i + 1]

                # Check if there's an overlap between current and next element
                overlap_start = max(element['startTime'], next_element['startTime'])
                overlap_end = min(element['endTime'], next_element['endTime'])

                # If there's an overlap and we're in that time range
                if overlap_start < overlap_end and overlap_start <= time_seconds <= overlap_end:
                    # Calculate progress through the transition
                    transition_duration_actual = overlap_end - overlap_start
                    progress = (time_seconds - overlap_start) / transition_duration_actual
                    progress = max(0.0, min(1.0, progress))

                    # Get the specific transition name from mapping
                    overlap_key = f"{element['id']}->{next_element['id']}"
                    transition_name = getattr(self, 'transition_mapping', {}).get(overlap_key, None)

                    self.logger.debug(f"Transition: {time_seconds:.2f}s in overlap [{overlap_start:.2f}, {overlap_end:.2f}] ({transition_duration_actual:.1f}s) - {element['name']} -> {next_element['name']} (progress: {progress:.3f}) using {transition_name}")
                    return element, next_element, progress, transition_name

        # Not in transition, find current element normally
        current_element = self.find_element_at_time(elements, time_seconds)
        return current_element, None, None, None

    def initialize_buffer_textures(self, shader_data, resolution):
        """Initialize ping-pong textures and framebuffers for all buffers."""
        for buffer_id, buffer_data in shader_data.get('buffers', {}).items():
            # Create two textures for ping-pong rendering
            buffer_data['texture_current'] = self.ctx.texture(resolution, 3)
            buffer_data['texture_previous'] = self.ctx.texture(resolution, 3)

            # Set texture parameters
            for tex in [buffer_data['texture_current'], buffer_data['texture_previous']]:
                tex.filter = (self.ctx.LINEAR, self.ctx.LINEAR)
                tex.repeat_x = False
                tex.repeat_y = False

            # Create framebuffers
            buffer_data['fbo_current'] = self.ctx.framebuffer(
                color_attachments=[buffer_data['texture_current']]
            )
            buffer_data['fbo_previous'] = self.ctx.framebuffer(
                color_attachments=[buffer_data['texture_previous']]
            )

            self.logger.debug(f"Initialized buffer {buffer_id} textures: {resolution}")

    def swap_buffer_textures(self, buffer_data):
        """Swap current and previous textures for ping-pong rendering."""
        buffer_data['texture_current'], buffer_data['texture_previous'] = \
            buffer_data['texture_previous'], buffer_data['texture_current']
        buffer_data['fbo_current'], buffer_data['fbo_previous'] = \
            buffer_data['fbo_previous'], buffer_data['fbo_current']

    def render_buffer_pass(self, buffer_data, vbo, audio_texture, time_seconds, resolution):
        """Render a single buffer pass with feedback support."""
        buffer_data['fbo_current'].use()

        program = buffer_data['program']
        vao = self.ctx.simple_vertex_array(program, vbo, 'in_vert')

        # Bind audio to iChannel0
        audio_texture.use(location=0)
        if 'iChannel0' in program:
            program['iChannel0'].value = 0

        # Bind previous frame to iChannel1 (feedback)
        if buffer_data['texture_previous']:
            buffer_data['texture_previous'].use(location=1)
            if 'iChannel1' in program:
                program['iChannel1'].value = 1

        # Set uniforms
        if 'iTime' in program:
            program['iTime'].value = time_seconds
        if 'iResolution' in program:
            program['iResolution'].value = resolution

        # Clear and render
        self.ctx.clear(0.0, 0.0, 0.0, 1.0)
        vao.render()

    def render_shader_frame_with_buffers(self, shader_data, vbo, fbo, audio_data, frame_idx, frame_rate, raw_file):
        """Render a frame with multi-pass buffer support."""
        time_seconds = frame_idx / frame_rate
        resolution = (fbo.width, fbo.height)

        # Create audio texture
        audio_texture = None
        if audio_data:
            audio_frame_idx = min(frame_idx, len(audio_data['bass']) - 1)
            bass_value = audio_data['bass'][audio_frame_idx]
            treble_value = audio_data['treble'][audio_frame_idx]
            waveform_data = audio_data['waveform'][audio_frame_idx] if 'waveform' in audio_data else None
            fft_spectrum = audio_data['fft_spectrum'][:, audio_frame_idx] if 'fft_spectrum' in audio_data else None
            audio_texture = self.create_audio_texture(bass_value, treble_value, waveform_data, fft_spectrum)

        # Render all buffer passes in order (A, B, C, D)
        if audio_texture:
            for buffer_id in ['A', 'B', 'C', 'D']:
                if buffer_id in shader_data.get('buffers', {}):
                    self.render_buffer_pass(
                        shader_data['buffers'][buffer_id],
                        vbo,
                        audio_texture,
                        time_seconds,
                        resolution
                    )

        # Render main image using buffer outputs
        fbo.use()
        program = shader_data['program']
        vao = self.ctx.simple_vertex_array(program, vbo, 'in_vert')

        # Bind audio to iChannel0
        if audio_texture:
            audio_texture.use(location=0)
            if 'iChannel0' in program:
                program['iChannel0'].value = 0

        # Bind buffer outputs to iChannel1, iChannel2, etc.
        channel = 1
        for buffer_id in ['A', 'B', 'C', 'D']:
            if buffer_id in shader_data.get('buffers', {}):
                shader_data['buffers'][buffer_id]['texture_current'].use(location=channel)
                if f'iChannel{channel}' in program:
                    program[f'iChannel{channel}'].value = channel
                channel += 1

        # Set uniforms
        if 'iTime' in program:
            program['iTime'].value = time_seconds
        if 'iResolution' in program:
            program['iResolution'].value = resolution

        # Clear and render
        self.ctx.clear(0.0, 0.0, 0.0, 1.0)
        vao.render()

        # Read pixels and write to raw file
        pixels = fbo.read(components=3)
        raw_file.write(pixels)

        # Swap ping-pong buffers for next frame
        for buffer_id, buffer_data in shader_data.get('buffers', {}).items():
            self.swap_buffer_textures(buffer_data)

        # Cleanup
        if audio_texture:
            audio_texture.release()

    def render_shader_frame(self, shader_data, vbo, fbo, audio_data, frame_idx, frame_rate, raw_file):
        """Render a single frame using a shader."""
        # Check if shader has buffers
        if shader_data.get('buffers'):
            self.render_shader_frame_with_buffers(shader_data, vbo, fbo, audio_data, frame_idx, frame_rate, raw_file)
            return

        # Standard single-pass rendering
        program = shader_data['program']
        vao = self.ctx.simple_vertex_array(program, vbo, 'in_vert')

        # Set uniforms
        time_seconds = frame_idx / frame_rate

        if 'iTime' in program:
            program['iTime'].value = time_seconds
        if 'iResolution' in program:
            program['iResolution'].value = (fbo.width, fbo.height)

        # Audio reactivity - Create and bind audio texture
        audio_texture = None
        if audio_data and 'iChannel0' in program:
            # Create audio texture (matching render_shader.py and transition rendering)
            audio_frame_idx = min(frame_idx, len(audio_data['bass']) - 1)
            bass_value = audio_data['bass'][audio_frame_idx]
            treble_value = audio_data['treble'][audio_frame_idx]
            waveform_data = audio_data['waveform'][audio_frame_idx] if 'waveform' in audio_data else None
            fft_spectrum = audio_data['fft_spectrum'][:, audio_frame_idx] if 'fft_spectrum' in audio_data else None

            audio_texture = self.create_audio_texture(bass_value, treble_value, waveform_data, fft_spectrum)
            audio_texture.use(location=0)
            program['iChannel0'].value = 0

        # Bind custom textures to iChannel1, iChannel2, etc.
        textures = shader_data.get('textures', {})
        if textures:
            for texture_channel in sorted(textures.keys()):
                if texture_channel.startswith('iChannel'):
                    try:
                        requested_channel = int(texture_channel.replace('iChannel', ''))
                        textures[texture_channel].use(location=requested_channel)
                        if texture_channel in program:
                            program[texture_channel].value = requested_channel
                    except ValueError:
                        self.logger.error(f"Invalid channel name: {texture_channel}")

        # Render to framebuffer
        fbo.use()
        self.ctx.clear(0.0, 0.0, 0.0, 1.0)
        vao.render()

        # Read pixels and write to raw file
        pixels = fbo.read(components=3)
        raw_file.write(pixels)

        # Cleanup audio texture
        if audio_texture:
            audio_texture.release()

    def render_transition_frame(self, from_shader_data, to_shader_data, transition_data,
                              vbo, fbo, audio_data, frame_idx, frame_rate, progress, raw_file):
        """Render a transition frame blending two shaders."""
        if not transition_data:
            # Fallback to simple alpha blend if no transition shader
            self.render_simple_transition_frame(
                from_shader_data, to_shader_data, vbo, fbo, audio_data,
                frame_idx, frame_rate, progress, raw_file
            )
            return

        # Create temporary textures and framebuffers for each shader
        temp_texture_from = self.ctx.texture((fbo.width, fbo.height), 3)
        temp_texture_to = self.ctx.texture((fbo.width, fbo.height), 3)
        temp_fbo_from = self.ctx.framebuffer(color_attachments=[temp_texture_from])
        temp_fbo_to = self.ctx.framebuffer(color_attachments=[temp_texture_to])

        time_seconds = frame_idx / frame_rate

        # Create audio texture (matching render_shader.py)
        audio_frame_idx = min(frame_idx, len(audio_data['bass']) - 1)
        bass_value = audio_data['bass'][audio_frame_idx]
        treble_value = audio_data['treble'][audio_frame_idx]
        waveform_data = audio_data['waveform'][audio_frame_idx] if 'waveform' in audio_data else None
        fft_spectrum = audio_data['fft_spectrum'][:, audio_frame_idx] if 'fft_spectrum' in audio_data else None
        audio_texture = self.create_audio_texture(bass_value, treble_value, waveform_data, fft_spectrum)
        audio_texture.use(location=0)

        try:
            # Render FROM shader to temporary framebuffer
            temp_fbo_from.use()
            from_program = from_shader_data['program']
            from_vao = self.ctx.simple_vertex_array(from_program, vbo, 'in_vert')
            if 'iTime' in from_program:
                from_program['iTime'].value = time_seconds
            if 'iResolution' in from_program:
                from_program['iResolution'].value = (fbo.width, fbo.height)
            if 'iChannel0' in from_program:
                from_program['iChannel0'].value = 0
            self.ctx.clear(0.0, 0.0, 0.0, 1.0)
            from_vao.render()

            # Render TO shader to temporary framebuffer
            temp_fbo_to.use()
            to_program = to_shader_data['program']
            to_vao = self.ctx.simple_vertex_array(to_program, vbo, 'in_vert')
            if 'iTime' in to_program:
                to_program['iTime'].value = time_seconds
            if 'iResolution' in to_program:
                to_program['iResolution'].value = (fbo.width, fbo.height)
            if 'iChannel0' in to_program:
                to_program['iChannel0'].value = 0
            self.ctx.clear(0.0, 0.0, 0.0, 1.0)
            to_vao.render()

            # Apply transition shader
            fbo.use()
            transition_program = transition_data['program']
            transition_vao = self.ctx.simple_vertex_array(transition_program, vbo, 'in_vert')

            # Bind textures from temporary framebuffers
            temp_texture_from.use(location=0)
            temp_texture_to.use(location=1)

            # Set transition uniforms
            if 'from' in transition_program:
                transition_program['from'].value = 0
            if 'to' in transition_program:
                transition_program['to'].value = 1
            if 'progress' in transition_program:
                transition_program['progress'].value = progress
            if 'resolution' in transition_program:
                transition_program['resolution'].value = (fbo.width, fbo.height)

            # Apply shader-specific configuration (matching render_shader.py)
            transition_config = transition_data.get('config', {})
            for param_name, param_value in transition_config.items():
                if param_name in ['resolution', 'preference', 'status']:  # Skip special parameters
                    continue
                try:
                    if param_name in transition_program:
                        if isinstance(param_value, list):
                            if len(param_value) == 2:
                                transition_program[param_name].value = tuple(param_value)
                            elif len(param_value) == 3:
                                transition_program[param_name].value = tuple(param_value)
                            elif len(param_value) == 4:
                                transition_program[param_name].value = tuple(param_value)
                            else:
                                transition_program[param_name].value = param_value[0]
                        else:
                            transition_program[param_name].value = param_value
                except Exception as e:
                    # Skip parameters that can't be set
                    pass

            # Render transition
            self.ctx.clear(0.0, 0.0, 0.0, 1.0)
            transition_vao.render()

            # Read frame data and write to raw file
            data = fbo.read(components=3)
            raw_file.write(data)

        finally:
            # Cleanup temporary resources (matching render_shader.py)
            audio_texture.release()
            temp_texture_from.release()
            temp_texture_to.release()
            temp_fbo_from.release()
            temp_fbo_to.release()

    def render_simple_transition_frame(self, from_shader_data, to_shader_data, vbo, fbo,
                                     audio_data, frame_idx, frame_rate, progress, raw_file):
        """Render a simple alpha-blended transition frame when no transition shader is available."""
        # Create temporary textures for blending
        temp_texture_from = self.ctx.texture((fbo.width, fbo.height), 3)
        temp_texture_to = self.ctx.texture((fbo.width, fbo.height), 3)
        temp_fbo_from = self.ctx.framebuffer(color_attachments=[temp_texture_from])
        temp_fbo_to = self.ctx.framebuffer(color_attachments=[temp_texture_to])

        time_seconds = frame_idx / frame_rate

        # Create audio texture for both shaders (matching render_shader.py)
        audio_texture = None
        if audio_data:
            audio_frame_idx = min(frame_idx, len(audio_data['bass']) - 1)
            bass_value = audio_data['bass'][audio_frame_idx]
            treble_value = audio_data['treble'][audio_frame_idx]
            waveform_data = audio_data['waveform'][audio_frame_idx] if 'waveform' in audio_data else None
            fft_spectrum = audio_data['fft_spectrum'][:, audio_frame_idx] if 'fft_spectrum' in audio_data else None

            audio_texture = self.create_audio_texture(bass_value, treble_value, waveform_data, fft_spectrum)
            audio_texture.use(location=0)

        try:
            # Render FROM shader
            temp_fbo_from.use()
            from_program = from_shader_data['program']
            from_vao = self.ctx.simple_vertex_array(from_program, vbo, 'in_vert')
            if 'iTime' in from_program:
                from_program['iTime'].value = time_seconds
            if 'iResolution' in from_program:
                from_program['iResolution'].value = (fbo.width, fbo.height)
            if 'iChannel0' in from_program and audio_texture:
                from_program['iChannel0'].value = 0
            self.ctx.clear(0.0, 0.0, 0.0, 1.0)
            from_vao.render()

            # Render TO shader
            temp_fbo_to.use()
            to_program = to_shader_data['program']
            to_vao = self.ctx.simple_vertex_array(to_program, vbo, 'in_vert')
            if 'iTime' in to_program:
                to_program['iTime'].value = time_seconds
            if 'iResolution' in to_program:
                to_program['iResolution'].value = (fbo.width, fbo.height)
            if 'iChannel0' in to_program and audio_texture:
                to_program['iChannel0'].value = 0
            self.ctx.clear(0.0, 0.0, 0.0, 1.0)
            to_vao.render()

            # Proper alpha blend in main framebuffer
            fbo.use()
            self.ctx.clear(0.0, 0.0, 0.0, 1.0)

            # Enable blending for proper alpha compositing
            self.ctx.enable(moderngl.BLEND)
            self.ctx.blend_func = moderngl.SRC_ALPHA, moderngl.ONE_MINUS_SRC_ALPHA

            # First render FROM shader at full opacity
            temp_texture_from.use(location=0)

            # Create a simple blending shader for alpha compositing
            blend_vertex = """
            #version 330 core
            in vec2 in_vert;
            out vec2 uv;
            void main() {
                gl_Position = vec4(in_vert, 0.0, 1.0);
                uv = (in_vert + 1.0) * 0.5;
            }
            """

            blend_fragment = f"""
            #version 330 core
            uniform sampler2D from_texture;
            uniform sampler2D to_texture;
            uniform float progress;
            in vec2 uv;
            out vec4 fragColor;
            void main() {{
                vec4 from_color = texture(from_texture, uv);
                vec4 to_color = texture(to_texture, uv);
                fragColor = mix(from_color, to_color, progress);
            }}
            """

            # Create temporary blend program
            blend_program = self.ctx.program(vertex_shader=blend_vertex, fragment_shader=blend_fragment)
            blend_vao = self.ctx.simple_vertex_array(blend_program, vbo, 'in_vert')

            # Bind textures and set progress
            temp_texture_from.use(location=0)
            temp_texture_to.use(location=1)
            blend_program['from_texture'].value = 0
            blend_program['to_texture'].value = 1
            blend_program['progress'].value = progress

            # Render blended result
            blend_vao.render()

            self.ctx.disable(moderngl.BLEND)

            # Read frame data
            data = fbo.read(components=3)
            raw_file.write(data)

        finally:
            # Cleanup
            if audio_texture:
                audio_texture.release()
            temp_texture_from.release()
            temp_texture_to.release()
            temp_fbo_from.release()
            temp_fbo_to.release()

    def render_greenscreen_frame(self, element, video_time, width, height, raw_file):
        """Render a single frame from a green screen video with scaling and positioning."""
        video_path = Path(element['path'])

        # Extract frame from video at specific time
        frame_data = self.extract_video_frame(video_path, video_time)

        if frame_data is None:
            # Fallback to green fill if frame extraction fails
            self.render_green_fill_frame(width, height, raw_file)
            return

        # Scale and position the video frame
        processed_frame = self.scale_and_position_video_frame(
            frame_data, width, height
        )

        # Apply green screen removal if enabled
        if element.get('greenscreen', {}).get('enabled', True):  # Default to enabled
            processed_frame = self.apply_chromakey_to_frame(processed_frame, element)

        # Write frame to raw file
        raw_file.write(processed_frame.tobytes())

    def extract_video_frame(self, video_path, time_seconds):
        """Extract a single frame from video at specified time."""
        try:
            # Get video info first to check duration and dimensions
            probe_cmd = [
                'ffprobe',
                '-v', 'quiet',
                '-print_format', 'json',
                '-show_format',
                '-show_streams',
                str(video_path)
            ]

            probe_result = subprocess.run(probe_cmd, capture_output=True, check=True, text=True)
            import json
            probe_data = json.loads(probe_result.stdout)

            # Find video stream
            video_stream = None
            for stream in probe_data['streams']:
                if stream['codec_type'] == 'video':
                    video_stream = stream
                    break

            if not video_stream:
                self.logger.warning(f"No video stream found in {video_path}")
                return None

            video_width = int(video_stream['width'])
            video_height = int(video_stream['height'])

            # Get video duration
            duration = float(probe_data['format']['duration'])

            # Check if requested time is beyond video duration
            if time_seconds >= duration:
                self.logger.debug(f"Requested time {time_seconds}s exceeds video duration {duration}s for {video_path}, using last frame")
                # Use the last frame instead
                time_seconds = max(0, duration - 0.1)

            # Use FFmpeg to extract frame at specific time
            cmd = [
                'ffmpeg',
                '-y',
                '-ss', str(time_seconds),
                '-i', str(video_path),
                '-vframes', '1',
                '-f', 'rawvideo',
                '-pix_fmt', 'rgb24',
                '-'
            ]

            result = subprocess.run(cmd, capture_output=True, check=True)

            # Convert raw bytes to numpy array
            frame_data = np.frombuffer(result.stdout, dtype=np.uint8)

            # Check if we got the expected amount of data
            expected_size = video_width * video_height * 3
            if len(frame_data) != expected_size:
                self.logger.warning(f"Frame data size mismatch for {video_path} at {time_seconds}s: got {len(frame_data)}, expected {expected_size}")
                return None

            frame_data = frame_data.reshape((video_height, video_width, 3))

            return frame_data

        except Exception as e:
            self.logger.warning(f"Failed to extract frame from {video_path} at {time_seconds}s: {e}")
            return None

    def scale_and_position_video_frame(self, frame_data, target_width, target_height):
        """Scale video frame to fill entire canvas at composition aspect ratio."""
        from PIL import Image

        # Convert numpy array to PIL Image
        frame_height, frame_width = frame_data.shape[:2]
        frame_image = Image.fromarray(frame_data, 'RGB')

        # Scale video to exactly match target dimensions (composition aspect ratio)
        # This ensures the green screen video fills the entire canvas
        scaled_image = frame_image.resize((target_width, target_height), Image.LANCZOS)

        # Convert back to numpy array
        return np.array(scaled_image)

    def apply_chromakey_to_frame(self, frame_data, element):
        """Apply chroma key to normalize green colors to rgb(0, 214, 0) for consistent FFmpeg processing."""
        # Get chroma key parameters with defaults
        greenscreen_config = element.get('greenscreen', {})
        color = greenscreen_config.get('color', [0, 214, 0])  # Default: rgb(0, 214, 0)
        threshold = greenscreen_config.get('threshold', 0.5)  # Similarity threshold

        # Convert to float for processing
        frame_float = frame_data.astype(np.float32) / 255.0
        target_color = np.array(color, dtype=np.float32) / 255.0

        # Calculate color distance using multiple green variations
        # This handles slight variations in green screen color
        green_variations = [
            [0.0, 214.0/255.0, 0.0],  # Target green rgb(0, 214, 0)
            [0.0, 0.8, 0.0],          # Darker green
            [0.1, 0.9, 0.1],          # Slightly off-green
            [0.0, 0.9, 0.0],          # Medium green
        ]

        mask = np.zeros(frame_float.shape[:2], dtype=bool)

        # Check against multiple green variations
        for green_var in green_variations:
            diff = frame_float - np.array(green_var)
            distance = np.sqrt(np.sum(diff * diff, axis=2))
            mask |= distance < threshold

        # Also check the original target color
        diff = frame_float - target_color
        distance = np.sqrt(np.sum(diff * diff, axis=2))
        mask |= distance < threshold

        # Replace green areas with consistent rgb(0, 214, 0) for FFmpeg chroma key
        frame_float[mask] = [0.0, 214.0/255.0, 0.0]  # rgb(0, 214, 0)

        # Convert back to uint8
        return (frame_float * 255).astype(np.uint8)

    def render_green_fill_frame(self, width, height, raw_file):
        """Render a solid green frame for gaps between videos - matches chroma key color."""
        # Create solid green frame matching chroma key target: rgb(0, 214, 0)
        green_frame = np.full((height, width, 3), [0, 214, 0], dtype=np.uint8)
        raw_file.write(green_frame.tobytes())

    def render_black_frame(self, fbo, raw_file):
        """Render a black frame."""
        fbo.use()
        self.ctx.clear(0.0, 0.0, 0.0, 1.0)
        pixels = fbo.read(components=3)
        raw_file.write(pixels)

    def convert_raw_to_mp4(self, raw_path, output_path, width, height, frame_rate):
        """Convert raw RGB video to MP4 using FFmpeg."""
        self.logger.info("\n🎬 CONVERTING RAW TO MP4")
        self.logger.info(f"Input: {raw_path}")
        self.logger.info(f"Output: {output_path}")
        self.logger.info(f"Resolution: {width}x{height} @ {frame_rate}fps")
        self.logger.info(f"Output pixel format: yuv420p (no alpha channel)")

        cmd = [
            'ffmpeg',
            '-y',
            '-f', 'rawvideo',
            '-vcodec', 'rawvideo',
            '-s', f'{width}x{height}',
            '-pix_fmt', 'rgb24',
            '-r', str(frame_rate),
            '-i', str(raw_path),
            '-c:v', 'libx264',
            '-crf', '18',
            '-preset', 'medium',
            '-pix_fmt', 'yuv420p',
            str(output_path)
        ]

        # Log the full command for manual testing
        cmd_str = ' '.join(str(c) for c in cmd)
        self.logger.info("\n📋 FFmpeg Command (copy/paste to test manually):")
        self.logger.info(cmd_str)

        self.logger.info("\n⏳ Running FFmpeg conversion...")
        result = subprocess.run(cmd, capture_output=True, text=True)

        if result.returncode != 0:
            self.logger.error(f"❌ FFmpeg conversion failed!")
            self.logger.error(f"Return code: {result.returncode}")
            self.logger.error(f"stderr: {result.stderr}")
            raise subprocess.CalledProcessError(result.returncode, cmd, result.stderr)

        # Log FFmpeg output for debugging
        if result.stderr:
            self.logger.debug("FFmpeg stderr output:")
            for line in result.stderr.split('\n'):
                if line.strip() and ('frame=' in line or 'error' in line.lower() or 'warning' in line.lower()):
                    self.logger.debug(f"  {line}")

        self.logger.info("✓ Conversion complete")

    def convert_raw_to_mp4_with_chromakey(self, raw_path, output_path, width, height, frame_rate):
        """Convert raw RGB video to MP4 with chroma key filtering for rgb(0, 216, 0) green."""
        # Chroma key parameters:
        # - Target color: rgb(0, 216, 0) = 0x00d800
        # - Threshold: 0.5 (similarity - how close to green to remove)
        # - Smoothness: 0.3 (edge blending)

        self.logger.info("\n🎬 CHROMA KEY CONVERSION")
        self.logger.info(f"Input: {raw_path}")
        self.logger.info(f"Output: {output_path}")
        self.logger.info(f"Resolution: {width}x{height} @ {frame_rate}fps")
        self.logger.info(f"Chroma key color: 0x00d800 (rgb(0, 216, 0) - your green screen color)")
        self.logger.info(f"Similarity threshold: 0.5 (how close to green to remove)")
        self.logger.info(f"Blend/smoothness: 0.3 (edge smoothing)")
        self.logger.info(f"Output pixel format: yuva420p (WITH alpha channel)")

        cmd = [
            'ffmpeg',
            '-y',
            '-f', 'rawvideo',
            '-vcodec', 'rawvideo',
            '-s', f'{width}x{height}',
            '-pix_fmt', 'rgb24',
            '-r', str(frame_rate),
            '-i', str(raw_path),
            '-vf', 'chromakey=0x00d800:0.5:0.3',  # Target rgb(0, 216, 0) with threshold 0.5
            '-c:v', 'libx264',
            '-crf', '18',
            '-preset', 'medium',
            '-pix_fmt', 'yuva420p',  # Support transparency
            str(output_path)
        ]

        # Log the full command for manual testing
        cmd_str = ' '.join(str(c) for c in cmd)
        self.logger.info("\n📋 FFmpeg Command (copy/paste to test manually):")
        self.logger.info(cmd_str)

        self.logger.info("\n⏳ Running FFmpeg chroma key conversion...")
        result = subprocess.run(cmd, capture_output=True, text=True)

        if result.returncode != 0:
            self.logger.error(f"❌ FFmpeg chroma key failed!")
            self.logger.error(f"Return code: {result.returncode}")
            self.logger.error(f"stderr: {result.stderr}")
            raise subprocess.CalledProcessError(result.returncode, cmd, result.stderr)

        # Log FFmpeg output for debugging
        if result.stderr:
            self.logger.debug("FFmpeg stderr output:")
            for line in result.stderr.split('\n'):
                if line.strip():
                    self.logger.debug(f"  {line}")

        self.logger.info("✓ Chroma key conversion complete")

    def render_video_layer(self, elements, output_path):
        """Render video layer with green screen processing and proper video playback."""
        self.logger.info("Processing green screen videos with frame-by-frame rendering...")

        width, height = self.get_resolution()
        frame_rate = self.get_frame_rate()
        duration = self.manifest['timeline']['duration']
        total_frames = int(duration * frame_rate)

        self.logger.info(f"Layer 0 (green screen) total frames: {total_frames}")

        # Create raw video file for layer 0
        raw_file = open(self.temp_dir / "layer0_raw.rgb", 'wb')

        try:
            # Render each frame
            for frame_idx in range(total_frames):
                time_seconds = frame_idx / frame_rate

                # Find active video element at this time
                active_element = self.find_element_at_time(elements, time_seconds)

                if active_element:
                    # Calculate video time offset within the element
                    element_start = active_element['startTime']
                    video_time = time_seconds - element_start

                    # Render video frame with green screen processing
                    self.render_greenscreen_frame(
                        active_element, video_time, width, height, raw_file
                    )
                else:
                    # No active video - render neon green fill for chroma key
                    self.render_green_fill_frame(width, height, raw_file)

                # Progress indicator - more frequent and detailed
                if frame_idx % (frame_rate * 2) == 0:  # Every 2 seconds
                    # Layer 0 (green screen) represents 60-75% of total progress
                    layer_progress = (frame_idx / total_frames) * 100
                    progress = 60.0 + (layer_progress * 0.15)  # Scale to 15% of total, offset by 60%
                    current_video_name = active_element['name'] if active_element else "None"
                    self.logger.info(f"PROGRESS: {progress:.1f}% | STAGE: Rendering green screen | ITEM: {current_video_name} | TIME: {time_seconds:.1f}s/{duration:.1f}s")

            raw_file.close()

            # Don't convert to MP4 here - chroma key will be applied during compositing
            # This avoids alpha channel loss that occurs with intermediate MP4 files
            self.logger.info("\n✓ Layer 0 (green screen) raw rendering complete")
            self.logger.info("ℹ️ Chroma key will be applied during compositing (single-pass)")

            # Return path to raw RGB file instead of MP4
            return str(self.temp_dir / "layer0_raw.rgb")

        except Exception as e:
            raw_file.close()
            raise e

    def create_blank_video(self, output_path, width, height, frame_rate, duration):
        """Create a blank (transparent) video."""
        cmd = [
            'ffmpeg',
            '-y',
            '-f', 'lavfi',
            '-i', f'color=c=black@0.0:s={width}x{height}:r={frame_rate}:d={duration}',
            '-c:v', 'libx264',
            '-pix_fmt', 'yuva420p',
            str(output_path)
        ]

        subprocess.run(cmd, check=True, capture_output=True)

    def apply_greenscreen(self, element, video_path):
        """Apply chroma key to remove green screen from video."""
        greenscreen_config = element.get('greenscreen', {})

        # Get chroma key parameters
        color = greenscreen_config.get('color', [0, 255, 0])  # Default: green
        threshold = greenscreen_config.get('threshold', 0.4)
        smoothness = greenscreen_config.get('smoothness', 0.1)

        # Convert RGB to hex color for FFmpeg
        color_hex = f"0x{color[0]:02x}{color[1]:02x}{color[2]:02x}"

        output_path = self.temp_dir / f"greenscreen_{element['id']}.mp4"

        self.logger.info(f"    Applying chroma key (color={color_hex}, threshold={threshold})")

        cmd = [
            'ffmpeg',
            '-y',
            '-i', str(video_path),
            '-vf', f'chromakey={color_hex}:{threshold}:{smoothness}',
            '-c:v', 'libx264',
            '-pix_fmt', 'yuva420p',
            str(output_path)
        ]

        subprocess.run(cmd, check=True, capture_output=True)

        return output_path

    def composite_videos_on_canvas(self, canvas_path, videos, output_path):
        """Composite multiple videos onto a canvas at specific times."""
        # Build FFmpeg filter complex for overlaying videos at specific times
        filter_parts = []
        inputs = ['-i', str(canvas_path)]

        for idx, video in enumerate(videos):
            inputs.extend(['-i', str(video['path'])])

            # Create overlay filter with timing
            if idx == 0:
                filter_parts.append(
                    f"[0:v][{idx+1}:v]overlay=enable='between(t,{video['start_time']},{video['start_time']+video['duration']})'[v{idx}]"
                )
            else:
                filter_parts.append(
                    f"[v{idx-1}][{idx+1}:v]overlay=enable='between(t,{video['start_time']},{video['start_time']+video['duration']})'[v{idx}]"
                )

        # Final output is the last overlay
        filter_complex = ';'.join(filter_parts)

        cmd = [
            'ffmpeg',
            '-y',
            *inputs,
            '-filter_complex', filter_complex,
            '-map', f'[v{len(videos)-1}]',
            '-c:v', 'libx264',
            '-pix_fmt', 'yuva420p',
            str(output_path)
        ]

        subprocess.run(cmd, check=True, capture_output=True)

    def create_black_video(self):
        """Create a black video for empty layers."""
        width, height = self.get_resolution()
        frame_rate = self.get_frame_rate()
        duration = self.manifest['timeline']['duration']

        output_path = self.temp_dir / "black_video.mp4"

        cmd = [
            'ffmpeg',
            '-y',
            '-f', 'lavfi',
            '-i', f'color=c=black:s={width}x{height}:r={frame_rate}:d={duration}',
            '-c:v', 'libx264',
            '-pix_fmt', 'yuv420p',
            str(output_path)
        ]

        subprocess.run(cmd, check=True, capture_output=True)

        return output_path


def main():
    """Main entry point."""
    if len(sys.argv) < 2:
        print("Usage: python render_timeline.py <manifest.json>")
        sys.exit(1)
    
    manifest_path = sys.argv[1]
    
    try:
        renderer = TimelineRenderer(manifest_path)
        output_path = renderer.render()
        
        if output_path:
            sys.exit(0)
        else:
            sys.exit(1)
            
    except Exception as e:
        print(f"Fatal error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == "__main__":
    main()

