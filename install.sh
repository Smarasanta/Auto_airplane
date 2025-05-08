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

# Buat skrip init.d agar auto_airplane jadi service
SERVICE_PATH="/etc/init.d/auto_airplane"
cat <<EOF > "$SERVICE_PATH"
#!/bin/sh /etc/rc.common

START=99
STOP=15

start() {
    echo "Menjalankan auto_airplane..."
    /bin/sh $INSTALL_PATH &
}

stop() {
    echo "Menghentikan auto_airplane..."
    pkill -f $INSTALL_PATH
}
EOF

chmod +x "$SERVICE_PATH"
/etc/init.d/auto_airplane enable

# Setup log cleaner setiap 30 menit via cron
echo "[STEP] Menjadwalkan pembersihan log setiap 30 menit..."
crontab -l 2>/dev/null | grep -v 'auto_airplane.log' > /tmp/cron.tmp
echo "*/30 * * * * echo '' > $LOG_PATH" >> /tmp/cron.tmp
crontab /tmp/cron.tmp
rm /tmp/cron.tmp

# Jalankan service langsung
echo "[INFO] Menjalankan service auto_airplane..."
/etc/init.d/auto_airplane start

echo "[DONE] Instalasi selesai dan skrip sedang berjalan sebagai service."
