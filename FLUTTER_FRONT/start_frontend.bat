@echo off
title Onion Smart Flutter Application
echo ============================================================
echo Starting Onion Smart Flutter Application
echo URL: http://localhost:8085
echo ============================================================
echo.
cd /d "C:\Users\vicky\Desktop\FLUTTER_FRONT"
python -m http.server 8085 --directory build/web
pause
