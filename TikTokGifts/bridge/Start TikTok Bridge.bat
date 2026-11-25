@echo off
cd /d "%~dp0"
title TikTok Gifts Bridge

where node >nul 2>nul
if errorlevel 1 (
  echo Node.js isn't installed. Download the LTS version from https://nodejs.org then try again.
  pause
  exit /b
)

echo Gifts come from the TikFinity Desktop app, or from TikOps webhooks sent to
echo http://localhost:21214/gift
echo Leave this window open while you stream.
echo.
node tiktok-bridge.js
pause
