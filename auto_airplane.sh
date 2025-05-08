#!/bin/sh

# Konfigurasi (otomatis diisi saat instalasi)
TELEGRAM_TOKEN=""
TELEGRAM_CHAT_ID=""
TARGET_HOST=""

MAX_FAILURES=3
INTERVAL=5
MAX_RETRIES=3
fail_count=0

send_telegram() {
    local message="$1"
    curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendMessage" \
        -d chat_id="$TELEGRAM_CHAT_ID" \
        -d text="$message" > /dev/null
}

echo "[INIT] Monitoring koneksi ke $TARGET_HOST..."

while true; do
    ping -c 1 -W 1 "$TARGET_HOST" > /dev/null 2>&1

    if [ $? -eq 0 ]; then
        echo "[INFO] Ping berhasil ke $TARGET_HOST"
        fail_count=0
    else
        echo "[WARN] Ping gagal ke $TARGET_HOST"
        fail_count=$((fail_count + 1))
    fi

    if [ "$fail_count" -ge "$MAX_FAILURES" ]; then
        echo "[ALERT] Tidak ada jaringan. Menjalankan mode pesawat..."

        retry=1
        while [ "$retry" -le "$MAX_RETRIES" ]; do
            echo "[ACTION] Mode pesawat ON (percobaan ke-$retry)..."
            adb shell su -c 'settings put global airplane_mode_on 1'
            adb shell su -c 'am broadcast -a android.intent.action.AIRPLANE_MODE --ez state true'
            sleep 10

            echo "[ACTION] Mode pesawat OFF..."
            adb shell su -c 'settings put global airplane_mode_on 0'
            adb shell su -c 'am broadcast -a android.intent.action.AIRPLANE_MODE --ez state false'
            sleep 5

            echo "[CHECK] Mengecek koneksi..."
            ping -c 1 -W 2 "$TARGET_HOST" > /dev/null 2>&1
            if [ $? -eq 0 ]; then
                echo "[RECOVERY] Koneksi pulih setelah percobaan ke-$retry."
                send_telegram "[RECOVERY] Koneksi ke $TARGET_HOST berhasil dipulihkan!"
                fail_count=0
                break
            else
                echo "[RETRY] Belum pulih. Coba lagi..."
                retry=$((retry + 1))
            fi
        done

        if [ "$retry" -gt "$MAX_RETRIES" ]; then
            echo "[FAILED] Gagal pulihkan koneksi setelah $MAX_RETRIES percobaan."
        fi
    fi

    sleep "$INTERVAL"
done
