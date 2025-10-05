#!/usr/bin/env python3
"""
Simple launcher for the web editor
"""
import sys
import os

# Add web_editor to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'web_editor'))

print("=" * 50)
print("  OneOffRender Web Editor")
print("=" * 50)
print()
print("Starting Flask server...")
print()

# Import and run the app
from web_editor import app as web_app

if __name__ == '__main__':
    print("Server starting on http://localhost:5000")
    print("Press Ctrl+C to stop")
    print()
    web_app.app.run(debug=True, host='0.0.0.0', port=5000)

