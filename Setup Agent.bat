@echo off
setlocal EnableDelayedExpansion
cd /d "%~dp0"

echo ===================================================
echo             TubeTrail - Setup Agent
echo ===================================================
echo.

:: 1. Check Node.js
where node >nul 2>nul
if errorlevel 1 (
  echo [!] Node.js was not found on your system.
  set /p "INSTALL_NODE=Do you want to download and install Node.js automatically? (y/n): "
  if /i "!INSTALL_NODE!"=="y" (
    echo Downloading Node.js LTS installer...
    curl -Lo "%temp%\node-setup.msi" "https://nodejs.org/dist/v20.18.0/node-v20.18.0-x64.msi"
    if errorlevel 1 (
      echo Failed to download Node.js installer. Please install manually from https://nodejs.org/
      pause
      exit /b 1
    )
    echo Running Node.js installer (follow the prompt on screen)...
    start /wait msiexec /i "%temp%\node-setup.msi"
    del /f /q "%temp%\node-setup.msi" >nul 2>nul
    echo Node.js installation finished. Please restart this script if environment variables need to reload.
  ) else (
    echo Node.js is required. Please install it from https://nodejs.org/ and rerun setup.
    pause
    exit /b 1
  )
) else (
  echo [OK] Node.js is detected.
)
echo.

:: 2. Check Python
set "PYTHON_FOUND=0"
set "PY_CMD="

:: Check py launcher with 3.11
py -3.11 --version >nul 2>nul
if not errorlevel 1 (
  set "PYTHON_FOUND=1"
  set "PY_CMD=py -3.11"
) else (
  :: Check py default launcher
  py --version >nul 2>nul
  if not errorlevel 1 (
    set "PYTHON_FOUND=1"
    set "PY_CMD=py"
  ) else (
    :: Check standard python
    python --version >nul 2>nul
    if not errorlevel 1 (
      set "PYTHON_FOUND=1"
      set "PY_CMD=python"
    )
  )
)

if "%PYTHON_FOUND%"=="1" (
  echo [OK] Python is detected: !PY_CMD!
  set /p "CONFIRM_PY=Is Python properly installed and ready to use? (y/n): "
  if /i "!CONFIRM_PY!"=="n" (
    set "PYTHON_FOUND=0"
  )
)

if "%PYTHON_FOUND%"=="0" (
  echo.
  echo [!] Python is not installed or configured.
  set /p "INSTALL_PY=Do you want to download and install Python 3.11 automatically? (y/n): "
  if /i "!INSTALL_PY!"=="y" (
    echo Downloading Python 3.11.9 installer...
    curl -Lo "%temp%\python-installer.exe" "https://www.python.org/ftp/python/3.11.9/python-3.11.9-amd64.exe"
    if errorlevel 1 (
      echo Download failed. Please download Python 3.11 from https://www.python.org/downloads/
      pause
      exit /b 1
    )
    echo Installing Python 3.11 (with PATH and py launcher enabled)...
    start /wait "" "%temp%\python-installer.exe" /passive InstallAllUsers=1 PrependPath=1 Include_launcher=1
    del /f /q "%temp%\python-installer.exe" >nul 2>nul

    :: Refresh and check again
    py -3.11 --version >nul 2>nul
    if not errorlevel 1 (
      set "PY_CMD=py -3.11"
    ) else (
      python --version >nul 2>nul
      if not errorlevel 1 (
        set "PY_CMD=python"
      ) else (
        echo Python installation completed. If the command is not recognized yet, please close this window and run Setup Agent.bat again so PATH changes take effect.
        pause
        exit /b 0
      )
    )
    echo [OK] Python installed successfully.
  ) else (
    echo Python is required to retrieve YouTube transcripts.
    echo Please install Python 3.11 from https://www.python.org/downloads/ and rerun setup.
    pause
    exit /b 1
  )
)
echo.

:: 3. Install required Python packages
echo Installing / verifying required transcript libraries...
!PY_CMD! -m pip install --upgrade pip >nul 2>nul
!PY_CMD! -m pip install --user youtube-transcript-api
if errorlevel 1 (
  !PY_CMD! -m pip install youtube-transcript-api
  if errorlevel 1 (
    echo [!] Could not install youtube-transcript-api. Please check your internet connection and try again.
    pause
    exit /b 1
  )
)

echo.
echo ===================================================
echo [SUCCESS] Setup is complete!
echo You can now run Start Agent.bat to use TubeTrail.
echo ===================================================
pause
