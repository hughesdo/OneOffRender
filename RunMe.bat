@echo off
title OneOffRender - Shader Video Generator

echo ========================================
echo OneOffRender - Shader Video Generator
echo ========================================
echo.

REM Get the directory where this batch file is located
set SCRIPT_DIR=%~dp0
cd /d "%SCRIPT_DIR%"

REM Check if Python is available
python --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Python is not installed or not in PATH
    echo Please install Python 3.7+ and try again
    pause
    exit /b 1
)

REM Create virtual environment if it doesn't exist
if not exist "venv\Scripts\activate.bat" (
    echo Creating virtual environment...
    python -m venv venv
    if errorlevel 1 (
        echo ERROR: Failed to create virtual environment
        pause
        exit /b 1
    )
    echo Virtual environment created successfully!
)

REM Activate virtual environment
echo Activating virtual environment...
call venv\Scripts\activate.bat

REM Install dependencies
echo Installing/updating dependencies...
python -m pip install --upgrade pip
python -m pip install -r requirements.txt

REM Check if config.json exists
if not exist "config.json" (
    echo ERROR: config.json not found
    echo Please ensure config.json is in the same directory as this script
    pause
    exit /b 1
)

REM Ask user about custom temp directory
echo.
echo Do you want to use E:\TEMPSHIT for temporary files? (Y/N)
echo This can help if you're running low on space in the default temp directory.
set /p USE_CUSTOM_TEMP="Enter Y or N: "

if /i "%USE_CUSTOM_TEMP%"=="Y" (
    echo Setting custom temp directory to E:\TEMPSHIT...

    REM Create the directory if it doesn't exist
    if not exist "E:\TEMPSHIT" (
        echo Creating directory E:\TEMPSHIT...
        mkdir "E:\TEMPSHIT" 2>nul
        if errorlevel 1 (
            echo WARNING: Could not create E:\TEMPSHIT directory
            echo Continuing with default temp directory...
        ) else (
            echo Custom temp directory created successfully!
        )
    )

    REM Set environment variables for custom temp
    if exist "E:\TEMPSHIT" (
        set TEMP=E:\TEMPSHIT
        set TMP=E:\TEMPSHIT
        echo Custom temp directory set: E:\TEMPSHIT
    )
) else (
    echo Using default system temp directory...
)

REM Run the shader renderer
echo.
echo Starting shader rendering...
echo.
python render_shader.py

REM Check if rendering was successful
if errorlevel 1 (
    echo.
    echo ERROR: Rendering failed
    pause
    exit /b 1
) else (
    echo.
    echo SUCCESS: Rendering completed!
    echo Check the Output_Video folder for your rendered video.
)

echo.
pause
