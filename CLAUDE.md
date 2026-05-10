# CLAUDE.md

File ini memberikan panduan kepada Claude Code (claude.ai/code) saat bekerja di repositori ini.

## Gambaran Proyek

Ini adalah setup **server AI chatbot lokal** untuk laptop Windows spesifikasi rendah (Intel i5-5200U, 10GB RAM, inferensi CPU-only). Stack ini mengekspos API kompatibel OpenAI ke jaringan LAN dan internet publik — semuanya gratis.

## Stack
python 3.11
| Komponen | Software | Port | Catatan |
|---|---|---|---|
| AI Runtime | Ollama | 11434 | CPU-only, tanpa inferensi GPU |
| Antarmuka Web | Open WebUI | 8080 | Diinstall via `pip install open-webui` |
| Tunnel Publik | Cloudflare Tunnel | — | Wajib pakai `--protocol http2`, bukan QUIC |

**Model yang digunakan:** `qwen2.5:3b` (kuantisasi Q4_K_M, ~2GB RAM)

## Menjalankan Stack

```bat
REM Jalankan semua sekaligus (Ollama + Open WebUI + Cloudflare Tunnel)
start_ai.bat
```

Atau manual di terminal terpisah:

```bat
REM 1. Ollama
"C:\Users\%USERNAME%\AppData\Local\Programs\Ollama\ollama.exe" serve

REM 2. Open WebUI
open-webui serve --host 0.0.0.0 --port 8080

REM 3. Cloudflare Tunnel — WAJIB pakai http2 agar tidak timeout
cloudflared tunnel --protocol http2 --url http://localhost:11434 --no-autoupdate
```

## Konfigurasi Penting

**Environment variable Ollama** (diset di System Environment Variables Windows, perlu restart):
```
OLLAMA_HOST=0.0.0.0:11434
OLLAMA_ORIGINS=*
OLLAMA_NUM_PARALLEL=1
OLLAMA_MAX_LOADED_MODELS=1
OLLAMA_NUM_THREAD=4
```

**Lokasi binary cloudflared:** `C:\cloudflared\cloudflared.exe`

## Penggunaan API

```
POST /v1/chat/completions   — Endpoint kompatibel OpenAI
GET  /api/tags              — Daftar model yang tersedia
```

Selalu gunakan `"stream": true` saat memanggil melalui Cloudflare Tunnel — inferensi CPU yang lambat menyebabkan Cloudflare membatalkan request non-streaming sebelum model selesai menjawab.

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

- **`cloudflared: not recognized`** — binary ada di `C:\cloudflared\cloudflared.exe`; gunakan full path atau tambahkan `C:\cloudflared` ke system PATH.
- **Error QUIC timeout** (`timeout: no recent network activity`) — selalu tambahkan `--protocol http2` saat menjalankan cloudflared.
- **`context canceled` di tunnel** — disebabkan inferensi CPU lambat melampaui idle timeout Cloudflare; gunakan `stream: true` di semua API call.
- **Ollama hanya listen di localhost** — `OLLAMA_HOST=0.0.0.0:11434` harus diset sebagai system env var (bukan user-level), lalu restart service Ollama.
