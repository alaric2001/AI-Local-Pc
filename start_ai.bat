@echo off
title AI Local Server
color 0A

echo ============================================
echo    LOCAL AI SERVER STARTER
echo ============================================
echo.

REM --- Start Ollama ---
echo [1/3] Starting Ollama API...
start "" "C:\Users\%USERNAME%\AppData\Local\Programs\Ollama\ollama.exe" serve
timeout /t 5 /nobreak >nul

REM --- Start Open WebUI ---
echo [2/3] Starting Open WebUI...
start "" cmd /k "open-webui serve --host 0.0.0.0 --port 8080"
timeout /t 3 /nobreak >nul

REM --- Start Cloudflare Tunnel (HTTP2 to fix QUIC timeout) ---
echo [3/3] Starting Cloudflare Tunnel (HTTP2 protocol)...
echo    Waiting for tunnel URL...
start "" cmd /k "cloudflared tunnel --protocol http2 --url http://localhost:11434 --no-autoupdate
"

echo.
echo ============================================
echo  STATUS:
echo    Ollama API (LAN) : http://%COMPUTERNAME%:11434
echo    Open WebUI (LAN) : http://%COMPUTERNAME%:8080
echo    Public tunnel    : Check cloudflared window
echo ============================================
echo.
echo  API Endpoint: POST [tunnel-url]/v1/chat/completions
echo  Model: qwen2.5:3b  (ganti sesuai model yang kamu download)
echo.
pause
