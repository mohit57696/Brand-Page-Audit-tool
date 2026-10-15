@echo off
setlocal
cd /d "%~dp0"
echo Setting up Specification Audit Tool...
if exist ".venv\Scripts\python.exe" goto install
py -3 -m venv .venv
if not errorlevel 1 goto install
python -m venv .venv
if errorlevel 1 goto failed
:install
".venv\Scripts\python.exe" -m pip install -r backend\requirements.txt
if errorlevel 1 goto failed
if exist "frontend\dist\index.html" goto configured
where npm.cmd >nul 2>nul
if errorlevel 1 goto missingnode
call npm.cmd ci --prefix frontend --no-audit --no-fund
if errorlevel 1 goto failed
call npm.cmd run build --prefix frontend
if errorlevel 1 goto failed
:configured
if not exist "backend\.env" copy /y "backend\.env.example" "backend\.env" >nul
echo.
echo Setup complete. Configure your API key in backend\.env.
echo Copy the three input data files into input, then double-click start.bat.
pause
exit /b 0
:missingnode
echo Install Node.js 22 LTS, reopen this folder and run Setup.bat again.
pause
exit /b 1
:failed
echo Setup failed. Python 3.14 and Node.js 22 are recommended.
echo Review the error above, then run Setup.bat again.
pause
exit /b 1
