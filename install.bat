@echo off
REM OneOffRender Installation Script

echo.
echo ========================================
echo OneOffRender Installation
echo ========================================
echo.

REM 0. System Check
echo [0/8] Performing system check...
echo.
echo === System Check ===

REM Check Python version
python --version >nul 2>&1
if errorlevel 1 (
    echo [MISSING] Python: Not found in PATH
    set PYTHON_MISSING=1
    set PYTHON_CHECK=MISSING
) else (
    for /f "tokens=2" %%i in ('python --version 2^>^&1') do set PYTHON_VERSION=%%i
    echo [OK] Python version: %PYTHON_VERSION%
    set PYTHON_CHECK=OK
    set PYTHON_MISSING=0
)

REM Check FFmpeg
ffmpeg -version >nul 2>&1
if errorlevel 1 (
    echo [MISSING] FFmpeg: Not found in PATH
    set FFMPEG_MISSING=1
    set FFMPEG_CHECK=MISSING
) else (
    for /f "tokens=1" %%i in ('ffmpeg -version 2^>^&1 ^| findstr /R "ffmpeg version"') do set FFMPEG_VERSION=%%i
    echo [OK] FFmpeg: Found
    set FFMPEG_MISSING=0
    set FFMPEG_CHECK=OK
)

echo.

REM 0.3 Install Python if missing
if %PYTHON_MISSING%==1 (
    echo.
    echo [0.3/7] Installing Python...

    REM Create python directory if it doesn't exist
    if not exist "python_installer" mkdir python_installer

    REM Download Python installer
    echo Downloading Python 3.11...
    powershell -Command "& {[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; (New-Object System.Net.WebClient).DownloadFile('https://www.python.org/ftp/python/3.11.9/python-3.11.9-amd64.exe', 'python_installer\python-installer.exe')}"

    if errorlevel 1 (
        echo Error: Failed to download Python
        echo Please download manually from: https://www.python.org/downloads/
        set /p CONTINUE="Continue? (y/n): "
        if /i not "%CONTINUE%"=="y" (
            exit /b 1
        )
    ) else (
        echo Installing Python...
        REM Install Python with options: /quiet /InstallAllUsers /PrependPath=1
        python_installer\python-installer.exe /quiet InstallAllUsers=1 PrependPath=1 Include_test=0

        if errorlevel 1 (
            echo Error: Failed to install Python
            set /p CONTINUE="Continue? (y/n): "
            if /i not "%CONTINUE%"=="y" (
                exit /b 1
            )
        ) else (
            echo Python installed successfully

            REM Refresh PATH environment variable
            for /f "tokens=2*" %%A in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v PATH') do set PATH=%%B

            REM Verify Python installation
            python --version >nul 2>&1
            if errorlevel 1 (
                echo Warning: Python installation may not be in PATH yet
                echo Please restart your Command Prompt and run install.bat again
                pause
                exit /b 1
            ) else (
                for /f "tokens=2" %%i in ('python --version 2^>^&1') do set PYTHON_VERSION=%%i
                echo [OK] Python version: %PYTHON_VERSION%
                set PYTHON_CHECK=OK
            )
        )

        REM Clean up installer
        if exist "python_installer" rmdir /s /q "python_installer"
    )
    echo.
)

