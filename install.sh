#!/bin/sh

echo "[INFO] Memulai proses instalasi Auto_airplane..."

# Cek root
if [ "$(id -u)" -ne 0 ]; then
    echo "[ERROR] Skrip harus dijalankan sebagai root!"
    exit 1
fi

# Cek dan instal dependensi satu per satu
echo "[STEP] Memeriksa dan memasang dependensi..."
opkg update || {
    echo "[ERROR] Gagal update package list"
    exit 1
}
for pkg in curl adb bind-tools; do
    opkg install "$pkg" || {
        echo "[ERROR] Gagal menginstal paket $pkg"
        exit 1
    }
done

# Path instalasi
INSTALL_DIR="/etc/auto_airplane"
mkdir -p "$INSTALL_DIR"
SCRIPT_PATH="$INSTALL_DIR/auto_airplane.sh"
CONFIG_PATH="$INSTALL_DIR/auto_airplane.env"
LOG_PATH="/var/log/auto_airplane.log"

# Unduh skrip utama
echo "[STEP] Mengunduh skript dari GitHub..."
SCRIPT_URL="https://raw.githubusercontent.com/Smarasanta/Auto_airplane/main/auto_airplane.sh"
if ! curl -fsSL "$SCRIPT_URL" -o "$SCRIPT_PATH"; then
    echo "[ERROR] Gagal mengunduh skrip utama"
    exit 1
fi
chmod +x "$SCRIPT_PATH"

# Input konfigurasi dengan validasi
while true; do
    read -p "[INPUT] Masukkan Telegram Bot Token: " TELEGRAM_TOKEN
    [ -n "$TELEGRAM_TOKEN" ] && break
    echo "[ERROR] Token tidak boleh kosong, coba lagi."
done

while true; do
    read -p "[INPUT] Masukkan Telegram Chat ID: " TELEGRAM_CHAT_ID
    [ -n "$TELEGRAM_CHAT_ID" ] && break
    echo "[ERROR] Chat ID tidak boleh kosong, coba lagi."
done

while true; do
    read -p "[INPUT] Masukkan Target Host (misal: google.com): " TARGET_HOST
    [ -n "$TARGET_HOST" ] && break
    echo "[ERROR] Target host tidak boleh kosong, coba lagi."
done

# Simpan konfigurasi dengan hak akses aman
{
    echo "TELEGRAM_TOKEN='$TELEGRAM_TOKEN'"
    echo "TELEGRAM_CHAT_ID='$TELEGRAM_CHAT_ID'"
    echo "TARGET_HOST='$TARGET_HOST'"
} > "$CONFIG_PATH"
chmod 600 "$CONFIG_PATH"

# Buat service init.d
SERVICE_PATH="/etc/init.d/auto_airplane"
cat > "$SERVICE_PATH" <<'EOF'
#!/bin/sh /etc/rc.common

USE_PROCD=1
START=99
STOP=15

start_service() {
    procd_open_instance
    procd_set_param command /bin/sh "/etc/auto_airplane/auto_airplane.sh"
    procd_set_param respawn
    procd_set_param stdout 1
    procd_set_param stderr 1
    procd_close_instance
}

stop_service() {
    pid=$(pgrep -f "/etc/auto_airplane/auto_airplane.sh")
    [ -n "$pid" ] && kill $pid
}
EOF

chmod +x "$SERVICE_PATH"
/etc/init.d/auto_airplane enable || {
    echo "[ERROR] Gagal mengaktifkan service"
    exit 1
}

# Setup log rotation di cron
echo "[STEP] Menyiapkan log rotation..."
if ! grep -q "auto_airplane.log" /etc/crontabs/root; then
    echo "*/30 * * * * [ -f $LOG_PATH ] && echo '' > $LOG_PATH 2>/dev/null" >> /etc/crontabs/root
    [ -x /etc/init.d/cron ] && /etc/init.d/cron restart
fi

# Jalankan service
echo "[INFO] Menjalankan service auto_airplane..."
/etc/init.d/auto_airplane start || {
    echo "[ERROR] Gagal memulai service"
    exit 1
}

echo "[DONE] Instalasi selesai."
echo "       Config: $CONFIG_PATH"
echo "       Log: $LOG_PATH"
