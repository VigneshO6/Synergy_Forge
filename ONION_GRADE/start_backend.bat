@echo off
title Onion Smart AI Backend Server
echo ============================================================
echo Starting Onion Smart AI Backend Server
echo Location: %~dp0backend
echo Models:   YOLO11 + MobileNetV3 (Zero Overlap, 4-Class)
echo URL:      http://127.0.0.1:8000 (Swagger: http://127.0.0.1:8000/docs)
echo ============================================================
echo.
cd /d "%~dp0backend"
python -m uvicorn main:app --host 0.0.0.0 --port 8000 --reload
pause
