@echo off
REM OneOffRender Uninstallation Script

echo.
echo ========================================
echo OneOffRender Uninstallation
echo ========================================
echo.

REM Confirm uninstallation
set /p CONFIRM="Are you sure you want to uninstall OneOffRender? (y/n): "
if /i not "%CONFIRM%"=="y" (
    echo Uninstallation cancelled.
    pause
    exit /b 0
)

echo.
echo [1/4] Removing virtual environment...
if exist "venv" (
    rmdir /s /q "venv"
    if errorlevel 1 (
        echo Warning: Failed to remove virtual environment
    ) else (
        echo Virtual environment removed.
    )
) else (
    echo Virtual environment not found (already removed).
)
echo.

echo [2/4] Removing FFmpeg installation...
if exist "ffmpeg" (
    rmdir /s /q "ffmpeg"
    if errorlevel 1 (
        echo Warning: Failed to remove FFmpeg directory
    ) else (
        echo FFmpeg directory removed.
    )
) else (
    echo FFmpeg directory not found (already removed).
)
echo.

echo [3/4] Removing FFmpeg from system PATH...
REM Get current PATH from registry
for /f "tokens=2*" %%A in ('reg query "HKCU\Environment" /v PATH 2^>nul') do (
    set CURRENT_PATH=%%B
)

if defined CURRENT_PATH (
    REM Check if FFmpeg path is in PATH
    echo %CURRENT_PATH% | findstr /i "ffmpeg" >nul
    if errorlevel 1 (
        echo FFmpeg not found in system PATH.
    ) else (
        echo Removing FFmpeg from system PATH...
        REM Create a temporary script to remove the FFmpeg path
        powershell -Command "& {$path = [Environment]::GetEnvironmentVariable('PATH', 'User'); $newPath = ($path -split ';' | Where-Object {$_ -notlike '*ffmpeg*'}) -join ';'; [Environment]::SetEnvironmentVariable('PATH', $newPath, 'User'); Write-Host 'FFmpeg removed from system PATH'}"
        if errorlevel 1 (
            echo Warning: Could not remove FFmpeg from PATH via PowerShell
            echo Please manually remove FFmpeg path from system environment variables:
            echo   1. Press Win+X and select "System"
            echo   2. Click "Advanced system settings"
            echo   3. Click "Environment Variables"
            echo   4. Find and edit the PATH variable
            echo   5. Remove any entries containing "ffmpeg"
        ) else (
            echo FFmpeg removed from system PATH successfully.
        )
    )
) else (
    echo Could not read system PATH.
)
echo.

echo [4/4] Cleanup complete...
echo.

echo ========================================
echo Uninstallation completed!
echo ========================================
echo.
echo The following were removed:
echo   - Virtual environment (venv/)
echo   - FFmpeg installation (ffmpeg/)
echo.
echo The following were NOT removed (you can delete manually if desired):
echo   - config.json
echo   - render_shader.py
echo   - requirements.txt
echo   - Shaders/
echo   - Input_Audio/
echo   - Output/
echo.
echo To completely remove OneOffRender:
echo   1. Delete the entire OneOffRender folder
echo   2. Or manually delete the files listed above
echo.

pause

