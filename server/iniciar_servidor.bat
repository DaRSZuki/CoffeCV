@echo off
cd /d "%~dp0"
echo Direcciones IP de esta PC (use una de estas en la app desde un telefono real):
ipconfig | findstr /i "IPv4"
echo.
.venv\Scripts\python -m uvicorn app:app --host 0.0.0.0 --port 8000
