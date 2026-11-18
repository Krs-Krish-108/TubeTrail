@echo off
setlocal
cd /d "%~dp0"

where node >nul 2>nul
if errorlevel 1 (
  echo [!] Node.js was not found. Please install Node.js from https://nodejs.org/ or run Setup Agent.bat.
  pause
  exit /b 1
)

node server.mjs
if errorlevel 1 pause
