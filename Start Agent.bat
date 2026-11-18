@echo off
setlocal
cd /d "%~dp0"

where node >nul 2>nul
if errorlevel 1 (
  echo [!] Node.js was not found. Run Setup Agent.bat once to install prerequisites.
  pause
  exit /b 1
)

set "PY_CMD="
py -3.11 -c "import youtube_transcript_api" >nul 2>nul
if not errorlevel 1 (
  set "PY_CMD=py -3.11"
) else (
  py -c "import youtube_transcript_api" >nul 2>nul
  if not errorlevel 1 (
    set "PY_CMD=py"
  ) else (
    python -c "import youtube_transcript_api" >nul 2>nul
    if not errorlevel 1 (
      set "PY_CMD=python"
    )
  )
)

if "%PY_CMD%"=="" (
  echo [!] Python or transcript support (youtube-transcript-api) is not installed or configured.
  echo Please run Setup Agent.bat once, then start the agent again.
  pause
  exit /b 1
)

node server.mjs
if errorlevel 1 pause
