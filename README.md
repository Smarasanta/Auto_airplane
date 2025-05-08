# Auto Airplane Mode Script for Android via ADB (OpenWrt)

Skrip ini secara otomatis memantau koneksi internet dari router OpenWrt. Jika tidak ada koneksi, maka akan mengaktifkan **mode pesawat** di perangkat Android (yang terhubung via ADB) selama 10 detik dan kemudian mematikannya, dengan tujuan menyegarkan koneksi jaringan.

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
curl -fsSL https://raw.githubusercontent.com/Smarasanta/Auto_airplane/main/install.sh | sh
