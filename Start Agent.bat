@echo off
setlocal
cd /d "%~dp0"
where node >nul 2>nul
if errorlevel 1 (
  echo Node.js was not found. Install the current Node.js LTS from https://nodejs.org/ and try again.
  pause
  exit /b 1
)
where py >nul 2>nul
if errorlevel 1 (
  echo Python was not found. Install Python 3.11 from https://www.python.org/downloads/ and try again.
  pause
  exit /b 1
)
py -3.11 -c "import youtube_transcript_api" >nul 2>nul
if errorlevel 1 (
  echo Transcript support is not installed. Run Setup Agent.bat once, then start the agent again.
  pause
  exit /b 1
)
node server.mjs
if errorlevel 1 pause
