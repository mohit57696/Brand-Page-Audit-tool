@echo off
title Specification Audit - Frontend Dev Server
cd /d "%~dp0\frontend"
echo ===================================================
echo Starting Specification Audit Frontend (Vite)...
echo ===================================================
cmd /c npm.cmd run dev
pause
