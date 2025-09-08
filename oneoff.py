#!/usr/bin/env python3
"""
OneOff Single Shader Renderer
Renders a single shader with audio reactivity for a specified duration.

Usage: python oneoff.py <shader_name> <duration>
Examples:
  python oneoff.py "sleeplessV3.glsl" 30
  python oneoff.py "Cosmic Nebula2.glsl" 01:30
"""

import sys
import os
import json
import time
from pathlib import Path
import logging

# Import the main renderer
from render_shader import ShaderRenderer

def parse_duration(duration_str):
    """Parse duration string into seconds. Supports '30' or '01:30' format."""
    try:
        # Try parsing as plain seconds first
        if ':' not in duration_str:
            return float(duration_str)
        
        # Parse MM:SS format
        parts = duration_str.split(':')
        if len(parts) == 2:
            minutes = int(parts[0])
            seconds = float(parts[1])
            return minutes * 60 + seconds
        else:
            raise ValueError("Invalid time format")
    except (ValueError, IndexError):
        raise ValueError(f"Invalid duration format: '{duration_str}'. Use seconds (e.g., '30') or MM:SS (e.g., '01:30')")

def find_shader_file(shader_name, shaders_dir="Shaders"):
    """Find the shader file, handling both exact names and names without extension."""
    shaders_path = Path(shaders_dir)
    
    # Try exact match first
    exact_path = shaders_path / shader_name
    if exact_path.exists():
        return exact_path
    
    # Try adding .glsl extension if not present
    if not shader_name.endswith('.glsl'):
        with_ext_path = shaders_path / f"{shader_name}.glsl"
        if with_ext_path.exists():
            return with_ext_path
    
    # List available shaders for error message
    available_shaders = []
    if shaders_path.exists():
        available_shaders = [f.name for f in shaders_path.glob("*.glsl")]
    
    raise FileNotFoundError(f"Shader '{shader_name}' not found in {shaders_dir}/\n"
                          f"Available shaders: {', '.join(available_shaders)}")

def find_audio_file(audio_dir="Input_Audio"):
    """Find the first audio file in the audio directory."""
    audio_path = Path(audio_dir)
    if not audio_path.exists():
        raise FileNotFoundError(f"Audio directory '{audio_dir}' not found")
    
    # Supported audio formats
    audio_extensions = ['.mp3', '.wav', '.flac', '.m4a', '.aac', '.ogg', '.wma']
    
    for ext in audio_extensions:
        audio_files = list(audio_path.glob(f"*{ext}"))
        if audio_files:
            return audio_files[0]
    
    raise FileNotFoundError(f"No supported audio files found in {audio_dir}/\n"
                          f"Supported formats: {', '.join(audio_extensions)}")

def create_single_shader_config(base_config, duration_seconds, shader_path, audio_path, output_path):
    """Create a modified config for single shader rendering."""
    config = base_config.copy()

    # Add input section for single file mode
    config['input'] = {
        'shader_file': str(shader_path),
        'audio_file': str(audio_path)
    }

    # Update output path
    config['output']['video_file'] = str(output_path)

    # Disable multi-shader system
    if 'shader_settings' not in config:
        config['shader_settings'] = {}
    config['shader_settings']['multi_shader'] = False

    # Disable transitions
    if 'transitions' not in config['shader_settings']:
        config['shader_settings']['transitions'] = {}
    config['shader_settings']['transitions']['enabled'] = False

    # Set duration override
    minutes = int(duration_seconds // 60)
    seconds = int(duration_seconds % 60)
    duration_str = f"{minutes:02d}:{seconds:02d}"

    config['duration_override'] = {
        'enabled': True,
        'cutoff_time': duration_str
    }

    # Disable batch processing
    if 'batch_settings' not in config:
        config['batch_settings'] = {}
    config['batch_settings']['enabled'] = False

    return config

def main():
    """Main function for single shader rendering."""
    try:
        # Check command line arguments
        if len(sys.argv) != 3:
            print("OneOff Single Shader Renderer")
            print("Usage: python oneoff.py <shader_name> <duration>")
            print()
            print("Parameters:")
            print("  shader_name  - Name of the shader file (with or without .glsl extension)")
            print("  duration     - Duration in seconds (30) or MM:SS format (01:30)")
            print()
            print("Examples:")
            print("  python oneoff.py sleeplessV3.glsl 30")
            print("  python oneoff.py \"Cosmic Nebula2.glsl\" 01:30")
            print("  python oneoff.py MoltenHeart 45")
            sys.exit(1)
    except Exception as e:
        print(f"Error in argument parsing: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
    
    shader_name = sys.argv[1]
    duration_str = sys.argv[2]
    
    try:
        # Parse and validate inputs
        print("OneOff Single Shader Renderer")
        print("=" * 40)
        
        # Parse duration
        duration_seconds = parse_duration(duration_str)
        print(f"Duration: {duration_seconds} seconds")
        
        # Find shader file
        shader_path = find_shader_file(shader_name)
        print(f"Shader: {shader_path}")
        
        # Find audio file
        audio_path = find_audio_file()
        print(f"Audio: {audio_path}")
        
        # Generate output filename
        shader_stem = shader_path.stem  # filename without extension
        duration_suffix = f"{int(duration_seconds)}s"
        output_filename = f"{shader_stem}_{duration_suffix}.mp4"
        output_path = Path("Output_Video") / output_filename

        # Ensure output directory exists
        output_path.parent.mkdir(exist_ok=True)

        print(f"Output: {output_path}")
        print()

        # Load base configuration
        config_path = Path("config.json")
        if not config_path.exists():
            raise FileNotFoundError("config.json not found")

        with open(config_path, 'r') as f:
            base_config = json.load(f)

        # Create single shader config with all required paths
        config = create_single_shader_config(base_config, duration_seconds, shader_path, audio_path, output_path)

        # Write temporary config file
        temp_config_path = "oneoff_temp_config.json"
        with open(temp_config_path, 'w') as f:
            json.dump(config, f, indent=2)

        # Initialize renderer with temporary config
        renderer = ShaderRenderer(temp_config_path)

        # Start rendering
        print("Starting single shader render...")
        start_time = time.time()

        try:
            # Use the single file rendering method but force single shader mode
            success = renderer.render_single_shader_file(
                str(shader_path),
                str(audio_path),
                str(output_path)
            )
        except Exception as e:
            print(f"Error during rendering: {e}")
            import traceback
            traceback.print_exc()
            success = False

        end_time = time.time()
        render_time = end_time - start_time

        if success:
            print(f"\n✓ Rendering completed successfully in {render_time:.1f} seconds")
            print(f"✓ Output saved to: {output_path}")
        else:
            print(f"\n✗ Rendering failed")
            sys.exit(1)

    except Exception as e:
        print(f"\n✗ Error: {e}")
        sys.exit(1)
    finally:
        # Clean up temporary config file
        try:
            if 'temp_config_path' in locals():
                os.remove(temp_config_path)
        except:
            pass

if __name__ == "__main__":
    main()
