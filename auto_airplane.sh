#!/bin/sh

# Konfigurasi
TARGET_HOST="ava.game.naver.com"
MAX_FAILURES=3
MAX_RETRIES=3
PING_TRIALS=3
SLEEP_BETWEEN_TRIALS=15
SLEEP_LOOP=3

# Telegram
TELEGRAM_BOT_TOKEN="7790428558:AAE1eG7vHK6U7jvdorSVVAH9YFPWWKZreTY"
TELEGRAM_CHAT_ID="8151047414"
send_telegram() {
    MESSAGE="$1"
    curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
        -d chat_id="$TELEGRAM_CHAT_ID" \
        -d text="$MESSAGE" > /dev/null
}

fail_count=0
echo "[INIT] Monitoring koneksi ke $TARGET_HOST..."
sleep 10

while true; do
    # Pastikan DNS bisa resolve
    nslookup "$TARGET_HOST" > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "[DNS] Gagal resolve $TARGET_HOST"
        fail_count=$((fail_count + 1))
    else
        success=0
        for i in $(seq 1 $PING_TRIALS); do
            /bin/ping -c 1 -W 1 "$TARGET_HOST" > /dev/null 2>&1
            if [ $? -eq 0 ]; then
                success=1
                break
            fi
            sleep 1
        done

        if [ "$success" -eq 1 ]; then
            echo "[INFO] Ping berhasil ke $TARGET_HOST"
            fail_count=0
        else
            echo "[WARN] Ping gagal ke $TARGET_HOST"
            fail_count=$((fail_count + 1))
        fi
    fi

    if [ "$fail_count" -ge "$MAX_FAILURES" ]; then
        echo "[ALERT] Tidak ada jaringan. Menjalankan siklus mode pesawat..."

        retry=1
        while [ "$retry" -le "$MAX_RETRIES" ]; do
            echo "[ACTION] Mode pesawat ON (percobaan ke-$retry)..."
            adb shell su -c 'settings put global airplane_mode_on 1'
            adb shell su -c 'am broadcast -a android.intent.action.AIRPLANE_MODE --ez state true'
            sleep 5

            echo "[ACTION] Mode pesawat OFF..."
            adb shell su -c 'settings put global airplane_mode_on 0'
            adb shell su -c 'am broadcast -a android.intent.action.AIRPLANE_MODE --ez state false'
            sleep 5

            echo "[ACTION] Restart data dan WiFi..."
            adb shell su -c 'svc data disable'
            sleep 2
            adb shell su -c 'svc data enable'
            sleep 5

            echo "[CHECK] Mengecek koneksi dari router..."
            nslookup "$TARGET_HOST" > /dev/null 2>&1
            if [ $? -ne 0 ]; then
                echo "[RETRY] DNS masih gagal."
                retry=$((retry + 1))
                sleep $SLEEP_BETWEEN_TRIALS
                continue
            fi

            success=0
            for i in $(seq 1 $PING_TRIALS); do
                /bin/ping -c 1 -W 1 "$TARGET_HOST" > /dev/null 2>&1
                if [ $? -eq 0 ]; then
                    success=1
                    break
                fi
                sleep 1
            done

            if [ "$success" -eq 1 ]; then
                echo "[RECOVERY] Koneksi pulih setelah percobaan ke-$retry."
                send_telegram "✅ Koneksi ke $TARGET_HOST berhasil dipulihkan setelah percobaan ke-$retry."
                fail_count=0
                break
            else
                echo "[RETRY] Koneksi belum pulih. Tunggu $SLEEP_BETWEEN_TRIALS detik..."
                retry=$((retry + 1))
                sleep $SLEEP_BETWEEN_TRIALS
            fi
        done

        if [ "$retry" -gt "$MAX_RETRIES" ]; then
            echo "[FAILED] Gagal pulihkan koneksi setelah $MAX_RETRIES percobaan."
        fi
    fi

    sleep $SLEEP_LOOP
done

