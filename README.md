# Auto_airplane

[![License: Custom](https://img.shields.io/badge/license-restricted-red)](./LICENSE)

## 🚫 License
This software is licensed under a **Custom Restricted License**.

- ✅ Free to use for personal/internal purposes  
- ❌ No redistribution  
- ❌ No modification or reverse engineering  
- ❌ No commercial use without permission

For commercial licensing or inquiries, contact: `smarasanta@example.com`

## 🔧 Fitur
- Ping otomatis ke host target dari router
- Jika gagal ping 3 kali berturut-turut, aktifkan mode pesawat via ADB
- Ulangi hingga maksimal 3 siklus jika koneksi belum pulih
- Kirim notifikasi ke Telegram saat koneksi kembali normal *(opsional, jika token diset)*
- Auto start saat boot router
- Auto install dengan konfigurasi hostname target

## 📦 Dependensi
- `adb`
- `curl`
- `bind-tools` (untuk `nslookup` atau `host`)

## 🚀 Instalasi

1. **Clone repository atau langsung jalankan via curl**:

```sh
curl -fsSL https://raw.githubusercontent.com/Smarasanta/Auto_airplane/main/install.sh -o install.sh
chmod +x install.sh
./install.sh
