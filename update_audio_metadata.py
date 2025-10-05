#!/usr/bin/env python3
"""
Update Shader Metadata with Audio-Reactive Detection

Scans all .glsl shader files in the Shaders/ directory and updates metadata.json
to include an "audio_reactive" field based on whether the shader uses iChannel0.
"""

import json
import re
from pathlib import Path


def detect_audio_reactive(shader_path):
    """
    Detect if a shader is audio-reactive by checking for iChannel0 usage.
    
    Args:
        shader_path: Path to the .glsl shader file
        
    Returns:
        bool: True if shader uses iChannel0 (audio-reactive), False otherwise
    """
    try:
        with open(shader_path, 'r', encoding='utf-8') as f:
            content = f.read()
            
        # Search for iChannel0 in the shader code
        # Use word boundary to avoid matching iChannel01, iChannel0x, etc.
        pattern = r'\biChannel0\b'
        return bool(re.search(pattern, content))
        
    except Exception as e:
        print(f"Warning: Could not read {shader_path}: {e}")
        return False


def update_metadata():
    """
    Update Shaders/metadata.json with audio_reactive field for all shaders.
    """
    shaders_dir = Path("Shaders")
    metadata_path = shaders_dir / "metadata.json"
    
    if not metadata_path.exists():
        print(f"Error: {metadata_path} not found!")
        return
    
    # Load existing metadata
    print(f"Loading metadata from {metadata_path}...")
    with open(metadata_path, 'r', encoding='utf-8') as f:
        metadata = json.load(f)
    
    print(f"Found {len(metadata)} shader entries in metadata.json")
    
    # Track statistics
    audio_reactive_count = 0
    updated_count = 0
    
    # Update each shader entry
    for shader_entry in metadata:
        shader_name = shader_entry.get('name')
        if not shader_name:
            print(f"Warning: Shader entry missing 'name' field: {shader_entry}")
            continue
        
        shader_path = shaders_dir / shader_name
        
        if not shader_path.exists():
            print(f"Warning: Shader file not found: {shader_path}")
            # Set to false if file doesn't exist
            shader_entry['audio_reactive'] = False
            continue
        
        # Detect audio reactivity
        is_audio_reactive = detect_audio_reactive(shader_path)
        
        # Update metadata entry
        old_value = shader_entry.get('audio_reactive')
        shader_entry['audio_reactive'] = is_audio_reactive
        
        if old_value != is_audio_reactive:
            updated_count += 1
            status = "✓ AUDIO-REACTIVE" if is_audio_reactive else "  non-reactive"
            print(f"  {status}: {shader_name}")
        
        if is_audio_reactive:
            audio_reactive_count += 1
    
    # Save updated metadata
    print(f"\nSaving updated metadata to {metadata_path}...")
    with open(metadata_path, 'w', encoding='utf-8') as f:
        json.dump(metadata, f, indent=2)
    
    # Print summary
    print("\n" + "="*60)
    print("SUMMARY")
    print("="*60)
    print(f"Total shaders: {len(metadata)}")
    print(f"Audio-reactive shaders: {audio_reactive_count}")
    print(f"Non-reactive shaders: {len(metadata) - audio_reactive_count}")
    print(f"Entries updated: {updated_count}")
    print("="*60)
    
    # List all audio-reactive shaders
    if audio_reactive_count > 0:
        print("\nAudio-Reactive Shaders:")
        for shader_entry in metadata:
            if shader_entry.get('audio_reactive'):
                print(f"  🎵 {shader_entry['name']}")


def main():
    """Main entry point."""
    print("="*60)
    print("Audio-Reactive Shader Metadata Updater")
    print("="*60)
    print()
    
    update_metadata()
    
    print("\n✓ Metadata update complete!")


if __name__ == "__main__":
    main()

