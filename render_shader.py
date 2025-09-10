#!/usr/bin/env python3
"""
OneOffRender - Standalone Command-Line Shader Video Generator
Creates audio-reactive videos from GLSL shaders and audio files.
"""

import json
import logging
import sys
import time
from pathlib import Path
import subprocess
import tempfile
import shutil
import random
import glob

import numpy as np
import moderngl
from PIL import Image
import librosa
import ffmpeg

class ShaderRenderer:
    def __init__(self, config_path="config.json"):
        """Initialize the shader renderer with configuration."""
        self.config_path = Path(config_path)
        self.load_config()
        self.setup_logging()
        self.ctx = None
        
    def load_config(self):
        """Load configuration from JSON file."""
        if not self.config_path.exists():
            raise FileNotFoundError(f"Configuration file not found: {self.config_path}")
            
        with open(self.config_path, 'r') as f:
            self.config = json.load(f)
            
        # Check if batch mode is enabled
        batch_mode = self.config.get('batch_settings', {}).get('enabled', False)

        if batch_mode:
            # In batch mode, audio files are discovered dynamically
            self.shader_path = None  # Will be set by multi-shader discovery
            self.audio_path = None   # Will be set per audio file
            self.output_path = None  # Will be set per audio file

            # Ensure output directory exists
            output_dir = Path(self.config['output'].get('directory', 'Output_Video'))
            output_dir.mkdir(parents=True, exist_ok=True)
        else:
            # Single file mode - validate required paths
            self.shader_path = Path(self.config['input']['shader_file'])
            self.audio_path = Path(self.config['input']['audio_file'])
            self.output_path = Path(self.config['output']['video_file'])

            if not self.shader_path.exists():
                raise FileNotFoundError(f"Shader file not found: {self.shader_path}")
            if not self.audio_path.exists():
                raise FileNotFoundError(f"Audio file not found: {self.audio_path}")

            # Ensure output directory exists
            self.output_path.parent.mkdir(parents=True, exist_ok=True)
        
    def setup_logging(self):
        """Setup logging based on configuration."""
        level = logging.INFO if self.config['debug']['verbose_logging'] else logging.WARNING
        logging.basicConfig(
            level=level,
            format='%(asctime)s - %(levelname)s - %(message)s',
            datefmt='%H:%M:%S'
        )
        self.logger = logging.getLogger(__name__)
        
    def parse_duration(self, time_str):
        """Parse MM:SS format to seconds."""
        try:
            parts = time_str.split(':')
            if len(parts) == 2:
                minutes, seconds = map(int, parts)
                return minutes * 60 + seconds
            else:
                return float(time_str)  # Assume seconds if no colon
        except ValueError:
            self.logger.error(f"Invalid time format: {time_str}")
            return None
            
    def get_audio_duration(self):
        """Get the duration of the audio file."""
        try:
            probe = ffmpeg.probe(str(self.audio_path))
            duration = float(probe['format']['duration'])
            return duration
        except Exception as e:
            self.logger.error(f"Failed to get audio duration: {e}")
            return None
            
    def get_render_duration(self):
        """Get the duration to render based on configuration."""
        if self.config['duration_override']['enabled']:
            cutoff_time = self.config['duration_override']['cutoff_time']
            duration = self.parse_duration(cutoff_time)
            if duration is None:
                self.logger.warning("Invalid cutoff time, using full audio duration")
                return self.get_audio_duration()
            return duration
        else:
            return self.get_audio_duration()
            
    def analyze_audio(self, duration):
        """Analyze audio file for reactivity data with high-resolution 1024-point FFT."""
        self.logger.info("Analyzing audio for reactivity (1024-point FFT)...")

        try:
            # Load audio
            y, sr = librosa.load(str(self.audio_path), sr=None, duration=duration)

            # Calculate frame parameters
            frame_rate = self.config['output']['frame_rate']
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
            self.logger.error(f"Audio analysis failed: {e}")
            return None
            
    def create_audio_texture(self, bass_value, treble_value, waveform_data=None, fft_spectrum=None):
        """Create high-resolution audio texture for shader (Shadertoy-compatible)."""
        # Create a 512x256 texture for high-resolution FFT data
        audio_data = np.zeros((256, 512), dtype=np.float32)

        if fft_spectrum is not None:
            # Row 0: Full 512-bin FFT spectrum (Shadertoy-compatible)
            audio_data[0, :512] = fft_spectrum

            # Row 1: Copy of FFT data for compatibility
            audio_data[1, :512] = fft_spectrum
        else:
            # Fallback to legacy format if no FFT spectrum provided
            # Place bass in lower frequencies (0-63)
            audio_data[0, :64] = bass_value
            # Place treble in higher frequencies (256-319, mapped to available space)
            audio_data[0, 256:320] = treble_value

        # Rows 2-255: Waveform data for oscilloscope algorithm
        if waveform_data is not None:
            # Extend waveform to 512 samples by interpolation for higher resolution
            if len(waveform_data) == 256:
                # Interpolate 256 samples to 512 for better resolution
                extended_waveform = np.interp(
                    np.linspace(0, 255, 512),
                    np.arange(256),
                    waveform_data
                )
            else:
                extended_waveform = waveform_data[:512]  # Truncate if longer

            for y in range(2, 256):
                audio_data[y, :] = extended_waveform

        # Convert to bytes (0-255 range)
        audio_bytes = (audio_data * 255).astype(np.uint8)

        # Create texture (512x256 for high-resolution FFT)
        texture = self.ctx.texture((512, 256), 1, audio_bytes.tobytes())

        # Set texture filtering for smooth interpolation
        texture.filter = (self.ctx.LINEAR, self.ctx.LINEAR)
        texture.repeat_x = False
        texture.repeat_y = False

        return texture

    def discover_shaders(self):
        """Discover all available shader files in the Shaders directory."""
        shaders_dir = Path("Shaders")
        if not shaders_dir.exists():
            self.logger.error("Shaders directory not found")
            return []

        # Find all .glsl files
        shader_files = list(shaders_dir.glob("*.glsl"))

        if not shader_files:
            self.logger.error("No shader files found in Shaders directory")
            return []

        self.logger.info(f"Discovered {len(shader_files)} shader(s): {[s.name for s in shader_files]}")
        return shader_files

    def discover_audio_files(self):
        """Discover all audio files in the Input_Audio directory."""
        audio_dir = Path("Input_Audio")
        if not audio_dir.exists():
            self.logger.error("Input_Audio directory not found")
            return []

        # Supported audio formats
        audio_extensions = ['.mp3', '.wav', '.flac', '.m4a', '.aac', '.ogg', '.wma']
        audio_files = []

        for ext in audio_extensions:
            audio_files.extend(audio_dir.glob(f"*{ext}"))
            audio_files.extend(audio_dir.glob(f"*{ext.upper()}"))

        # Remove duplicates while preserving order
        seen = set()
        unique_audio_files = []
        for f in audio_files:
            if f not in seen:
                seen.add(f)
                unique_audio_files.append(f)

        if not unique_audio_files:
            self.logger.error("No audio files found in Input_Audio directory")
            return []

        self.logger.info(f"Discovered {len(unique_audio_files)} audio file(s): {[f.name for f in unique_audio_files]}")
        return unique_audio_files

    def generate_output_path(self, audio_file):
        """Generate output video path based on audio filename."""
        # Get base filename without extension
        base_name = audio_file.stem

        # Clean up filename for video output
        clean_name = base_name.replace(' ', '_').replace('-', '_')

        # Create output path
        output_dir = Path(self.config['output'].get('directory', 'Output_Video'))
        output_dir.mkdir(parents=True, exist_ok=True)

        output_path = output_dir / f"{clean_name}.mp4"
        return output_path

    def load_shader_from_file(self, shader_path):
        """Load and compile a specific GLSL shader file."""
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

    def precompile_shaders(self, shader_files):
        """Pre-compile all discovered shaders for seamless switching."""
        self.logger.info("Pre-compiling shaders...")
        compiled_shaders = {}

        for shader_file in shader_files:
            self.logger.info(f"Compiling {shader_file.name}...")
            program = self.load_shader_from_file(shader_file)
            if program is not None:
                compiled_shaders[shader_file.name] = {
                    'program': program,
                    'path': shader_file
                }
                self.logger.info(f"✓ {shader_file.name} compiled successfully")
            else:
                self.logger.warning(f"✗ Failed to compile {shader_file.name}")

        if not compiled_shaders:
            self.logger.error("No shaders compiled successfully")
            return None

        self.logger.info(f"Successfully compiled {len(compiled_shaders)} shader(s)")
        return compiled_shaders

    def select_next_shader(self, shader_names, usage_count, history, max_history, config=None):
        """
        Advanced shader selection algorithm that ensures better distribution and variety.

        Algorithm features:
        - Weighted selection favoring less-used shaders
        - Avoids recently used shaders (configurable history)
        - Ensures all shaders get fair representation
        - Maintains randomness while improving distribution
        - Configurable algorithm type and weighting
        """
        if config is None:
            config = {}

        algorithm = config.get('algorithm', 'weighted')
        distribution_weight = config.get('distribution_weight', 2.0)
        # Create candidate list (exclude recent history)
        candidates = [name for name in shader_names if name not in history]

        # If all shaders are in recent history, allow the least recently used
        if not candidates:
            candidates = [history[0]] if history else shader_names

        # Calculate weights based on usage (less used = higher weight)
        min_usage = min(usage_count[name] for name in candidates)
        max_usage = max(usage_count[name] for name in candidates)

        # Create weights based on algorithm type
        weights = []

        if algorithm == 'pure_random':
            # Pure random selection (ignores usage)
            weights = [1.0] * len(candidates)
        elif algorithm == 'weighted':
            # Weighted selection favoring less-used shaders
            for name in candidates:
                usage = usage_count[name]
                if max_usage == min_usage:
                    # All candidates used equally, use equal weights
                    weight = 1.0
                else:
                    # Configurable weighting: less used = higher weight
                    normalized_usage = (usage - min_usage) / (max_usage - min_usage)
                    weight = (1.0 - normalized_usage) ** distribution_weight + 0.1
                weights.append(weight)
        else:
            # Default to equal weights
            weights = [1.0] * len(candidates)

        # Weighted random selection
        total_weight = sum(weights)
        rand_val = random.random() * total_weight

        cumulative_weight = 0
        for i, weight in enumerate(weights):
            cumulative_weight += weight
            if rand_val <= cumulative_weight:
                return candidates[i]

        # Fallback (should never reach here)
        return random.choice(candidates)

    def discover_transitions(self):
        """Discover all transition shaders in the Transitions folder."""
        transitions_config = self.config.get('shader_settings', {}).get('transitions', {})
        if not transitions_config.get('enabled', False):
            return []

        transitions_folder = Path(transitions_config.get('folder', 'Transitions'))
        if not transitions_folder.exists():
            self.logger.warning(f"Transitions folder not found: {transitions_folder}")
            return []

        # Find all .glsl files in transitions folder
        transition_files = list(transitions_folder.glob("*.glsl"))
        if not transition_files:
            self.logger.warning(f"No transition shaders found in {transitions_folder}")
            return []

        self.logger.info(f"Discovered {len(transition_files)} transition shader(s)")
        return transition_files

    def load_transition_config(self):
        """Load transition shader configurations from Transitions_Metadata.json."""
        transitions_config = self.config.get('shader_settings', {}).get('transitions', {})
        config_file = Path(transitions_config.get('config_file', 'Transitions/Transitions_Metadata.json'))

        if not config_file.exists():
            self.logger.warning(f"Transition metadata file not found: {config_file}")
            return {}

        try:
            with open(config_file, 'r') as f:
                import json
                metadata = json.load(f)

                # Remove resolution parameters and ensure resolution comes only from config.json
                for shader_name, shader_data in metadata.items():
                    if 'resolution' in shader_data:
                        del shader_data['resolution']
                        self.logger.debug(f"Removed resolution parameter from {shader_name}")

                return metadata
        except Exception as e:
            self.logger.error(f"Failed to load transition metadata: {e}")
            return {}

    def calculate_transition_score(self, preference, status):
        """Calculate transition score based on preference and status."""
        preference_scores = {
            "Highly Desired": 1,
            "Mid": 2,
            "Low": 3
        }

        status_scores = {
            "Fully Working": 1,
            "Minor Adjustments": 2,
            "Broken": 3
        }

        pref_score = preference_scores.get(preference, 3)  # Default to Low if unknown
        stat_score = status_scores.get(status, 3)  # Default to Broken if unknown

        return pref_score + stat_score

    def group_transitions_by_score(self, transition_metadata):
        """Group transitions by their calculated scores."""
        score_groups = {}

        for shader_name, metadata in transition_metadata.items():
            preference = metadata.get('preference', 'Low')
            status = metadata.get('status', 'Broken')
            score = self.calculate_transition_score(preference, status)

            # Skip broken transitions (score = 6)
            if score == 6:
                continue

            if score not in score_groups:
                score_groups[score] = []
            score_groups[score].append(shader_name)

        return score_groups

    def is_score_group_exhausted(self, transitions_in_group, usage_count):
        """
        Check if a score group is exhausted (all transitions used equally).

        A score group is considered exhausted when we should move to the next
        priority tier. This happens when all transitions in the group have
        been used the same number of times.
        """
        if not transitions_in_group:
            return True

        # Get usage counts for all transitions in this group
        usage_counts = [usage_count.get(name, 0) for name in transitions_in_group]

        # If all transitions have the same usage count, the group is exhausted
        min_usage = min(usage_counts)
        max_usage = max(usage_counts)

        # Group is exhausted if all transitions have been used equally
        # and at least once (to ensure we don't skip unused groups)
        return min_usage == max_usage and min_usage > 0

    def load_transition_shader(self, transition_file, config_data):
        """Load and compile a transition shader with its configuration."""
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

    def select_transition_shader(self, transition_files, transition_usage_count, transition_history):
        """Select a transition shader using similar logic to main shader selection."""
        transitions_config = self.config.get('shader_settings', {}).get('transitions', {})
        randomization_config = transitions_config.get('randomization', {})

        # Use similar weighted selection as main shaders
        return self.select_next_shader(
            [f.name for f in transition_files],
            transition_usage_count,
            transition_history,
            min(randomization_config.get('history_size', 2), len(transition_files) - 1),
            randomization_config
        )

    def load_shader(self):
        """Load and compile the GLSL shader."""
        self.logger.info(f"Loading shader: {self.shader_path}")

        try:
            with open(self.shader_path, 'r') as f:
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
            self.logger.error(f"Failed to load shader: {e}")
            return None

    def render_fast(self, audio_data, duration):
        """Fast rendering using raw video data (no PNG files)."""
        self.logger.info("Starting fast render...")

        # Initialize OpenGL context
        self.ctx = moderngl.create_standalone_context()

        # Load shader
        program = self.load_shader()
        if program is None:
            return False

        # Get resolution
        width = self.config['output']['resolution']['width']
        height = self.config['output']['resolution']['height']
        resolution = (width, height)

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
        vao = self.ctx.simple_vertex_array(program, vbo, 'in_vert')

        # Create framebuffer
        fbo = self.ctx.simple_framebuffer(resolution)
        fbo.use()

        # Create temporary raw video file
        temp_video_file = Path(tempfile.mktemp(suffix='.raw'))

        try:
            total_frames = audio_data['total_frames']
            frame_rate = audio_data['frame_rate']

            with open(temp_video_file, 'wb') as raw_file:
                for frame_idx in range(total_frames):
                    # Calculate time
                    time_seconds = frame_idx / frame_rate

                    # Get audio values for this frame
                    bass_value = audio_data['bass'][frame_idx]
                    treble_value = audio_data['treble'][frame_idx]
                    waveform_data = audio_data['waveform'][frame_idx] if 'waveform' in audio_data else None
                    fft_spectrum = audio_data['fft_spectrum'][:, frame_idx] if 'fft_spectrum' in audio_data else None

                    # Create audio texture
                    audio_texture = self.create_audio_texture(bass_value, treble_value, waveform_data, fft_spectrum)
                    audio_texture.use(0)  # Bind to iChannel0

                    # Set uniforms
                    if 'iTime' in program:
                        program['iTime'].value = time_seconds
                    if 'iResolution' in program:
                        program['iResolution'].value = (float(width), float(height))
                    if 'iChannel0' in program:
                        program['iChannel0'].value = 0

                    # Clear and render
                    self.ctx.clear(0.0, 0.0, 0.0, 1.0)
                    vao.render()

                    # Read frame data directly as RGB bytes
                    data = fbo.read(components=3)

                    # Convert OpenGL data (bottom-up) to standard format (top-down)
                    frame_array = np.frombuffer(data, dtype=np.uint8).reshape((height, width, 3))
                    frame_array = np.flipud(frame_array)

                    # Write raw frame data to file
                    raw_file.write(frame_array.tobytes())

                    # Clean up texture
                    audio_texture.release()

                    # Progress update
                    if self.config['debug']['show_progress'] and frame_idx % 30 == 0:
                        progress = (frame_idx + 1) / total_frames * 100
                        self.logger.info(f"Rendered frame {frame_idx + 1}/{total_frames} ({progress:.1f}%)")

            # Now use FFmpeg to combine raw video with audio
            success = self.combine_raw_video_audio(temp_video_file, width, height, frame_rate, duration)

            # Cleanup raw file
            if temp_video_file.exists():
                temp_video_file.unlink()

            return success

        except Exception as e:
            self.logger.error(f"Fast render failed: {e}")
            if temp_video_file.exists():
                temp_video_file.unlink()
            return False

    def render_fast_multi_shader(self, audio_data, duration):
        """Fast rendering with dynamic shader cycling."""
        self.logger.info("Starting fast multi-shader render...")

        # Initialize OpenGL context
        self.ctx = moderngl.create_standalone_context()

        # Discover and pre-compile all shaders
        shader_files = self.discover_shaders()
        if not shader_files:
            return False

        compiled_shaders = self.precompile_shaders(shader_files)
        if not compiled_shaders:
            return False

        # Get resolution
        width = self.config['output']['resolution']['width']
        height = self.config['output']['resolution']['height']
        resolution = (width, height)

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

        # Create framebuffer
        fbo = self.ctx.simple_framebuffer(resolution)
        fbo.use()

        # Create temporary raw video file
        temp_video_file = Path(tempfile.mktemp(suffix='.raw'))

        try:
            total_frames = audio_data['total_frames']
            frame_rate = audio_data['frame_rate']

            # Shader cycling parameters - now using random durations
            base_switch_interval = self.config.get('shader_settings', {}).get('switch_interval', 10.0)  # seconds
            # Generate random duration between 10-25 seconds for first shader
            current_shader_duration = random.uniform(10.0, 25.0)
            frames_per_shader = int(current_shader_duration * frame_rate)
            next_switch_frame = frames_per_shader

            # Prepare shader list for cycling
            shader_names = list(compiled_shaders.keys())
            if len(shader_names) == 1:
                # Only one shader, use it for the entire duration
                current_shader_name = shader_names[0]
                self.logger.info(f"Using single shader: {current_shader_name}")
            else:
                # Multiple shaders, prepare for advanced cycling
                self.logger.info(f"Cycling through {len(shader_names)} shaders with random durations (10-25s)")
                self.logger.info(f"First shader duration: {current_shader_duration:.1f}s")

                # Initialize shader selection system with configuration
                randomization_config = self.config.get('shader_settings', {}).get('randomization', {})
                shader_usage_count = {name: 0 for name in shader_names}
                shader_history = []  # Track recent selections
                max_history = min(
                    randomization_config.get('history_size', 3),
                    len(shader_names) - 1
                )  # Avoid repeating recent shaders

            # Select initial shader randomly
            current_shader_name = random.choice(shader_names)
            current_shader_idx = shader_names.index(current_shader_name)
            current_program = compiled_shaders[current_shader_name]['program']
            current_vao = self.ctx.simple_vertex_array(current_program, vbo, 'in_vert')

            if len(shader_names) > 1:
                shader_usage_count[current_shader_name] += 1
                shader_history.append(current_shader_name)

            self.logger.info(f"Starting with shader: {current_shader_name}")

            with open(temp_video_file, 'wb') as raw_file:
                for frame_idx in range(total_frames):
                    # Check if we need to switch shaders (using random duration system)
                    if len(shader_names) > 1 and frame_idx > 0 and frame_idx >= next_switch_frame:
                        # Advanced shader selection algorithm
                        if len(shader_names) == 2:
                            # Alternate between two shaders
                            current_shader_idx = 1 - current_shader_idx
                            current_shader_name = shader_names[current_shader_idx]
                        else:
                            # Smart weighted random selection
                            current_shader_name = self.select_next_shader(
                                shader_names, shader_usage_count, shader_history,
                                max_history, randomization_config
                            )
                            current_shader_idx = shader_names.index(current_shader_name)

                            # Update tracking
                            shader_usage_count[current_shader_name] += 1
                            shader_history.append(current_shader_name)
                            if len(shader_history) > max_history:
                                shader_history.pop(0)

                        current_program = compiled_shaders[current_shader_name]['program']
                        current_vao = self.ctx.simple_vertex_array(current_program, vbo, 'in_vert')

                        # Generate new random duration for this shader (10-25 seconds)
                        current_shader_duration = random.uniform(10.0, 25.0)
                        frames_for_this_shader = int(current_shader_duration * frame_rate)
                        next_switch_frame = frame_idx + frames_for_this_shader

                        time_seconds = frame_idx / frame_rate
                        self.logger.info(f"Switched to shader: {current_shader_name} at {time_seconds:.1f}s (duration: {current_shader_duration:.1f}s)")

                    # Calculate time
                    time_seconds = frame_idx / frame_rate

                    # Get audio values for this frame
                    bass_value = audio_data['bass'][frame_idx]
                    treble_value = audio_data['treble'][frame_idx]
                    waveform_data = audio_data['waveform'][frame_idx] if 'waveform' in audio_data else None
                    fft_spectrum = audio_data['fft_spectrum'][:, frame_idx] if 'fft_spectrum' in audio_data else None

                    # Create audio texture
                    audio_texture = self.create_audio_texture(bass_value, treble_value, waveform_data, fft_spectrum)
                    audio_texture.use(0)  # Bind to iChannel0

                    # Set uniforms
                    if 'iTime' in current_program:
                        current_program['iTime'].value = time_seconds
                    if 'iResolution' in current_program:
                        current_program['iResolution'].value = (float(width), float(height))
                    if 'iChannel0' in current_program:
                        current_program['iChannel0'].value = 0

                    # Clear and render
                    self.ctx.clear(0.0, 0.0, 0.0, 1.0)
                    current_vao.render()

                    # Read frame data directly as RGB bytes
                    data = fbo.read(components=3)

                    # Convert OpenGL data (bottom-up) to standard format (top-down)
                    frame_array = np.frombuffer(data, dtype=np.uint8).reshape((height, width, 3))
                    frame_array = np.flipud(frame_array)

                    # Write raw frame data to file
                    raw_file.write(frame_array.tobytes())

                    # Clean up texture
                    audio_texture.release()

                    # Progress update
                    if self.config['debug']['show_progress'] and frame_idx % 30 == 0:
                        progress = (frame_idx + 1) / total_frames * 100
                        self.logger.info(f"Rendered frame {frame_idx + 1}/{total_frames} ({progress:.1f}%) - {current_shader_name}")

            # Now use FFmpeg to combine raw video with audio
            success = self.combine_raw_video_audio(temp_video_file, width, height, frame_rate, duration)

            # Cleanup raw file
            if temp_video_file.exists():
                temp_video_file.unlink()

            return success

        except Exception as e:
            self.logger.error(f"Multi-shader render failed: {e}")
            if temp_video_file.exists():
                temp_video_file.unlink()
            return False

    def combine_raw_video_audio(self, raw_video_file, width, height, frame_rate, duration):
        """Combine raw video data with audio using FFmpeg."""
        self.logger.info("Combining raw video and audio...")

        try:
            # FFmpeg command to combine raw video with audio
            cmd = [
                'ffmpeg',
                '-y',  # Overwrite output file
                '-f', 'rawvideo',
                '-vcodec', 'rawvideo',
                '-s', f'{width}x{height}',
                '-pix_fmt', 'rgb24',
                '-r', str(frame_rate),
                '-i', str(raw_video_file),  # Raw video input
                '-i', str(self.audio_path),  # Audio input
                '-c:v', 'libx264',
                '-crf', str(self.config['rendering']['quality']['crf']),
                '-preset', self.config['rendering']['quality']['preset'],
                '-pix_fmt', 'yuv420p',
                '-c:a', self.config['rendering']['audio']['codec'],
                '-b:a', self.config['rendering']['audio']['bitrate'],
                '-shortest',  # Stop when shortest input ends
            ]

            # Add duration limit if enabled
            if self.config['duration_override']['enabled']:
                cmd.extend(['-t', str(duration)])

            # Add output file
            cmd.append(str(self.output_path))

            # Add quiet flag if not verbose
            if not self.config['debug']['verbose_logging']:
                cmd.extend(['-loglevel', 'error'])

            # Run FFmpeg
            result = subprocess.run(cmd, capture_output=True, text=True)

            if result.returncode == 0:
                self.logger.info(f"Video created successfully: {self.output_path}")
                return True
            else:
                self.logger.error(f"FFmpeg failed with return code: {result.returncode}")
                if result.stderr:
                    self.logger.error(f"FFmpeg stderr: {result.stderr}")
                return False

        except Exception as e:
            self.logger.error(f"Raw video combination failed: {e}")
            return False

    def render_fast_multi_shader_with_transitions(self, audio_data, duration):
        """Fast rendering with dynamic shader cycling and smooth transitions."""
        self.logger.info("Starting fast multi-shader render with transitions...")

        # Initialize OpenGL context
        self.ctx = moderngl.create_standalone_context()

        # Discover and pre-compile all main shaders
        shader_files = self.discover_shaders()
        if not shader_files:
            return False

        compiled_shaders = self.precompile_shaders(shader_files)
        if not compiled_shaders:
            return False

        # Discover and load transition shaders
        transition_files = self.discover_transitions()
        transition_config_data = self.load_transition_config()
        compiled_transitions = {}

        if transition_files:
            self.logger.info("Pre-compiling transition shaders...")
            for transition_file in transition_files:
                transition_data = self.load_transition_shader(transition_file, transition_config_data)
                if transition_data:
                    compiled_transitions[transition_file.name] = transition_data
                    self.logger.info(f"✓ {transition_file.name} compiled successfully")
                else:
                    self.logger.warning(f"✗ Failed to compile {transition_file.name}")

        if not compiled_transitions:
            self.logger.warning("No transitions available, falling back to standard multi-shader mode")
            return self.render_fast_multi_shader(audio_data, duration)

        # Get configuration
        transitions_config = self.config.get('shader_settings', {}).get('transitions', {})
        transition_duration = transitions_config.get('duration', 1.6)

        # Continue with transition rendering implementation...
        self.logger.info(f"Transition system initialized: {len(compiled_transitions)} transitions, {transition_duration}s duration")

        # Now implement the full transition rendering pipeline
        return self.render_with_transitions(
            compiled_shaders, compiled_transitions, audio_data, duration,
            transition_duration, transitions_config
        )

    def render_with_transitions(self, compiled_shaders, compiled_transitions, audio_data, duration, transition_duration, transitions_config):
        """Render with smooth transitions between shaders."""
        self.logger.info("Starting transition-enabled multi-shader render...")

        # Get configuration
        width = self.config['output']['resolution']['width']
        height = self.config['output']['resolution']['height']
        resolution = (width, height)
        frame_rate = audio_data['frame_rate']
        total_frames = audio_data['total_frames']

        # Calculate timing - now using random durations
        base_switch_interval = self.config.get('shader_settings', {}).get('switch_interval', 10.0)
        transition_frames = int(transition_duration * frame_rate)

        # Generate random duration for first shader (10-25 seconds)
        current_shader_duration = random.uniform(10.0, 25.0)
        shader_segment_frames = int(current_shader_duration * frame_rate)

        # Adjust shader segments to account for transitions
        # Each shader plays for (random_duration - transition_duration) seconds
        pure_shader_duration = current_shader_duration - transition_duration
        pure_shader_frames = int(pure_shader_duration * frame_rate)

        self.logger.info(f"Using random shader durations (10-25s) with transitions")
        self.logger.info(f"First shader duration: {current_shader_duration:.1f}s (pure: {pure_shader_duration:.1f}s)")
        self.logger.info(f"Transitions: {transition_duration:.1f}s ({transition_frames} frames)")

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

        # Create framebuffers
        fbo = self.ctx.simple_framebuffer(resolution)
        fbo.use()

        # Create temporary raw video file
        temp_video_file = Path(tempfile.mktemp(suffix='.raw'))

        try:
            # Initialize shader selection system
            shader_names = list(compiled_shaders.keys())
            randomization_config = self.config.get('shader_settings', {}).get('randomization', {})
            shader_usage_count = {name: 0 for name in shader_names}
            shader_history = []
            max_history = min(randomization_config.get('history_size', 3), len(shader_names) - 1)

            # Initialize transition selection system with priority-based scoring
            transition_names = list(compiled_transitions.keys())
            transition_randomization_config = transitions_config.get('randomization', {})
            transition_usage_count = {name: 0 for name in transition_names}
            transition_history = []
            max_transition_history = min(transition_randomization_config.get('history_size', 2), len(transition_names) - 1)

            # Load transition metadata and calculate score distribution
            transition_metadata = self.load_transition_config()
            score_groups = self.group_transitions_by_score(transition_metadata)

            # Log transition selection configuration with scoring info
            score_summary = {score: len(shaders) for score, shaders in score_groups.items()}
            self.logger.info(f"Transition selection: {len(transition_names)} transitions, "
                           f"priority-based scoring enabled, "
                           f"history_size={max_transition_history}")
            self.logger.info(f"Score distribution: {score_summary} (lower scores = higher priority)")

            # Select initial shader
            current_shader_name = random.choice(shader_names)
            shader_usage_count[current_shader_name] += 1
            shader_history.append(current_shader_name)

            self.logger.info(f"Starting with shader: {current_shader_name}")

            # Initialize dynamic transition tracking
            next_transition_start = pure_shader_frames  # When to start first transition
            in_transition = False
            transition_frame = 0
            next_shader_name = None
            transition_name = None

            # Open raw video file for writing
            with open(temp_video_file, 'wb') as raw_file:
                frame_idx = 0

                while frame_idx < total_frames:
                    # Determine current phase: shader or transition (dynamic system)
                    if not in_transition and frame_idx >= next_transition_start:
                        # Start transition - select next shader and transition
                        in_transition = True
                        transition_frame = 0

                        next_shader_name = self.select_next_shader(
                            shader_names, shader_usage_count, shader_history,
                            max_history, randomization_config
                        )

                        transition_name = self.select_transition_shader(
                            transition_names, transition_usage_count, transition_history,
                            max_transition_history, transition_randomization_config
                        )

                        time_seconds = frame_idx / frame_rate
                        self.logger.info(f"Transition: {current_shader_name} → {next_shader_name} using {transition_name} at {time_seconds:.1f}s")

                    if in_transition:
                        # Render transition frame
                        progress = transition_frame / transition_frames
                        self.render_transition_frame(
                            compiled_shaders[current_shader_name],
                            compiled_shaders[next_shader_name],
                            compiled_transitions[transition_name],
                            vbo, fbo, audio_data, frame_idx, frame_rate,
                            progress, raw_file
                        )

                        transition_frame += 1

                        # Check if transition is complete
                        if transition_frame >= transition_frames:
                            # Transition complete - switch to next shader
                            in_transition = False
                            current_shader_name = next_shader_name

                            # Update tracking
                            shader_usage_count[next_shader_name] += 1
                            shader_history.append(next_shader_name)
                            if len(shader_history) > max_history:
                                shader_history.pop(0)

                            transition_usage_count[transition_name] += 1
                            transition_history.append(transition_name)
                            if len(transition_history) > max_transition_history:
                                transition_history.pop(0)

                            # Generate new random duration for next shader
                            new_shader_duration = random.uniform(10.0, 25.0)
                            new_pure_duration = new_shader_duration - transition_duration
                            new_pure_frames = int(new_pure_duration * frame_rate)
                            next_transition_start = frame_idx + new_pure_frames

                            time_seconds = frame_idx / frame_rate
                            self.logger.info(f"Switched to {current_shader_name}, next duration: {new_shader_duration:.1f}s")

                    else:
                        # Pure shader phase
                        self.render_shader_frame(
                            compiled_shaders[current_shader_name], vbo, fbo,
                            audio_data, frame_idx, frame_rate, raw_file
                        )

                    frame_idx += 1

                    # Progress update
                    if self.config['debug']['show_progress'] and frame_idx % 30 == 0:
                        progress = frame_idx / total_frames * 100
                        self.logger.info(f"Rendered frame {frame_idx}/{total_frames} ({progress:.1f}%)")

            # Log final usage statistics
            self.logger.info("=== FINAL USAGE STATISTICS ===")
            self.logger.info("Shader usage:")
            for name, count in sorted(shader_usage_count.items()):
                self.logger.info(f"  {name}: {count} times")

            self.logger.info("Transition usage:")
            for name, count in sorted(transition_usage_count.items()):
                if count > 0:  # Only show used transitions
                    self.logger.info(f"  {name}: {count} times")

            total_transitions = sum(transition_usage_count.values())
            if total_transitions > 0:
                self.logger.info(f"Total transitions used: {total_transitions}")
                used_transitions = sum(1 for count in transition_usage_count.values() if count > 0)
                self.logger.info(f"Unique transitions used: {used_transitions}/{len(transition_names)}")

            # Combine raw video with audio
            success = self.combine_raw_video_audio(temp_video_file, width, height, frame_rate, duration)

            # Cleanup
            if temp_video_file.exists():
                temp_video_file.unlink()

            return success

        except Exception as e:
            self.logger.error(f"Transition render failed: {e}")
            if temp_video_file.exists():
                temp_video_file.unlink()
            return False

    def render_shader_frame(self, shader_data, vbo, fbo, audio_data, frame_idx, frame_rate, raw_file):
        """Render a single frame using a shader."""
        program = shader_data['program']
        vao = self.ctx.simple_vertex_array(program, vbo, 'in_vert')

        # Set uniforms
        time_seconds = frame_idx / frame_rate
        program['iTime'].value = time_seconds
        program['iResolution'].value = (fbo.width, fbo.height)

        # Create and bind audio texture
        audio_frame_idx = min(frame_idx, len(audio_data['bass']) - 1)
        bass_value = audio_data['bass'][audio_frame_idx]
        treble_value = audio_data['treble'][audio_frame_idx]
        waveform_data = audio_data['waveform'][audio_frame_idx] if 'waveform' in audio_data else None
        fft_spectrum = audio_data['fft_spectrum'][:, audio_frame_idx] if 'fft_spectrum' in audio_data else None
        audio_texture = self.create_audio_texture(bass_value, treble_value, waveform_data, fft_spectrum)
        audio_texture.use(location=0)
        if 'iChannel0' in program:
            program['iChannel0'].value = 0

        # Clear and render
        self.ctx.clear(0.0, 0.0, 0.0, 1.0)
        vao.render()

        # Read frame data and write to raw file
        data = fbo.read(components=3)
        raw_file.write(data)

        # Cleanup
        audio_texture.release()

    def render_transition_frame(self, from_shader_data, to_shader_data, transition_data,
                              vbo, fbo, audio_data, frame_idx, frame_rate, progress, raw_file):
        """Render a transition frame blending two shaders."""
        # Create temporary textures and framebuffers for each shader
        temp_texture_from = self.ctx.texture((fbo.width, fbo.height), 3)
        temp_texture_to = self.ctx.texture((fbo.width, fbo.height), 3)
        temp_fbo_from = self.ctx.framebuffer(color_attachments=[temp_texture_from])
        temp_fbo_to = self.ctx.framebuffer(color_attachments=[temp_texture_to])

        time_seconds = frame_idx / frame_rate
        audio_frame_idx = min(frame_idx, len(audio_data['bass']) - 1)
        bass_value = audio_data['bass'][audio_frame_idx]
        treble_value = audio_data['treble'][audio_frame_idx]
        waveform_data = audio_data['waveform'][audio_frame_idx] if 'waveform' in audio_data else None
        fft_spectrum = audio_data['fft_spectrum'][:, audio_frame_idx] if 'fft_spectrum' in audio_data else None
        audio_texture = self.create_audio_texture(bass_value, treble_value, waveform_data, fft_spectrum)
        audio_texture.use(location=0)

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

        # Apply shader-specific configuration
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

        # Clear and render transition
        self.ctx.clear(0.0, 0.0, 0.0, 1.0)
        transition_vao.render()

        # Read frame data and write to raw file
        data = fbo.read(components=3)
        raw_file.write(data)

        # Cleanup
        audio_texture.release()
        temp_texture_from.release()
        temp_texture_to.release()
        temp_fbo_from.release()
        temp_fbo_to.release()

    def select_transition_shader(self, transition_names, usage_count, history, max_history, config):
        """
        Select a transition shader using priority-based scoring system.

        Uses preference + status scoring with weighted priority:
        - Score 2: Highly Desired + Fully Working (highest priority)
        - Score 3: Highly Desired + Minor Adjustments OR Mid + Fully Working
        - Score 4: Highly Desired + Broken OR Mid + Minor Adjustments OR Low + Fully Working
        - Score 5: Mid + Broken OR Low + Minor Adjustments
        - Score 6: Low + Broken (excluded - never used)
        """
        # Load transition metadata for scoring
        transition_metadata = self.load_transition_config()

        # Group transitions by score
        score_groups = self.group_transitions_by_score(transition_metadata)

        # Log current transition usage for debugging
        if self.config['debug']['verbose_logging']:
            usage_summary = {name: count for name, count in usage_count.items()}
            self.logger.debug(f"Transition usage before selection: {usage_summary}")
            self.logger.debug(f"Transition history: {history}")
            self.logger.debug(f"Score groups: {[(score, len(shaders)) for score, shaders in score_groups.items()]}")

        # Select transition using priority-based system
        selected = self.select_transition_by_priority(score_groups, usage_count, history, max_history)

        if self.config['debug']['verbose_logging']:
            if selected in transition_metadata:
                metadata = transition_metadata[selected]
                preference = metadata.get('preference', 'Unknown')
                status = metadata.get('status', 'Unknown')
                score = self.calculate_transition_score(preference, status)
                self.logger.debug(f"Selected transition: {selected} (Score: {score}, {preference} + {status})")
            else:
                self.logger.debug(f"Selected transition: {selected}")

        return selected

    def select_transition_by_priority(self, score_groups, usage_count, history, max_history):
        """
        Select transition using priority-based system with scoring.

        Priority order: Score 2 → 3 → 4 → 5 (skip score 6 - broken)
        Within each score group, exhaust all transitions before moving to next group.
        """
        # Process score groups in priority order (2, 3, 4, 5)
        for score in sorted(score_groups.keys()):
            if score == 6:  # Skip broken transitions
                continue

            available_transitions = score_groups[score]

            # Check if this score group is exhausted (all transitions used equally)
            if self.is_score_group_exhausted(available_transitions, usage_count):
                continue  # Move to next score group

            # Filter out transitions that are in recent history
            if history and max_history > 0:
                recent_history = history[-max_history:]
                filtered_transitions = [
                    name for name in available_transitions
                    if name not in recent_history
                ]
            else:
                filtered_transitions = available_transitions

            # If no transitions available after filtering, use all from this score group
            if not filtered_transitions:
                filtered_transitions = available_transitions

            # Find the minimum usage count in this score group
            min_usage_in_group = min(usage_count.get(name, 0) for name in available_transitions)

            # Find transitions with minimum usage in this score group
            least_used_in_group = [
                name for name in filtered_transitions
                if usage_count.get(name, 0) == min_usage_in_group
            ]

            # If we found candidates, select one
            if least_used_in_group:
                import random
                selected = random.choice(least_used_in_group)
                if self.config['debug']['verbose_logging']:
                    self.logger.debug(f"Selected transition from score {score}: {selected} (usage: {min_usage_in_group})")
                return selected

        # Fallback: if no transitions available, select from all available
        if score_groups:
            all_available = []
            for score, transitions in score_groups.items():
                if score != 6:  # Skip broken
                    all_available.extend(transitions)

            if all_available:
                import random
                selected = random.choice(all_available)
                if self.config['debug']['verbose_logging']:
                    self.logger.debug(f"Fallback selection: {selected}")
                return selected

        # Ultimate fallback: return first available transition name
        if hasattr(self, 'transition_names') and self.transition_names:
            return self.transition_names[0]

        return None

    def render_frames_legacy(self, audio_data):
        """Legacy frame-by-frame rendering (saves PNG files to disk)."""
        self.logger.info("Starting legacy frame rendering...")

        # Initialize OpenGL context
        self.ctx = moderngl.create_standalone_context()

        # Load shader
        program = self.load_shader()
        if program is None:
            return None

        # Get resolution
        width = self.config['output']['resolution']['width']
        height = self.config['output']['resolution']['height']
        resolution = (width, height)

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
        vao = self.ctx.simple_vertex_array(program, vbo, 'in_vert')

        # Create framebuffer
        fbo = self.ctx.simple_framebuffer(resolution)
        fbo.use()

        # Create temporary directory for frames
        temp_dir = Path(tempfile.mkdtemp())

        try:
            total_frames = audio_data['total_frames']
            frame_rate = audio_data['frame_rate']

            for frame_idx in range(total_frames):
                # Calculate time
                time_seconds = frame_idx / frame_rate

                # Get audio values for this frame
                bass_value = audio_data['bass'][frame_idx]
                treble_value = audio_data['treble'][frame_idx]
                waveform_data = audio_data['waveform'][frame_idx] if 'waveform' in audio_data else None
                fft_spectrum = audio_data['fft_spectrum'][:, frame_idx] if 'fft_spectrum' in audio_data else None

                # Create audio texture
                audio_texture = self.create_audio_texture(bass_value, treble_value, waveform_data, fft_spectrum)
                audio_texture.use(0)  # Bind to iChannel0

                # Set uniforms
                if 'iTime' in program:
                    program['iTime'].value = time_seconds
                if 'iResolution' in program:
                    program['iResolution'].value = (float(width), float(height))
                if 'iChannel0' in program:
                    program['iChannel0'].value = 0

                # Clear and render
                self.ctx.clear(0.0, 0.0, 0.0, 1.0)
                vao.render()

                # Read frame data
                data = fbo.read(components=3)
                img = Image.frombytes('RGB', resolution, data)
                img = img.transpose(Image.FLIP_TOP_BOTTOM)  # Fix OpenGL coordinate system

                # Save frame
                frame_path = temp_dir / f"frame_{frame_idx:05d}.png"
                img.save(frame_path)

                # Clean up texture
                audio_texture.release()

                # Progress update
                if self.config['debug']['show_progress'] and frame_idx % 30 == 0:
                    progress = (frame_idx + 1) / total_frames * 100
                    self.logger.info(f"Rendered frame {frame_idx + 1}/{total_frames} ({progress:.1f}%)")

            self.logger.info(f"Rendered {total_frames} frames to {temp_dir}")
            return temp_dir

        except Exception as e:
            self.logger.error(f"Frame rendering failed: {e}")
            return None

    def combine_video_audio(self, frames_dir, duration):
        """Combine rendered frames with audio using FFmpeg."""
        self.logger.info("Combining video and audio...")

        try:
            frame_rate = self.config['output']['frame_rate']

            # Build FFmpeg command
            input_pattern = str(frames_dir / "frame_%05d.png")

            # Create video stream from frames
            video_stream = ffmpeg.input(input_pattern, framerate=frame_rate)

            # Create audio stream
            audio_stream = ffmpeg.input(str(self.audio_path))

            # Output settings
            output_args = {
                'vcodec': 'libx264',
                'crf': self.config['rendering']['quality']['crf'],
                'preset': self.config['rendering']['quality']['preset'],
                'pix_fmt': 'yuv420p',
                'acodec': self.config['rendering']['audio']['codec'],
                'audio_bitrate': self.config['rendering']['audio']['bitrate']
            }

            # Add duration limit if enabled
            if self.config['duration_override']['enabled']:
                output_args['t'] = duration

            # Create output
            output = ffmpeg.output(
                video_stream, audio_stream,
                str(self.output_path),
                **output_args
            )

            # Run FFmpeg
            ffmpeg.run(output, overwrite_output=True, quiet=not self.config['debug']['verbose_logging'])

            self.logger.info(f"Video created successfully: {self.output_path}")
            return True

        except Exception as e:
            self.logger.error(f"Video combination failed: {e}")
            return False

    def render_audio_file(self, audio_file):
        """Render a single audio file to video."""
        self.logger.info(f"=== Processing: {audio_file.name} ===")

        # Set current audio file
        self.audio_path = audio_file
        self.output_path = self.generate_output_path(audio_file)

        # Check if output already exists
        if self.output_path.exists() and not self.config.get('batch_settings', {}).get('overwrite_existing', False):
            self.logger.info(f"Output already exists, skipping: {self.output_path}")
            return True

        # Validate audio file
        if not self.audio_path.exists():
            self.logger.error(f"Audio file not found: {self.audio_path}")
            return False

        try:
            # Get render duration
            duration = self.get_render_duration()
            if duration is None:
                self.logger.error("Failed to determine render duration")
                return False

            self.logger.info(f"Rendering {duration:.2f} seconds to: {self.output_path}")

            # Analyze audio
            audio_data = self.analyze_audio(duration)
            if audio_data is None:
                return False

            # Choose rendering method based on configuration
            use_fast_mode = self.config.get('rendering', {}).get('streaming', True)
            use_multi_shader = self.config.get('shader_settings', {}).get('multi_shader', False)

            if use_fast_mode:
                if use_multi_shader:
                    # Check if transitions are enabled
                    transitions_enabled = self.config.get('shader_settings', {}).get('transitions', {}).get('enabled', False)
                    if transitions_enabled:
                        # Use multi-shader cycling mode with transitions
                        self.logger.info("Using fast multi-shader render mode with transitions")
                        success = self.render_fast_multi_shader_with_transitions(audio_data, duration)
                    else:
                        # Use standard multi-shader cycling mode
                        self.logger.info("Using fast multi-shader render mode")
                        success = self.render_fast_multi_shader(audio_data, duration)
                else:
                    # Use single shader fast mode
                    self.logger.info("Using fast render mode")
                    success = self.render_fast(audio_data, duration)
            else:
                # Legacy frame-by-frame approach (slower, more memory)
                self.logger.info("Using frame-by-frame render mode")
                frames_dir = self.render_frames_legacy(audio_data)
                if frames_dir is None:
                    return False

                success = self.combine_video_audio(frames_dir, duration)
                self.cleanup_temp_files(frames_dir)

            if success:
                self.logger.info(f"✓ Successfully rendered: {self.output_path}")
                return True
            else:
                self.logger.error(f"✗ Failed to render: {audio_file.name}")
                return False

        except Exception as e:
            self.logger.error(f"Error processing {audio_file.name}: {e}")
            return False

    def batch_render(self):
        """Render videos for all discovered audio files."""
        self.logger.info("=== Starting Batch Render Mode ===")

        # Discover audio files
        audio_files = self.discover_audio_files()
        if not audio_files:
            self.logger.error("No audio files found for batch processing")
            return False

        # Track results
        successful_renders = 0
        failed_renders = 0
        skipped_renders = 0

        start_time = time.time()

        for i, audio_file in enumerate(audio_files, 1):
            self.logger.info(f"\n--- Processing {i}/{len(audio_files)}: {audio_file.name} ---")

            # Check if output already exists
            output_path = self.generate_output_path(audio_file)
            if output_path.exists() and not self.config.get('batch_settings', {}).get('overwrite_existing', False):
                self.logger.info(f"Output already exists, skipping: {output_path}")
                skipped_renders += 1
                continue

            # Render the audio file
            success = self.render_audio_file(audio_file)

            if success:
                successful_renders += 1
            else:
                failed_renders += 1

        # Summary
        total_time = time.time() - start_time
        self.logger.info(f"\n=== Batch Render Complete ===")
        self.logger.info(f"Total time: {total_time:.1f} seconds")
        self.logger.info(f"Successful: {successful_renders}")
        self.logger.info(f"Failed: {failed_renders}")
        self.logger.info(f"Skipped: {skipped_renders}")
        self.logger.info(f"Total processed: {len(audio_files)}")

        return successful_renders > 0

    def cleanup_temp_files(self, temp_dir):
        """Clean up temporary files."""
        if temp_dir and temp_dir.exists():
            if not self.config['debug']['save_frames']:
                shutil.rmtree(temp_dir)
                self.logger.info("Temporary frames cleaned up")
            else:
                self.logger.info(f"Frames saved in: {temp_dir}")

    def run(self):
        """Main rendering pipeline - supports both single file and batch modes."""
        self.logger.info("=== OneOffRender Starting ===")

        # Check if batch mode is enabled
        batch_mode = self.config.get('batch_settings', {}).get('enabled', False)
        self.logger.info(f"Batch mode: {batch_mode}")

        if batch_mode:
            # Batch mode: process all audio files in Input_Audio folder
            self.logger.info("Entering batch render mode")
            return self.batch_render()
        else:
            # Single file mode: use audio file specified in config
            self.logger.info("Entering single file render mode")
            return self.render_single_file()

    def render_single_shader_file(self, shader_path, audio_path, output_path):
        """Render a single shader with specified paths (for oneoff.py)."""
        self.logger.info("=== Single Shader Render Mode ===")

        start_time = time.time()

        try:
            self.logger.info(f"Shader: {shader_path}")
            self.logger.info(f"Audio: {audio_path}")
            self.logger.info(f"Output: {output_path}")

            # Override the paths temporarily
            original_shader_path = self.shader_path
            original_audio_path = self.audio_path
            original_output_path = self.output_path

            self.shader_path = shader_path
            self.audio_path = audio_path
            self.output_path = output_path

            # Get render duration
            duration_seconds = self.get_render_duration()
            self.logger.info(f"Render duration: {duration_seconds:.2f} seconds")

            # Analyze audio
            self.logger.info("Analyzing audio for reactivity...")
            audio_data = self.analyze_audio(duration_seconds)

            if not audio_data:
                self.logger.error("Failed to analyze audio")
                return False

            self.logger.info(f"Audio: {duration_seconds:.2f}s, {audio_data['frame_rate']}fps, {len(audio_data['bass'])} frames")

            # Single shader rendering (no transitions)
            success = self.render_single_shader_video(shader_path, audio_data, output_path)

            # Restore original paths
            self.shader_path = original_shader_path
            self.audio_path = original_audio_path
            self.output_path = original_output_path

            if success:
                end_time = time.time()
                total_time = end_time - start_time
                self.logger.info(f"=== Rendering completed in {total_time:.1f} seconds ===")
                return True
            else:
                self.logger.error("Rendering failed")
                return False

        except Exception as e:
            self.logger.error(f"Error in single shader render: {e}")
            import traceback
            self.logger.error(f"Traceback: {traceback.format_exc()}")
            return False

    def render_single_shader_video(self, shader_path, audio_data, output_path):
        """Render video using a single shader without transitions."""
        try:
            # Initialize OpenGL context
            self.ctx = moderngl.create_standalone_context()

            # Load and compile the shader
            program = self.load_shader_from_file(Path(shader_path))
            if program is None:
                self.logger.error(f"Failed to compile shader: {shader_path}")
                return False

            self.logger.info(f"✓ Shader compiled successfully: {Path(shader_path).name}")

            # Setup rendering
            width = self.config['output']['resolution']['width']
            height = self.config['output']['resolution']['height']
            frame_rate = self.config['output']['frame_rate']

            total_frames = len(audio_data['bass'])

            # Create vertex buffer for full-screen quad
            vertices = np.array([
                -1.0, -1.0,
                 1.0, -1.0,
                -1.0,  1.0,
                -1.0,  1.0,
                 1.0, -1.0,
                 1.0,  1.0,
            ], dtype=np.float32)

            # Create framebuffer and vertex buffer
            fbo = self.ctx.framebuffer(self.ctx.renderbuffer((width, height), 3))
            vbo = self.ctx.buffer(vertices.tobytes())
            vao = self.ctx.simple_vertex_array(program, vbo, 'in_vert')

            # Setup raw video file
            raw_file_path = output_path.replace('.mp4', '_raw.yuv')

            self.logger.info("Starting single shader render...")

            with open(raw_file_path, 'wb') as raw_file:
                for frame_idx in range(total_frames):
                    # Calculate time and audio values
                    time_seconds = frame_idx / frame_rate
                    audio_frame_idx = min(frame_idx, len(audio_data['bass']) - 1)
                    bass_value = audio_data['bass'][audio_frame_idx]
                    treble_value = audio_data['treble'][audio_frame_idx]
                    waveform_data = audio_data['waveform'][audio_frame_idx] if 'waveform' in audio_data else None
                    fft_spectrum = audio_data['fft_spectrum'][:, audio_frame_idx] if 'fft_spectrum' in audio_data else None

                    # Create audio texture
                    audio_texture = self.create_audio_texture(bass_value, treble_value, waveform_data, fft_spectrum)
                    audio_texture.use(location=0)

                    # Set uniforms
                    if 'iTime' in program:
                        program['iTime'].value = time_seconds
                    if 'iResolution' in program:
                        program['iResolution'].value = (float(width), float(height))
                    if 'iChannel0' in program:
                        program['iChannel0'].value = 0

                    # Render frame
                    fbo.use()
                    self.ctx.clear(0.0, 0.0, 0.0, 1.0)
                    vao.render()

                    # Read frame data
                    data = fbo.read(components=3)
                    raw_file.write(data)

                    # Progress logging
                    if (frame_idx + 1) % 30 == 0 or frame_idx == total_frames - 1:
                        progress = (frame_idx + 1) / total_frames * 100
                        self.logger.info(f"Rendered frame {frame_idx + 1}/{total_frames} ({progress:.1f}%)")

                    # Cleanup
                    audio_texture.release()

            # Cleanup rendering resources
            vao.release()
            vbo.release()
            fbo.release()
            program.release()

            # Combine with audio using FFmpeg
            duration_seconds = len(audio_data['bass']) / audio_data['frame_rate']
            success = self.combine_raw_video_audio(raw_file_path, width, height, frame_rate, duration_seconds)

            # Cleanup raw file
            try:
                os.remove(raw_file_path)
            except:
                pass

            return success

        except Exception as e:
            self.logger.error(f"Error in single shader video rendering: {e}")
            import traceback
            self.logger.error(f"Traceback: {traceback.format_exc()}")
            return False

    def render_single_file(self):
        """Render a single file specified in configuration."""
        self.logger.info("=== Single File Render Mode ===")

        start_time = time.time()

        try:
            self.logger.info(f"Shader: {self.shader_path}")
            self.logger.info(f"Audio: {self.audio_path}")
            self.logger.info(f"Output: {self.output_path}")

            # Get render duration
            duration = self.get_render_duration()
            if duration is None:
                return False

            self.logger.info(f"Render duration: {duration:.2f} seconds")

            # Analyze audio
            audio_data = self.analyze_audio(duration)
            if audio_data is None:
                return False

            # Choose rendering method based on configuration
            use_fast_mode = self.config.get('rendering', {}).get('streaming', True)
            use_multi_shader = self.config.get('shader_settings', {}).get('multi_shader', False)

            if use_fast_mode:
                if use_multi_shader:
                    # Check if transitions are enabled
                    transitions_enabled = self.config.get('shader_settings', {}).get('transitions', {}).get('enabled', False)
                    if transitions_enabled:
                        # Use multi-shader cycling mode with transitions
                        self.logger.info("Using fast multi-shader render mode with transitions")
                        success = self.render_fast_multi_shader_with_transitions(audio_data, duration)
                    else:
                        # Use standard multi-shader cycling mode
                        self.logger.info("Using fast multi-shader render mode")
                        success = self.render_fast_multi_shader(audio_data, duration)
                else:
                    # Use single shader fast mode
                    self.logger.info("Using fast render mode")
                    success = self.render_fast(audio_data, duration)
            else:
                # Legacy frame-by-frame approach (slower, more memory)
                self.logger.info("Using frame-by-frame render mode")
                frames_dir = self.render_frames_legacy(audio_data)
                if frames_dir is None:
                    return False

                success = self.combine_video_audio(frames_dir, duration)
                self.cleanup_temp_files(frames_dir)

            if success:
                elapsed = time.time() - start_time
                self.logger.info(f"=== Rendering completed in {elapsed:.1f} seconds ===")
                return True
            else:
                return False

        except Exception as e:
            self.logger.error(f"Rendering failed: {e}")
            return False


def main():
    """Main entry point."""
    try:
        # Check for command line argument
        config_file = "config.json"
        if len(sys.argv) > 1:
            config_file = sys.argv[1]

        renderer = ShaderRenderer(config_file)
        success = renderer.run()
        sys.exit(0 if success else 1)
    except Exception as e:
        print(f"Fatal error: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
