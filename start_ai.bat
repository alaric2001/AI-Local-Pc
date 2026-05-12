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
start "" cmd /k "cd /d C:\webui && open-webui serve --host 0.0.0.0 --port 8080"
timeout /t 3 /nobreak >nul

REM --- Start Tunneling Service ---
echo [3/3] Starting Tunneling Service...
echo    Waiting for tunnel URL...

REM --- Start Cloudflare Tunnel (HTTP2 to fix QUIC timeout) ---
@REM start "" cmd /k "cloudflared tunnel --protocol http2 --url http://localhost:11434 --no-autoupdate

REM [Opsi 1] Cloudflare Named Tunnel (Status: Aktif)
@REM start "" cmd /k "C:\cloudflared\cloudflared.exe tunnel --config C:\cloudflared\config.yml run"

REM [Opsi 2] Ngrok (Status: Aktif)
REM Konfigurasi Authtoken (Hanya perlu sekali, tapi aman dijalankan berulang)
ngrok config add-authtoken 2CON11PcsXfDAav7BunMcPK0H9H_7UAMNGQShadtVcmZ4Un55 >nul
start "" cmd /k "ngrok http --domain=cube-judicial-amber.ngrok-free.dev 11434"

REM [Opsi 3] Localhost.run via SSH (Status: Nonaktif) - Hapus 'REM' di bawah ini untuk mengaktifkan (berikan REM pada Opsi 1)
REM start "" cmd /k "ssh -R 80:localhost:11434 nokey@localhost.run"

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
