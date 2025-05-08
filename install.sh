#!/bin/sh

echo "[INFO] Memulai proses instalasi Auto_airplane BY SABDO PALON STORE..."

# Cek dan instal dependensi
echo "[STEP] Memeriksa dan memasang dependensi..."
opkg update
opkg install curl adb bind-tools

# Unduh skrip utama dari GitHub
SCRIPT_URL="https://raw.githubusercontent.com/Smarasanta/Auto_airplane/main/auto_airplane.sh"
INSTALL_PATH="/root/auto_airplane.sh"

echo "[STEP] Mengunduh skrip dari GitHub..."
curl -fsSL "$SCRIPT_URL" -o "$INSTALL_PATH"

# Ubah permission agar bisa dieksekusi
chmod +x "$INSTALL_PATH"

# Memasukkan ID Telegram dan Token Bot secara manual
echo "[INFO] Masukkan Telegram Bot Token Anda (dapatkan dari BotFather):"
read TELEGRAM_TOKEN

echo "[INFO] Masukkan ID Chat Telegram Anda (untuk mengirim notifikasi):"
read TELEGRAM_CHAT_ID

# Memasukkan Target Host secara manual
echo "[INFO] Masukkan alamat Target Host yang ingin diping (contoh: google.com atau ava.game.naver.com):"
read TARGET_HOST

# Menyimpan konfigurasi Telegram dan Target Host di auto_airplane.sh
echo "[STEP] Menyimpan konfigurasi ke skrip auto_airplane.sh..."
sed -i "s|^TELEGRAM_TOKEN=.*|TELEGRAM_TOKEN=\"$TELEGRAM_TOKEN\"|" "$INSTALL_PATH"
sed -i "s|^TELEGRAM_CHAT_ID=.*|TELEGRAM_CHAT_ID=\"$TELEGRAM_CHAT_ID\"|" "$INSTALL_PATH"
sed -i "s|^TARGET_HOST=.*|TARGET_HOST=\"$TARGET_HOST\"|" "$INSTALL_PATH"

# Tambahkan ke rc.local agar skrip berjalan otomatis saat boot
RCLOCAL="/etc/rc.local"
if ! grep -q "$INSTALL_PATH" "$RCLOCAL"; then
    echo "[STEP] Menambahkan ke /etc/rc.local agar otomatis saat boot..."
    sed -i "/^exit 0/i $INSTALL_PATH &" "$RCLOCAL"
else
    echo "[INFO] Skrip sudah terdaftar di rc.local"
fi

# Jalankan skrip untuk memastikan pengaturan berhasil
echo "[INFO] Menjalankan skrip auto_airplane.sh..."
"$INSTALL_PATH" &

echo "[DONE] Instalasi selesai. Skrip auto_airplane.sh sekarang berjalan!"
echo "[INFO] Skrip akan berjalan otomatis saat router reboot."
echo "[SCRIPT BY SABDO PALON STORE]"
