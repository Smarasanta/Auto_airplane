#!/bin/sh

echo "[INFO] Memulai instalasi Auto_airplane BY SABDO PALON STORE..."

# Cek dan instal dependensi
echo "[STEP] Memeriksa dan memasang dependensi..."
opkg update
opkg install curl adb bind-tools

# Unduh skrip utama dari GitHub
SCRIPT_URL="https://raw.githubusercontent.com/Smarasanta/Auto_airplane/main/auto_airplane.sh"
INSTALL_PATH="/root/auto_airplane.sh"
LOG_PATH="/root/auto_airplane.log"

echo "[STEP] Mengunduh skrip dari GitHub..."
curl -fsSL "$SCRIPT_URL" -o "$INSTALL_PATH"

chmod +x "$INSTALL_PATH"

# Input manual
read -r -p "[INPUT] Masukkan Telegram Bot Token: " TELEGRAM_TOKEN
read -r -p "[INPUT] Masukkan Telegram Chat ID: " TELEGRAM_CHAT_ID
read -r -p "[INPUT] Masukkan Target Host (contoh: google.com): " TARGET_HOST

# Simpan konfigurasi ke dalam skrip
sed -i "s|^TELEGRAM_TOKEN=.*|TELEGRAM_TOKEN=\"$TELEGRAM_TOKEN\"|" "$INSTALL_PATH"
sed -i "s|^TELEGRAM_CHAT_ID=.*|TELEGRAM_CHAT_ID=\"$TELEGRAM_CHAT_ID\"|" "$INSTALL_PATH"
sed -i "s|^TARGET_HOST=.*|TARGET_HOST=\"$TARGET_HOST\"|" "$INSTALL_PATH"

# Tambahkan ke /etc/rc.local jika belum ada
RCLOCAL="/etc/rc.local"
if ! grep -q "$INSTALL_PATH" "$RCLOCAL"; then
    sed -i "/^exit 0/i $INSTALL_PATH >> $LOG_PATH 2>&1 &" "$RCLOCAL"
fi

chmod +x "$RCLOCAL"

# Tambahkan cron untuk bersihkan log tiap 30 menit
( crontab -l 2>/dev/null | grep -v "truncate" ; echo "*/30 * * * * truncate -s 0 $LOG_PATH" ) | crontab -

# Jalankan skrip sekarang
echo "[INFO] Menjalankan auto_airplane.sh..."
"$INSTALL_PATH" >> "$LOG_PATH" 2>&1 &

echo "[DONE] Instalasi selesai. Log di $LOG_PATH"
