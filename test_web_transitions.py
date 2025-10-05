#!/usr/bin/env python3
"""Test script to verify web interface transition detection works correctly."""

import json
from render_timeline import TimelineRenderer

def test_web_interface_transitions():
    """Test conversion of web interface timeline to overlapping format."""

    # Load the current web interface manifest
    with open('temp_render_manifest.json', 'r') as f:
        manifest = json.load(f)

    print('=== Original Web Interface Timeline ===')
    for el in manifest['timeline']['elements']:
        print(f'{el["type"]}: {el["name"]} ({el["startTime"]}s - {el["endTime"]}s)')

    # Test the conversion
    renderer = TimelineRenderer('temp_render_manifest.json')
    layer0_elements = [el for el in manifest['timeline']['elements'] if el.get('layer', 0) == 0]
    converted = renderer.convert_web_interface_timeline(layer0_elements)

    print('\n=== Converted Overlapping Timeline ===')
    for el in converted:
        print(f'{el["type"]}: {el["name"]} ({el["startTime"]}s - {el["endTime"]}s)')

    print('\n=== Transition Mapping ===')
    if hasattr(renderer, 'transition_mapping'):
        for key, transition_name in renderer.transition_mapping.items():
            print(f'{key}: {transition_name}')
    else:
        print('No transition mapping found')

    print('\n=== Testing Transition Detection ===')
    test_times = [5.0, 6.8, 8.0]  # Test around the actual transition period (6.04s - 7.64s)
    for time_sec in test_times:
        result = renderer.find_transition_state(converted, time_sec, 1.6, 0.45)
        if len(result) == 4:
            from_el, to_el, progress, transition_name = result
            if progress is not None:
                print(f'Time {time_sec}s: TRANSITION {from_el["name"]} -> {to_el["name"]} (progress: {progress:.3f}) using {transition_name}')
            else:
                print(f'Time {time_sec}s: NORMAL {from_el["name"] if from_el else "None"}')
        elif len(result) == 3:
            from_el, to_el, progress = result
            if progress is not None:
                print(f'Time {time_sec}s: TRANSITION {from_el["name"]} -> {to_el["name"]} (progress: {progress:.3f}) - legacy format')
            else:
                print(f'Time {time_sec}s: NORMAL {from_el["name"] if from_el else "None"}')

if __name__ == "__main__":
    test_web_interface_transitions()
