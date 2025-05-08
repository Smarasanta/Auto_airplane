# 📡 Auto Airplane Recovery Script for OpenWrt

Skrip shell untuk memantau koneksi internet dari router OpenWrt dan secara otomatis **mengaktifkan mode pesawat** pada perangkat Android melalui ADB jika koneksi terputus, lalu **memulihkannya secara otomatis** saat koneksi kembali normal.

---

## ✨ Fitur

- Ping ke hostname (misalnya `google.com`)
- Kontrol ADB ke Android (rooted) untuk ON/OFF mode pesawat
- Deteksi pemulihan koneksi otomatis
- Ulangi siklus hingga koneksi pulih (maks 3 kali)
- Notifikasi ke Telegram (jika token dan chat ID diset)
- Otomatis jalan saat boot via `rc.local` (opsional)
- Diuji di OpenWrt

---

## 🔧 Instalasi Otomatis

```sh
wget -O - https://raw.githubusercontent.com/USERNAME/auto-airplane-recovery/main/install_auto_airplane.sh | sh
