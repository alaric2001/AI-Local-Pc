# 🤖 AI Lokal di Laptop Sendiri

> Jalankan AI chatbot di laptop Windows biasa, tanpa GPU, tanpa biaya. Bisa diakses dari LAN maupun internet publik.

**Spesifikasi yang dipakai:** Windows

---

## ✨ Fitur

- **100% Gratis** — tidak ada API key berbayar, tidak ada cloud
- **Offline-ready** — jalan tanpa internet setelah model didownload
- **API kompatibel OpenAI** — tinggal ganti base URL di app yang sudah pakai OpenAI
- **Bisa diakses publik** — lewat Cloudflare Tunnel, gratis dan tanpa daftar akun
- **Web UI bawaan** — Open WebUI mirip ChatGPT, langsung bisa dipakai

---

## 🏗️ Arsitektur

```
Internet / LAN
      │
      ▼
┌─────────────────────────────────────────┐
│           Cloudflare Tunnel             │  ← URL publik otomatis
│     https://xxxx.trycloudflare.com      │
└──────────────┬──────────────────────────┘
               │ http2
               ▼
┌──────────────────────────┐
│   Ollama  :11434         │  ← API kompatibel OpenAI
│   (AI Runtime, CPU-only) │
└──────────┬───────────────┘
           │
           ▼
┌──────────────────────────┐
│   Open WebUI  :8080      │  ← Antarmuka web (mirip ChatGPT)
└──────────────────────────┘
```

---

## 🚀 Cara Setup (Dari Nol)

### 1. Install Ollama

Download dari [ollama.com](https://ollama.com) dan install. Verifikasi:

```powershell
ollama --version
```

### 2. Set Environment Variable

Buka PowerShell sebagai **Administrator**, jalankan:

```powershell
[System.Environment]::SetEnvironmentVariable("OLLAMA_HOST", "0.0.0.0:11434", "Machine")
[System.Environment]::SetEnvironmentVariable("OLLAMA_ORIGINS", "*", "Machine")
[System.Environment]::SetEnvironmentVariable("OLLAMA_NUM_PARALLEL", "1", "Machine")
[System.Environment]::SetEnvironmentVariable("OLLAMA_MAX_LOADED_MODELS", "1", "Machine")
[System.Environment]::SetEnvironmentVariable("OLLAMA_NUM_THREAD", "4", "Machine")
```

> ⚠️ Harus diset sebagai **System** (Machine-level), bukan user-level. Restart Ollama setelah ini.

### 3. Restart Ollama & Download Model

Restart service Ollama via **Task Manager → Services → ollama → Restart**, lalu:

```powershell
# Model ringan dan cepat (direkomendasikan untuk spek rendah)
ollama pull qwen2.5:3b

# Alternatif yang lebih pintar tapi lebih berat
ollama pull qwen2.5:7b
ollama pull deepseek-r1:8b
```

### 4. Install Open WebUI

```powershell
pip install open-webui
```

### 5. Install Cloudflare Tunnel

```powershell
New-Item -ItemType Directory -Force -Path C:\cloudflared
Invoke-WebRequest -Uri "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-windows-amd64.exe" -OutFile "C:\cloudflared\cloudflared.exe"
```

Tambahkan `C:\cloudflared` ke system PATH agar bisa dipakai dari mana saja.

---

## ▶️ Menjalankan

### Cara Cepat (Semua Sekaligus)

```bat
start_ai.bat
```

Script ini otomatis menjalankan Ollama, Open WebUI, dan Cloudflare Tunnel sekaligus.

### Manual (Terminal Terpisah)

```bat
REM Terminal 1 — Ollama
"C:\Users\%USERNAME%\AppData\Local\Programs\Ollama\ollama.exe" serve

REM Terminal 2 — Open WebUI
open-webui serve --host 0.0.0.0 --port 8080

REM Terminal 3 — Tunnel publik
cloudflared tunnel --protocol http2 --url http://localhost:11434 --no-autoupdate
```

Setelah jalan, lihat di window cloudflared untuk URL publik seperti:
```
https://striking-worldwide-prepaid-distributed.trycloudflare.com
```

---

## 🌐 Akses

| Tujuan | URL |
|---|---|
| Web UI (lokal) | http://localhost:8080 |
| Web UI (LAN) | http://\<IP-laptop\>:8080 |
| API (lokal) | http://localhost:11434 |
| API (publik) | URL dari window cloudflared |

> **Pertama kali buka Web UI:** buat akun di http://localhost:8080 — akun ini tersimpan lokal, bukan ke server mana pun.

Cari IP laptop untuk akses dari perangkat lain:
```powershell
ipconfig   # Lihat IPv4 Address di adapter WiFi/Ethernet
```

---

## 🔌 Penggunaan API

API 100% kompatibel OpenAI. Tinggal ganti `base_url` di aplikasi yang sudah pakai OpenAI SDK.

### Test Cepat (PowerShell)

```powershell
$body = @{
    model    = "qwen2.5:3b"
    messages = @(@{role = "user"; content = "Halo, siapa kamu?"})
    stream   = $false
} | ConvertTo-Json -Depth 5

Invoke-RestMethod -Uri "http://localhost:11434/v1/chat/completions" `
    -Method POST -ContentType "application/json" -Body $body
```

### Endpoint Tersedia

```
POST /v1/chat/completions   — Chat (kompatibel OpenAI)
GET  /api/tags              — Daftar model yang terinstall
```

### Body Lengkap (Direkomendasikan untuk Tunnel)

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

> ⚠️ **Wajib `stream: true` saat pakai tunnel** — inferensi CPU yang lambat bisa membuat Cloudflare memutus koneksi sebelum model selesai menjawab.

---

## ✅ Verifikasi

```powershell
# Cek Ollama listen di semua interface (harus ada 0.0.0.0:11434)
netstat -an | findstr "11434"

# Cek model yang sudah didownload
ollama list

# Test API Ollama
Invoke-RestMethod -Uri "http://localhost:11434/api/tags" -Method GET
```

---

## 🔧 Troubleshooting

| Masalah | Penyebab | Solusi |
|---|---|---|
| `cloudflared: not recognized` | Binary tidak ada di PATH | Tambahkan `C:\cloudflared` ke system PATH |
| `timeout: no recent network activity` | Pakai protokol QUIC | Tambahkan `--protocol http2` ke perintah cloudflared |
| `context canceled` di tunnel | Inferensi CPU terlalu lambat | Gunakan `stream: true` di semua API call |
| Ollama hanya bisa diakses dari localhost | Env var diset di user, bukan system | Set `OLLAMA_HOST` sebagai System env var, restart Ollama |

---

## 🔄 Alternatif Tunnel

Selain Cloudflare Tunnel, bisa juga pakai **ngrok**:

```powershell
# Expose Ollama API
ngrok http 11434

# Expose Open WebUI
ngrok http 8080
```

---

## 📦 Stack

| Software | Versi | Keterangan |
|---|---|---|
| Python | 3.11 | Runtime Open WebUI |
| Ollama | latest | AI runtime, CPU-only |
| Open WebUI | latest | Web interface |
| cloudflared | latest | Tunnel ke internet publik |
