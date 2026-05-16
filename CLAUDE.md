# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Gambaran Proyek

Setup server AI chatbot lokal untuk laptop Windows spesifikasi rendah (Intel i5-5200U, 10GB RAM, inferensi CPU-only). Mengekspos API kompatibel OpenAI ke jaringan LAN dan internet publik — semuanya gratis.

## Stack (Python 3.11)

| Komponen | Software | Port | Catatan |
|---|---|---|---|
| AI Runtime | Ollama | 11434 | CPU-only, tanpa GPU |
| Antarmuka Web | Open WebUI | 8080 | `pip install open-webui`, data dir di `C:\webui` |
| Tunnel Publik | ngrok | — | Static domain `cube-judicial-amber.ngrok-free.dev`, binary di `C:\ngrok\ngrok.exe` |

**Model default:** `qwen2.5:3b` (kuantisasi Q4_K_M, ~2GB RAM). Alternatif: `qwen2.5:7b`, `deepseek-r1:8b` (lebih berat).

## Menjalankan Stack

```bat
REM Jalankan semua sekaligus (Ollama + Open WebUI + ngrok)
start_ai.bat
```

`start_ai.bat` menjalankan ngrok dengan static domain. ngrok harus ada di system PATH (`C:\ngrok` sudah ditambahkan ke PATH).

Manual di terminal terpisah:

```bat
REM 1. Ollama
"C:\Users\%USERNAME%\AppData\Local\Programs\Ollama\ollama.exe" serve

REM 2. Open WebUI — data dir wajib di C:\webui
cd /d C:\webui && open-webui serve --host 0.0.0.0 --port 8080

REM 3. ngrok dengan static domain
ngrok http --domain=cube-judicial-amber.ngrok-free.dev 11434
```

## Perintah Verifikasi (PowerShell)

```powershell
# Cek Ollama listen di semua interface
netstat -an | findstr "11434"   # Harus ada: 0.0.0.0:11434

# Daftar model yang sudah didownload
ollama list

# Test API native Ollama
Invoke-RestMethod -Uri "http://localhost:11434/api/tags" -Method GET

# Test endpoint kompatibel OpenAI
$body = @{
    model = "qwen2.5:3b"
    messages = @(@{role = "user"; content = "Halo"})
    stream = $false
} | ConvertTo-Json -Depth 5
Invoke-RestMethod -Uri "http://localhost:11434/v1/chat/completions" -Method POST -ContentType "application/json" -Body $body

# Cari IP LAN untuk test dari perangkat lain
ipconfig   # Lihat IPv4 Address di adapter WiFi/Ethernet
```

## Environment Variable Ollama

Harus diset sebagai **System** (Machine-level), bukan user-level. Perlu restart service Ollama setelah diset.

```
OLLAMA_HOST=0.0.0.0:11434
OLLAMA_ORIGINS=*
OLLAMA_NUM_PARALLEL=1
OLLAMA_MAX_LOADED_MODELS=1
OLLAMA_NUM_THREAD=4
```

PowerShell untuk set:
```powershell
[System.Environment]::SetEnvironmentVariable("OLLAMA_HOST", "0.0.0.0:11434", "Machine")
[System.Environment]::SetEnvironmentVariable("OLLAMA_ORIGINS", "*", "Machine")
```

## Penggunaan API

```
POST /v1/chat/completions   — Endpoint kompatibel OpenAI
GET  /api/tags              — Daftar model tersedia
```

Selalu gunakan `"stream": true` saat memanggil lewat tunnel — inferensi CPU lambat bisa menyebabkan koneksi timeout sebelum model selesai menjawab.

```json
{
  "model": "qwen2.5:3b",
  "messages": [{"role": "user", "content": "..."}],
  "stream": true,
  "options": {
    "num_ctx": 2048,
    "num_predict": 256,
    "num_thread": 4,
    "num_gpu": 0
  }
}
```

## Masalah yang Diketahui & Solusinya

- **`ngrok: not recognized`** — binary ada di `C:\ngrok\ngrok.exe`; tambahkan `C:\ngrok` ke system PATH.
- **ngrok error `authtoken`** — jalankan `ngrok config add-authtoken <token>` sekali di PowerShell.
- **ngrok domain tidak bisa diakses** — pastikan authtoken sudah dikonfigurasi dan static domain terdaftar di akun ngrok.
- **`context canceled` / timeout di tunnel** — inferensi CPU lambat; gunakan `stream: true` di semua API call.
- **Ollama hanya listen di localhost** — `OLLAMA_HOST=0.0.0.0:11434` harus diset sebagai system env var (bukan user), lalu restart service Ollama via Task Manager → Services.
- **`.webui_secret_key` dan database Open WebUI** — disimpan di `C:\webui`; Open WebUI harus dijalankan dari direktori tersebut (`cd /d C:\webui`) agar tidak tercecer ke folder lain.
