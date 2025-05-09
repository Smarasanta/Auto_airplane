#!/bin/sh

echo "[INFO] Memulai proses instalasi Auto_airplane BY SABDO PALON STORE..."

# Cek root
if [ "$(id -u)" -ne 0 ]; then
    echo "[ERROR] Skrip harus dijalankan sebagai root!"
    exit 1
fi

# Cek dan instal dependensi
echo "[STEP] Memeriksa dan memasang dependensi..."
opkg update || {
    echo "[ERROR] Gagal update package list"
    exit 1
}
opkg install curl adb bind-tools || {
    echo "[ERROR] Gagal menginstal dependensi"
    exit 1
}

# Path yang lebih sesuai
INSTALL_DIR="/etc/auto_airplane"
mkdir -p "$INSTALL_DIR"
SCRIPT_PATH="$INSTALL_DIR/auto_airplane.sh"
CONFIG_PATH="$INSTALL_DIR/auto_airplane.env"
LOG_PATH="/var/log/auto_airplane.log"

# Unduh skrip utama
echo "[STEP] Mengunduh skrip dari GitHub..."
SCRIPT_URL="https://raw.githubusercontent.com/Smarasanta/Auto_airplane/main/auto_airplane.sh"
if ! curl -fsSL "$SCRIPT_URL" -o "$SCRIPT_PATH"; then
    echo "[ERROR] Gagal mengunduh skrip utama"
    exit 1
fi
chmod +x "$SCRIPT_PATH"

# Input konfigurasi
echo "[INPUT] Masukkan Telegram Bot Token:"
read TELEGRAM_TOKEN
echo "[INPUT] Masukkan Telegram Chat ID:"
read TELEGRAM_CHAT_ID
echo "[INPUT] Masukkan Target Host (misal: google.com):"
read TARGET_HOST

# Simpan konfigurasi
cat <<EOF > "$CONFIG_PATH"
TELEGRAM_TOKEN='$TELEGRAM_TOKEN'
TELEGRAM_CHAT_ID='$TELEGRAM_CHAT_ID'
TARGET_HOST='$TARGET_HOST'
EOF

# Buat service init.d yang lebih baik
SERVICE_PATH="/etc/init.d/auto_airplane"
cat <<EOF > "$SERVICE_PATH"
#!/bin/sh /etc/rc.common

USE_PROCD=1
START=99
STOP=15

start_service() {
    procd_open_instance
    procd_set_param command /bin/sh "$SCRIPT_PATH"
    procd_set_param respawn
    procd_set_param stdout 1
    procd_set_param stderr 1
    procd_close_instance
}

stop_service() {
    pid=\$(pgrep -f "$SCRIPT_PATH")
    [ -n "\$pid" ] && kill \$pid
}
EOF

chmod +x "$SERVICE_PATH"
/etc/init.d/auto_airplane enable || {
    echo "[ERROR] Gagal mengaktifkan service"
    exit 1
}

# Setup log rotation
echo "[STEP] Menyiapkan log rotation..."
if ! grep -q "auto_airplane.log" /etc/crontabs/root; then
    echo "*/30 * * * * echo '' > $LOG_PATH 2>/dev/null" >> /etc/crontabs/root
    /etc/init.d/cron restart
fi

# Jalankan service
echo "[INFO] Menjalankan service auto_airplane..."
/etc/init.d/auto_airplane start || {
    echo "[ERROR] Gagal memulai service"
    exit 1
}

echo "[DONE] Instalasi selesai. Service auto_airplane aktif dan berjalan."
echo "       Log disimpan di: $LOG_PATH"
echo "       Konfigurasi ada di: $CONFIG_PATH"
