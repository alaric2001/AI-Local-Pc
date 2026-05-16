# 🤖 AI Lokal di Laptop Sendiri

> Jalankan AI chatbot di laptop Windows biasa, tanpa GPU, tanpa biaya. Bisa diakses dari LAN maupun internet publik.

**Spesifikasi yang dipakai:** Windows

---

## ✨ Fitur

- **100% Gratis** — tidak ada API key berbayar, tidak ada cloud
- **Offline-ready** — jalan tanpa internet setelah model didownload
- **API kompatibel OpenAI** — tinggal ganti base URL di app yang sudah pakai OpenAI
- **URL publik permanen** — lewat ngrok static domain, tidak berubah meski restart
- **Web UI bawaan** — Open WebUI mirip ChatGPT, langsung bisa dipakai

---

## 🏗️ Arsitektur

```
Internet / LAN
      │
      ▼
┌─────────────────────────────────────────┐
│               ngrok Tunnel              │  ← URL publik permanen
│   https://cube-judicial-amber.ngrok-    │
│              free.dev                   │
└──────────────┬──────────────────────────┘
               │
               ▼
┌──────────────────────────┐
│   Ollama  :11434         │  ← API kompatibel OpenAI
│   (AI Runtime, CPU-only) │
└──────────┬───────────────┘
           │
           ▼
┌──────────────────────────┐
│   Open WebUI  :8080      │  ← Antarmuka web (mirip ChatGPT)
│   Data dir: C:\webui     │
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
New-Item -ItemType Directory -Force -Path C:\webui
```

> Semua data Open WebUI (database, secret key, uploads) disimpan di `C:\webui`.

### 5. Install ngrok

1. Download dari [ngrok.com/download](https://ngrok.com/download) (pilih Windows) dan ekstrak ke `C:\ngrok\`
2. Tambahkan `C:\ngrok` ke system PATH
3. Daftar akun gratis di [ngrok.com](https://ngrok.com), ambil authtoken dari dashboard
4. Konfigurasi authtoken (sekali saja):

```powershell
ngrok config add-authtoken <TOKEN-DARI-DASHBOARD>
```

5. Di dashboard ngrok → **Cloud Edge → Domains** → ambil 1 static domain gratis

---

## ▶️ Menjalankan

### Cara Cepat (Semua Sekaligus)

```bat
start_ai.bat
```

Script ini otomatis menjalankan Ollama, Open WebUI, dan ngrok tunnel sekaligus.

### Manual (Terminal Terpisah)

```bat
REM Terminal 1 — Ollama
"C:\Users\%USERNAME%\AppData\Local\Programs\Ollama\ollama.exe" serve

REM Terminal 2 — Open WebUI
cd /d C:\webui && open-webui serve --host 0.0.0.0 --port 8080

REM Terminal 3 — ngrok tunnel (URL permanen)
ngrok http --domain=cube-judicial-amber.ngrok-free.dev 11434
```

---

## 🌐 Akses

| Tujuan | URL |
|---|---|
| Web UI (lokal) | http://localhost:8080 |
| Web UI (LAN) | http://\<IP-laptop\>:8080 |
| API (lokal) | http://localhost:11434 |
| API (publik) | https://cube-judicial-amber.ngrok-free.dev |

> **Pertama kali buka Web UI:** buat akun di http://localhost:8080 — akun ini tersimpan lokal di `C:\webui`, bukan ke server mana pun.

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

> ⚠️ **Gunakan `stream: true` saat pakai tunnel** — inferensi CPU yang lambat bisa menyebabkan koneksi timeout sebelum model selesai menjawab.

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
| `ngrok: not recognized` | Binary tidak ada di PATH | Tambahkan `C:\ngrok` ke system PATH |
| ngrok error authtoken | Authtoken belum dikonfigurasi | Jalankan `ngrok config add-authtoken <token>` |
| Domain ngrok tidak bisa diakses | Static domain belum terdaftar | Cek di dashboard ngrok → Domains |
| `context canceled` / timeout | Inferensi CPU terlalu lambat | Gunakan `stream: true` di semua API call |
| Ollama hanya bisa diakses dari localhost | Env var diset di user, bukan system | Set `OLLAMA_HOST` sebagai System env var, restart Ollama |
| Open WebUI simpan file di tempat salah | Tidak jalan dari `C:\webui` | Pastikan perintah diawali `cd /d C:\webui` |

---

## 📦 Stack

| Software | Versi | Keterangan |
|---|---|---|
| Python | 3.11 | Runtime Open WebUI |
| Ollama | latest | AI runtime, CPU-only |
| Open WebUI | latest | Web interface, data di `C:\webui` |
| ngrok | latest | Tunnel ke internet publik, static domain |
