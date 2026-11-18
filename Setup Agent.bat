@echo off
setlocal
cd /d "%~dp0"
where py >nul 2>nul
if errorlevel 1 (
  echo Python launcher was not found. Install Python 3.11 from https://www.python.org/downloads/ and select the Python Launcher option.
  pause
  exit /b 1
)
py -3.11 --version >nul 2>nul
if errorlevel 1 (
  echo Python 3.11 was not found. Install Python 3.11 from https://www.python.org/downloads/.
  pause
  exit /b 1
)
echo Installing the transcript component for this agent...
py -3.11 -m pip install --user youtube-transcript-api
if errorlevel 1 (
  echo Setup could not install the transcript component. Check your internet connection and try again.
  pause
  exit /b 1
)
echo Setup complete. You can now open Start Agent.bat.
pause

