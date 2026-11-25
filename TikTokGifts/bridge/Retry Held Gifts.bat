@echo off
cd /d "%~dp0"
node tiktok-bridge.js --retry
echo.
echo Held gifts will be retried in a moment. Check the BizHawk Lua Console.
pause
