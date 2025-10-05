#!/usr/bin/env python3
"""
Quick test script to verify render_timeline.py works
"""

import sys
from pathlib import Path

# Test that render_timeline.py can be imported
try:
    from render_timeline import TimelineRenderer
    print("✓ render_timeline.py imported successfully")
except Exception as e:
    print(f"✗ Failed to import render_timeline.py: {e}")
    sys.exit(1)

# Test that test manifest exists
manifest_path = Path('test_render_manifest.json')
if not manifest_path.exists():
    print(f"✗ Test manifest not found: {manifest_path}")
    sys.exit(1)
print(f"✓ Test manifest found: {manifest_path}")

# Try to load the manifest
try:
    renderer = TimelineRenderer(manifest_path)
    print("✓ TimelineRenderer initialized successfully")
except Exception as e:
    print(f"✗ Failed to initialize TimelineRenderer: {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)

# Check manifest structure
print(f"\nManifest details:")
print(f"  Project: {renderer.manifest.get('project_name')}")
print(f"  Audio: {renderer.manifest['audio']['path']}")
print(f"  Duration: {renderer.manifest['timeline']['duration']}s")
print(f"  Elements: {len(renderer.manifest['timeline']['elements'])}")
print(f"  Resolution: {renderer.get_resolution()}")
print(f"  Frame rate: {renderer.get_frame_rate()}")

# Validate manifest
try:
    renderer.validate_manifest()
    print("\n✓ Manifest validation passed")
except Exception as e:
    print(f"\n✗ Manifest validation failed: {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)

print("\n✅ All tests passed! render_timeline.py is ready to use.")
print("\nTo run a full render, execute:")
print(f"  python render_timeline.py {manifest_path}")

