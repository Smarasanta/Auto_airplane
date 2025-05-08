#!/bin/sh

echo "[INFO] Memulai proses instalasi Auto_airplane BY SABDO PALON STORE..."

# Cek dan instal dependensi
echo "[STEP] Memeriksa dan memasang dependensi..."
opkg update
opkg install curl adb bind-tools

# Unduh skrip utama dari GitHub
SCRIPT_URL="https://raw.githubusercontent.com/Smarasanta/Auto_airplane/main/auto_airplane.sh"
INSTALL_PATH="/root/auto_airplane.sh"
CONFIG_PATH="/root/auto_airplane.env"
LOG_PATH="/root/auto_airplane.log"

echo "[STEP] Mengunduh skrip dari GitHub..."
curl -fsSL "$SCRIPT_URL" -o "$INSTALL_PATH"
chmod +x "$INSTALL_PATH"

# Input manual konfigurasi
echo "[INPUT] Masukkan Telegram Bot Token:"
read TELEGRAM_TOKEN
echo "[INPUT] Masukkan Telegram Chat ID:"
read TELEGRAM_CHAT_ID
echo "[INPUT] Masukkan Target Host (misal: google.com):"
read TARGET_HOST

# Simpan ke file konfigurasi
cat <<EOF > "$CONFIG_PATH"
TELEGRAM_TOKEN='$TELEGRAM_TOKEN'
TELEGRAM_CHAT_ID='$TELEGRAM_CHAT_ID'
TARGET_HOST='$TARGET_HOST'
EOF

# Tambahkan ke rc.local jika belum ada
RCLOCAL="/etc/rc.local"
if ! grep -q "$INSTALL_PATH" "$RCLOCAL"; then
    echo "[STEP] Menambahkan skrip ke /etc/rc.local..."
    sed -i "/^exit 0/i $INSTALL_PATH &" "$RCLOCAL"
fi

# Setup log cleaner setiap 30 menit via cron
echo "[STEP] Menjadwalkan pembersihan log setiap 30 menit..."
crontab -l 2>/dev/null | grep -v 'auto_airplane.log' > /tmp/cron.tmp
echo "*/30 * * * * echo '' > $LOG_PATH" >> /tmp/cron.tmp
crontab /tmp/cron.tmp
rm /tmp/cron.tmp

# Jalankan skrip langsung
echo "[INFO] Menjalankan auto_airplane.sh..."
"$INSTALL_PATH" &

echo "[DONE] Instalasi selesai dan skrip sedang berjalan."
