@echo off
cd /d "%~dp0"
node tiktok-bridge.js --test "Hat and Mustache" 30 1
echo.
echo Sent a test Hat and Mustache. Your first Pokemon should gain a level.
echo Check the BizHawk Lua Console for the message.
pause
