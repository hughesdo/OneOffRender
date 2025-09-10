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
echo Checking Python installation...
python --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Python is not installed or not in PATH
    echo Please install Python 3.7+ and try again
    pause
    exit /b 1
) else (
    echo Python found and working!
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

REM Install Python dependencies
echo Installing/updating Python dependencies...
python -m pip install --upgrade pip
python -m pip install -r requirements.txt

REM Check for FFmpeg/ffprobe
echo.
echo Checking for FFmpeg/ffprobe...
ffprobe -version >nul 2>&1
if errorlevel 1 (
    echo FFmpeg/ffprobe not found in system PATH
    echo Checking for local FFmpeg installation...

    if not exist "ffmpeg\bin\ffprobe.exe" (
        echo Downloading FFmpeg for Windows...
        echo This is a one-time setup that will take a few minutes...

        REM Create ffmpeg directory
        if not exist "ffmpeg" mkdir ffmpeg
        if not exist "ffmpeg\bin" mkdir "ffmpeg\bin"

        REM Try to download FFmpeg using curl (available on Windows 10+)
        echo Attempting download with curl...
        curl -L -o "ffmpeg-temp.zip" "https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip" 2>nul

        if exist "ffmpeg-temp.zip" (
            echo Download successful! Extracting FFmpeg...

            REM Use PowerShell to extract (more reliable than tar on older Windows)
            powershell -Command "try { Expand-Archive -Path 'ffmpeg-temp.zip' -DestinationPath 'ffmpeg-temp' -Force; exit 0 } catch { exit 1 }" >nul 2>&1

            if errorlevel 1 (
                echo Extraction failed. Trying alternative method...
                REM Fallback: try with different PowerShell syntax
                powershell -Command "Add-Type -AssemblyName System.IO.Compression.FileSystem; [System.IO.Compression.ZipFile]::ExtractToDirectory('ffmpeg-temp.zip', 'ffmpeg-temp')" >nul 2>&1
            )

            REM Move the contents to our ffmpeg directory
            if exist "ffmpeg-temp" (
                echo Moving FFmpeg files...
                for /d %%i in ("ffmpeg-temp\ffmpeg-*") do (
                    if exist "%%i\bin" (
                        copy "%%i\bin\*.exe" "ffmpeg\bin\" >nul 2>&1
                    )
                )

                REM Cleanup
                echo Cleaning up temporary files...
                rmdir /s /q "ffmpeg-temp" >nul 2>&1
                del "ffmpeg-temp.zip" >nul 2>&1

                if exist "ffmpeg\bin\ffprobe.exe" (
                    echo FFmpeg installation completed successfully!
                ) else (
                    echo WARNING: FFmpeg installation may have failed
                    echo Please install FFmpeg manually if video encoding doesn't work
                )
            ) else (
                echo WARNING: Failed to extract FFmpeg
                echo Please install FFmpeg manually if video encoding doesn't work
                del "ffmpeg-temp.zip" >nul 2>&1
            )
        ) else (
            echo WARNING: Failed to download FFmpeg
            echo Please install FFmpeg manually if video encoding doesn't work
            echo You can:
            echo   - Download from: https://ffmpeg.org/download.html
            echo   - Or use: winget install ffmpeg
        )
    ) else (
        echo Local FFmpeg installation found!
    )

    REM Add local FFmpeg to PATH for this session
    if exist "ffmpeg\bin\ffprobe.exe" (
        set "PATH=%SCRIPT_DIR%ffmpeg\bin;%PATH%"
        echo FFmpeg added to PATH for this session

        REM Verify it's working
        ffprobe -version >nul 2>&1
        if errorlevel 1 (
            echo WARNING: Local FFmpeg installation may not be working properly
        ) else (
            echo Local FFmpeg verified and working!
        )
    )
) else (
    echo FFmpeg/ffprobe found in system PATH!
)

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
