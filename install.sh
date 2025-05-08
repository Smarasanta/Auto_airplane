#!/bin/sh

echo "[INFO] Mulai proses instalasi auto_airplane..."

# Cek dan instal dependensi
echo "[STEP] Memeriksa dan memasang dependensi..."
opkg update
opkg install curl adb bind-tools

# Tanya user untuk memasukkan target host
read -p "Masukkan hostname target untuk diping (contoh: google.com): " TARGET_HOST

# Unduh skrip utama dari GitHub
SCRIPT_URL="https://raw.githubusercontent.com/Smarasanta/Auto_airplane/main/auto_airplane.sh"
INSTALL_PATH="/root/auto_airplane.sh"

echo "[STEP] Mengunduh skrip dari GitHub..."
curl -fsSL "$SCRIPT_URL" -o "$INSTALL_PATH"

# Sisipkan TARGET_HOST ke dalam skrip
echo "[STEP] Mengatur hostname target dalam skrip..."
sed -i "s|^TARGET_HOST=.*|TARGET_HOST=\"$TARGET_HOST\"|" "$INSTALL_PATH"

# Ubah permission agar bisa dieksekusi
chmod +x "$INSTALL_PATH"

# Tambahkan ke rc.local jika belum ada
RCLOCAL="/etc/rc.local"
if ! grep -q "$INSTALL_PATH" "$RCLOCAL"; then
    echo "[STEP] Menambahkan ke /etc/rc.local agar otomatis saat boot..."
    sed -i "/^exit 0/i $INSTALL_PATH &" "$RCLOCAL"
else
    echo "[INFO] Skrip sudah terdaftar di rc.local"
fi

# Jalankan skrip langsung setelah instalasi
echo "[STEP] Menjalankan skrip auto_airplane.sh sekarang..."
"$INSTALL_PATH" &

echo "[DONE] Instalasi selesai dan skrip dijalankan dengan target: $TARGET_HOST"
