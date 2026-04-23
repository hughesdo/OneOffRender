# Shader Transition rendering Pipeline

This document explains the technical rendering pipeline of the transition process. It details what happens behind the scenes when two visual shaders are placed with a transition element between them in the timeline.

## 1. Timeline Overlap Creation

In the web interface, timeline elements (shaders and transitions) are organized sequentially. However, to create a smooth transition where both shaders merge, the underlying pipeline requires them to play at the same time.

When the rendering begins (`render_timeline.py`), the script converts the sequential timeline into an **overlapping timeline**:
- **Fixed Transition Length**: Transitions have a default length of **1.6 seconds**. 
- **Extending the First Shader**: The first shader's ending time is extended to cover the entire transition period.
- **Prestarting the Second Shader**: The second shader's starting time is pulled back so it begins exactly when the transition starts.

This process ensures that there is exactly a **1.6-second overlap window** where **both** the first and second shaders are actively running.

## 2. Rendering the Overlap (Frame-by-Frame) 

During a normal period of the timeline, only one shader is rendered per frame. When the playhead enters the 1.6-second overlap window, the rendering engine switches to `render_transition_frame()`.

For every single frame during this 1.6-second overlap:

1. **Calculate Progress**: The system calculates a `progress` value between `0.0` and `1.0`. (e.g., at 0.8 seconds into the 1.6-second transition, the progress is `0.5`).
2. **Render "From" Shader off-screen**: The engine generates the current frame of the first shader and saves it to a temporary hidden texture (`temp_texture_from`).
3. **Render "To" Shader off-screen**: The engine does the same for the second shader, saving it to another temporary hidden texture (`temp_texture_to`).
4. **Transition Execution**: The selected transition shader (e.g., Wipe, Dissolve, Zoom) is loaded. The engine feeds it:
   - The "From" texture
   - The "To" texture
   - The `progress` value (0.0 to 1.0)
   - Configuration parameters (direction, smoothness, etc.)
5. **Final Output**: The transition shader mathematically mixes the two textures based on the `progress` value and outputs the final composited frame to the main video file.

If a specific transition shader fails to load, the engine automatically falls back to a simple Alpha blend (`render_simple_transition_frame`) to ensure the video renders without crashing.

## 3. Audio Reactivity within Transitions

Both the "From" and "To" shaders continue to be fully audio-reactive during the transition window. 
- Fast Fourier Transform (FFT) spectrum data and waveform data from the audio track are calculated for the current exact millisecond.
- This audio data is fed to both shaders perfectly in sync before they are rendered off-screen, ensuring seamless reactiveness through the entire transition.

## Summary 

The secret to why the transition looks natural is the **time-extension overlap**. Instead of taking chunks away from the video run times, the timeline mathematically extends shader A to keep playing through the transition, starts shader B early, and uses a specialized transition shader to algorithmically dissolve between their off-screen buffers based on the overall 1.6-second progress. 
