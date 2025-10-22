@echo off
REM ========================================
REM OneOffRender - Update from GitHub
REM ========================================
REM This batch file safely updates your OneOffRender installation
REM with the latest code, shaders, and features from GitHub
REM
REM Author: OneOffRender System
REM Date: 2025-01-27

echo.
echo ========================================
echo OneOffRender - Update from GitHub
echo ========================================
echo.

REM Change to the script's directory (where this .bat file is located)
cd /d "%~dp0"

echo Current directory: %CD%
echo.

REM Check if we're in a git repository
if not exist ".git" (
    echo ERROR: This doesn't appear to be a Git repository!
    echo.
    echo To set up OneOffRender from GitHub:
    echo   1. Clone the repository:
    echo      git clone https://github.com/hughesdo/OneOffRender.git
    echo   2. Navigate to the folder:
    echo      cd OneOffRender
    echo   3. Run this script again:
    echo      refresh.bat
    echo.
    pause
    exit /b 1
)

REM Check if OneOffRender files exist
if not exist "oneoff.py" (
    echo ERROR: OneOffRender files not found!
    echo Make sure you're in the OneOffRender project directory.
    echo.
    pause
    exit /b 1
)

echo ✓ OneOffRender Git repository detected
echo.

REM Check for uncommitted changes
echo [1/7] Checking for local changes...
git status --porcelain > temp_status.txt 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Git command failed. Make sure Git is installed and in PATH.
    if exist temp_status.txt del temp_status.txt
    pause
    exit /b 1
)

REM Check if temp file has content (indicating changes)
for %%A in (temp_status.txt) do set size=%%~zA
if %size% GTR 0 (
    echo WARNING: You have uncommitted local changes!
    echo.
    echo Modified files:
    type temp_status.txt
    echo.
    echo Your changes will be safely stashed before updating.
    echo You can restore them later with: git stash pop
    echo.
    set /p CONTINUE="Continue with update? (Y/N): "
    if /i not "!CONTINUE!"=="Y" (
        echo Update cancelled by user.
        del temp_status.txt
        pause
        exit /b 0
    )
    
    echo.
    echo Stashing local changes...
    git stash push -m "Auto-stash before OneOffRender update - %date% %time%"
    if %ERRORLEVEL% NEQ 0 (
        echo ERROR: Failed to stash changes.
        del temp_status.txt
        pause
        exit /b 1
    )
    echo ✓ Local changes stashed safely
    set STASHED=1
) else (
    echo ✓ No local changes detected
    set STASHED=0
)

del temp_status.txt
echo.

REM Show current version info
echo [2/7] Current version info...
git log --oneline -1 2>nul
echo.

REM Fetch latest updates
echo [3/7] Fetching latest updates from GitHub...
git fetch origin
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Failed to fetch from GitHub. Check your internet connection.
    pause
    exit /b 1
)
echo ✓ Latest updates fetched from GitHub
echo.

REM Check if updates are available
echo [4/7] Checking for available updates...
git rev-list HEAD...origin/main --count > update_count.txt 2>nul
set /p UPDATE_COUNT=<update_count.txt
del update_count.txt

if "%UPDATE_COUNT%"=="0" (
    echo ✓ Your OneOffRender is already up to date!
    echo.
    if %STASHED%==1 (
        echo Your stashed changes are still available.
        echo To restore them: git stash pop
        echo.
    )
    pause
    exit /b 0
)

echo Found %UPDATE_COUNT% new update(s) available!
echo.

REM Pull updates
echo [5/7] Applying updates...
git pull origin main
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Failed to pull updates from GitHub.
    if %STASHED%==1 (
        echo Your changes are safely stashed. To restore: git stash pop
    )
    pause
    exit /b 1
)
echo ✓ Updates applied successfully
echo.

REM Show what was updated
echo New version info:
git log --oneline -1 2>nul
echo.

REM Clear Python cache
echo [6/7] Clearing Python cache...
if exist "CacheClear.bat" (
    echo Using CacheClear.bat...
    call CacheClear.bat >nul 2>&1
) else (
    echo Clearing __pycache__ directories manually...
    for /d /r . %%d in (__pycache__) do @if exist "%%d" (
        echo   Removing: %%d
        rd /s /q "%%d" 2>nul
    )
)
echo ✓ Python cache cleared
echo.

REM Update shader metadata
echo [7/7] Updating shader metadata...
if exist "venv\Scripts\python.exe" (
    echo Running audio metadata update...
    venv\Scripts\python.exe update_audio_metadata.py
    if %ERRORLEVEL% EQU 0 (
        echo ✓ Shader metadata updated successfully
    ) else (
        echo ⚠ Warning: Shader metadata update had issues (non-critical)
    )
) else (
    echo ⚠ Virtual environment not found - skipping metadata update
    echo   Run install.bat or StartWebEditor.bat to set up the environment
)
echo.

REM Final status and instructions
echo ========================================
echo Update Complete!
echo ========================================
echo.
echo ✅ What was updated:
echo   - Latest OneOffRender code and features
echo   - New shaders and transitions
echo   - Updated documentation
echo   - Refreshed shader metadata
echo.

if %STASHED%==1 (
    echo 📦 Your local changes were safely stashed
    echo   To restore them: git stash pop
    echo   To see stashed changes: git stash show
    echo.
)

echo 🚀 Next steps:
echo   1. Web Editor users: Press Ctrl+Shift+R to refresh browser
echo   2. Batch users: Your next render will use the updated code
echo   3. Check Documentation/ folder for new features
echo.

echo Your OneOffRender installation is now up to date!
echo Enjoy the latest features and improvements! 🌟
echo.

pause
