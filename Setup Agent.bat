@echo off
setlocal
cd /d "%~dp0"

echo ===================================================
echo             TubeTrail - Setup Agent
echo ===================================================
echo.

where node >nul 2>nul
if errorlevel 1 goto install_node
echo [OK] Node.js is detected.
goto check_python

:install_node
echo [!] Node.js was not found on your system.
set "INSTALL_NODE=n"
set /p "INSTALL_NODE=Do you want to download and install Node.js automatically? (y/n): "
if /i not "%INSTALL_NODE%"=="y" goto skip_node
echo Downloading Node.js LTS installer...
curl -Lo "%temp%\node-setup.msi" "https://nodejs.org/dist/v20.18.0/node-v20.18.0-x64.msi"
if errorlevel 1 (
  echo Failed to download Node.js installer. Please install manually from https://nodejs.org/
  pause
  exit /b 1
)
echo Running Node.js installer...
start /wait msiexec /i "%temp%\node-setup.msi"
del /f /q "%temp%\node-setup.msi" >nul 2>nul
echo Node.js installation finished.
goto check_python

:skip_node
echo Node.js is required. Please install it from https://nodejs.org/ and rerun setup.
pause
exit /b 1

:check_python
echo.
set "PY_CMD="

py -3.11 --version >nul 2>nul
if not errorlevel 1 (
  set "PY_CMD=py -3.11"
  goto confirm_python
)

py --version >nul 2>nul
if not errorlevel 1 (
  set "PY_CMD=py"
  goto confirm_python
)

python --version >nul 2>nul
if not errorlevel 1 (
  set "PY_CMD=python"
  goto confirm_python
)

goto install_python

:confirm_python
echo [OK] Python is detected (%PY_CMD%).
set "CONFIRM_PY=y"
set /p "CONFIRM_PY=Is Python installed and ready to use? (y/n): "
if /i "%CONFIRM_PY%"=="n" goto install_python
goto install_packages

:install_python
echo.
echo [!] Python is not installed or configured.
set "INSTALL_PY=y"
set /p "INSTALL_PY=Do you want to download and install Python 3.11 automatically? (y/n): "
if /i not "%INSTALL_PY%"=="y" goto skip_python

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

py -3.11 --version >nul 2>nul
if not errorlevel 1 (
  set "PY_CMD=py -3.11"
  goto install_packages
)

python --version >nul 2>nul
if not errorlevel 1 (
  set "PY_CMD=python"
  goto install_packages
)

echo Python installation completed. Please close this window and run Setup Agent.bat once more to apply PATH changes.
pause
exit /b 0

:skip_python
echo Python is required to retrieve YouTube transcripts.
echo Please install Python 3.11 from https://www.python.org/downloads/ and rerun setup.
pause
exit /b 1

:install_packages
echo.
echo Installing / verifying required transcript libraries...
%PY_CMD% -m pip install --user youtube-transcript-api
if errorlevel 1 (
  %PY_CMD% -m pip install youtube-transcript-api
  if errorlevel 1 (
    echo [!] Could not install youtube-transcript-api. Please check your internet connection and try again.
    pause
    exit /b 1
  )
)

echo.
echo ===================================================
echo [SUCCESS] Setup is complete!
echo.
echo To start TubeTrail right now:
echo   1. Double-click: "Start Agent.bat"
echo   OR
echo   2. Run command:  node server.mjs
echo.
echo Web interface will be available at: http://127.0.0.1:4173
echo ===================================================
echo.
set "LAUNCH_NOW=n"
set /p "LAUNCH_NOW=Would you like to start TubeTrail right now? (y/n): "
if /i "%LAUNCH_NOW%"=="y" (
  echo.
  echo Starting TubeTrail...
  start "" "Start Agent.bat"
  exit /b 0
)
pause
