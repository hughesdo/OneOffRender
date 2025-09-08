@echo off
REM ========================================
REM OneOffRender Python Cache Cleaner
REM ========================================
REM This batch file safely clears Python bytecode cache
REM from the OneOffRender project directory
REM
REM Author: OneOffRender System
REM Date: 2025-01-27

echo.
echo ========================================
echo OneOffRender Python Cache Cleaner
echo ========================================
echo.

REM Change to the script's directory (where this .bat file is located)
cd /d "%~dp0"

echo Current directory: %CD%
echo.

REM Check if we're in the right directory by looking for key files
if not exist "oneoff.py" (
    echo ERROR: oneoff.py not found!
    echo Make sure this batch file is in your OneOffRender project directory.
    echo.
    pause
    exit /b 1
)

if not exist "render_shader.py" (
    echo ERROR: render_shader.py not found!
    echo Make sure this batch file is in your OneOffRender project directory.
    echo.
    pause
    exit /b 1
)

echo ✓ OneOffRender project files detected
echo.

REM Clear Python bytecode cache directories
echo Clearing Python cache (__pycache__ directories)...
echo.

REM Use PowerShell to safely remove __pycache__ directories
powershell -Command "Get-ChildItem -Path . -Recurse -Directory -Name '__pycache__' | ForEach-Object { Write-Host 'Removing: ' $_; Remove-Item $_ -Recurse -Force }"

REM Check if the command was successful
if %ERRORLEVEL% EQU 0 (
    echo.
    echo ✓ Python cache cleared successfully!
    echo.
    echo What was cleared:
    echo   - All __pycache__ directories and .pyc files
    echo   - Compiled Python bytecode cache
    echo.
    echo What was NOT affected:
    echo   - Your source code files (.py)
    echo   - Your shader files (.glsl)
    echo   - Your output videos
    echo   - Your audio files
    echo.
    echo Your OneOffRender system is ready for fresh compilation!
) else (
    echo.
    echo ✗ Error occurred while clearing cache
    echo Please check permissions and try again
)

echo.
echo ========================================
echo Cache clearing complete
echo ========================================
echo.
pause
