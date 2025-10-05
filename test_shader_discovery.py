#!/usr/bin/env python3
"""
Test script to verify shader discovery improvements
"""

import sys
from pathlib import Path
from render_shader import ShaderRenderer

def test_shader_discovery():
    """Test the improved shader discovery system."""
    print("Testing Shader Discovery System")
    print("=" * 50)
    
    try:
        # Create renderer instance
        renderer = ShaderRenderer()
        
        # Test shader discovery
        print("\n1. Discovering shaders...")
        shader_files = renderer.discover_shaders()
        
        print(f"Found {len(shader_files)} usable shaders:")
        for shader_file in shader_files:
            print(f"  ✓ {shader_file.name}")
        
        # Test shader compilation
        print(f"\n2. Testing shader compilation...")
        compiled_shaders = renderer.precompile_shaders(shader_files)
        
        if compiled_shaders:
            print(f"Successfully compiled {len(compiled_shaders)} shaders:")
            for name in compiled_shaders.keys():
                print(f"  ✓ {name}")
        else:
            print("  ✗ No shaders compiled successfully")
            
        # Check for problematic shaders that should be excluded
        print(f"\n3. Checking exclusion of problematic shaders...")
        problematic_found = []
        for shader_file in shader_files:
            name = shader_file.name
            if name in ['Traveler2.glsl', 'the_fractal.glsl', 'Reflecting Crystals.glsl', 'infinite-keys.glsl']:
                problematic_found.append(name)
        
        if problematic_found:
            print(f"  ✗ Found problematic shaders that should be excluded: {problematic_found}")
        else:
            print("  ✓ No problematic shaders found (correctly excluded)")
            
        # Check for _Fixed versions being preferred
        print(f"\n4. Checking _Fixed version preference...")
        fixed_versions = [s.name for s in shader_files if s.name.endswith('_Fixed.glsl')]
        print(f"Found {len(fixed_versions)} _Fixed versions:")
        for name in fixed_versions:
            print(f"  ✓ {name}")
            
        return len(compiled_shaders) > 0 if compiled_shaders else False
        
    except Exception as e:
        print(f"Error during testing: {e}")
        return False

if __name__ == "__main__":
    success = test_shader_discovery()
    if success:
        print(f"\n🎉 Shader discovery test PASSED!")
        sys.exit(0)
    else:
        print(f"\n❌ Shader discovery test FAILED!")
        sys.exit(1)
