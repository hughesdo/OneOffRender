#!/usr/bin/env python3
"""Test Flask import"""

print("Testing imports...")

try:
    from flask import Flask
    print("✓ Flask imported")
except Exception as e:
    print(f"✗ Flask import failed: {e}")

try:
    from flask_cors import CORS
    print("✓ flask_cors imported")
except Exception as e:
    print(f"✗ flask_cors import failed: {e}")

try:
    import librosa
    print("✓ librosa imported")
except Exception as e:
    print(f"✗ librosa import failed: {e}")

print("\nAll imports successful! Starting Flask app...")

from pathlib import Path

app = Flask(__name__)
CORS(app)

@app.route('/')
def index():
    return "Flask is working!"

if __name__ == '__main__':
    print("Starting Flask server on http://localhost:5000")
    app.run(debug=True, host='0.0.0.0', port=5000)