REM 0.5 Install FFmpeg if missing
if %FFMPEG_MISSING%==1 (
    echo.
    echo [0.5/8] Installing FFmpeg...

    REM Create ffmpeg directory if it doesn't exist
    if not exist "ffmpeg" mkdir ffmpeg

    REM Download FFmpeg using multiple sources
    echo Downloading FFmpeg...
    powershell -Command "& {[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; try { (New-Object System.Net.WebClient).DownloadFile('https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl.zip', 'ffmpeg.zip') } catch { Write-Host 'Primary download failed, trying alternative...'; (New-Object System.Net.WebClient).DownloadFile('https://ffmpeg.org/releases/ffmpeg-snapshot-win64.zip', 'ffmpeg.zip') }}"

    if errorlevel 1 (
        echo Error: Failed to download FFmpeg
        echo Please download manually from: https://ffmpeg.org/download.html
        set /p CONTINUE="Continue without FFmpeg? (y/n): "
        if /i not "%CONTINUE%"=="y" (
            exit /b 1
        )
    ) else (
        echo Extracting FFmpeg...
        powershell -Command "& {Expand-Archive -Path 'ffmpeg.zip' -DestinationPath 'ffmpeg_temp' -Force}"

        if errorlevel 1 (
            echo Error: Failed to extract FFmpeg
            set /p CONTINUE="Continue without FFmpeg? (y/n): "
            if /i not "%CONTINUE%"=="y" (
                exit /b 1
            )
        ) else (
            REM Find bin folder and copy it
            echo Moving FFmpeg binaries...
            if exist "ffmpeg_temp\bin" (
                xcopy "ffmpeg_temp\bin\*" "ffmpeg\bin\" /Y /I >nul
            ) else (
                REM Try nested folder structure
                for /d %%D in (ffmpeg_temp\*) do (
                    if exist "%%D\bin" (
                        xcopy "%%D\bin\*" "ffmpeg\bin\" /Y /I >nul
                    )
                )
            )

            if exist "ffmpeg\bin\ffmpeg.exe" (
                echo FFmpeg installed successfully to: %CD%\ffmpeg\bin
                set FFMPEG_INSTALLED=1

                REM Add to PATH
                setx PATH "%PATH%;%CD%\ffmpeg\bin"
                echo Added FFmpeg to system PATH
            ) else (
                echo Error: FFmpeg binaries not found after extraction
                set /p CONTINUE="Continue without FFmpeg? (y/n): "
                if /i not "%CONTINUE%"=="y" (
                    exit /b 1
                )
            )

            REM Clean up temporary files
            if exist "ffmpeg_temp" rmdir /s /q "ffmpeg_temp"
            if exist "ffmpeg.zip" del ffmpeg.zip
        )
    )
    echo.
)

REM 1. Create virtual environment
echo [1/8] Creating virtual environment...
python -m venv venv
if errorlevel 1 (
    echo Error: Failed to create virtual environment
    pause
    exit /b 1
)
echo Virtual environment created successfully.
echo.

REM 2. Activate virtual environment
echo [2/8] Activating virtual environment...
call venv\Scripts\activate.bat
if errorlevel 1 (
    echo Error: Failed to activate virtual environment
    pause
    exit /b 1
)
echo Virtual environment activated.
echo.

REM 3. Install dependencies
echo [3/8] Installing dependencies...
pip install -r requirements.txt
if errorlevel 1 (
    echo Error: Failed to install dependencies
    pause
    exit /b 1
)
echo Dependencies installed successfully.
echo.

REM 4. Verify installation
echo [4/8] Verifying installation...
python verify_installation.py
if errorlevel 1 (
    echo Error: Installation verification failed
    pause
    exit /b 1
)
echo Installation verified.
echo.

REM 5. Verify FFmpeg
echo [5/8] Verifying FFmpeg...
python verify_ffmpeg.py
if errorlevel 1 (
    echo Error: FFmpeg verification failed
    pause
    exit /b 1
)
echo FFmpeg verified.
echo.

echo ========================================
echo Installation completed successfully!
echo ========================================
echo.

REM Display environment variables summary
echo === Environment Variables ===
echo Python Check: %PYTHON_CHECK%
echo FFmpeg Check: %FFMPEG_CHECK%
echo Python Version: %PYTHON_VERSION%
if defined FFMPEG_VERSION (
    echo FFmpeg Version: %FFMPEG_VERSION%
)
echo.

REM Notify user if FFmpeg was installed
if defined FFMPEG_INSTALLED (
    echo.
    echo *** IMPORTANT ***
    echo FFmpeg was installed during this setup.
    echo You MUST restart your Command Prompt or PowerShell for the changes to take effect.
    echo.
    echo Please:
    echo 1. Close this window
    echo 2. Open a new Command Prompt or PowerShell window
    echo 3. Run your application again
    echo.
)

pause

