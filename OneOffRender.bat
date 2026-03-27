@echo off
REM OneOffRender Web Editor Launcher
REM This script starts the Flask web server for the video editor

echo ========================================
echo   OneOffRender Web Editor
echo ========================================
echo.

REM Check if Python is available
python --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Python is not installed or not in PATH
    echo Please install Python 3.8 or higher
    pause
    exit /b 1
)

REM Check if virtual environment exists
if not exist "venv\Scripts\python.exe" (
    echo Virtual environment not found. Please run SETUP_GUIDE.md instructions first.
    pause
    exit /b 1
)

REM Check if Flask is installed
venv\Scripts\python.exe -c "import flask" >nul 2>&1
if errorlevel 1 (
    echo Installing web editor dependencies...
    venv\Scripts\python.exe -m pip install -r web_editor\requirements.txt
)

REM Start the Flask server
echo.
echo Starting web editor server...
echo.
echo The editor will be available at:
echo http://localhost:5000
echo.
echo Press Ctrl+C to stop the server
echo.

venv\Scripts\python.exe web_editor\app.py

pause

