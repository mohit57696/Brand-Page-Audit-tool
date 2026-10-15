@echo off
setlocal
cd /d "%~dp0"
title Specification Audit Tool
if exist ".venv\Scripts\python.exe" goto run
call Setup.bat
if errorlevel 1 exit /b 1
:run
if not exist "backend\.env" copy /y "backend\.env.example" "backend\.env" >nul
set "HOST=127.0.0.1"
set "PORT=8000"
set "DEBUG=False"
set "AUDIT_OPEN_BROWSER=1"
echo Open http://localhost:8000 in your browser.
echo Keep this window open while using the app. Press Ctrl+C to stop.
".venv\Scripts\python.exe" backend\run.py
pause
