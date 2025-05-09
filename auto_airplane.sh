#!/bin/sh

. /root/auto_airplane.env

MAX_FAILURES=3
MAX_RETRIES=3
INTERVAL=3
fail_count=0
LOG_FILE="/root/auto_airplane.log"

echo "[INIT] Monitoring koneksi ke $TARGET_HOST..." | tee -a "$LOG_FILE"

while true; do
    for i in 1 2 3; do
        if ! ping -c 1 -W 1 "$TARGET_HOST" > /dev/null 2>&1 || \
           ! curl -X "HEAD" --connect-timeout 3 -so /dev/null "http://bing.com"; then
            echo "[WARN] Salah satu pemeriksaan koneksi gagal (ping atau curl)" | tee -a "$LOG_FILE"
            fail_count=$((fail_count + 1))
        else
            echo "[INFO] Pemeriksaan koneksi berhasil" | tee -a "$LOG_FILE"
            fail_count=0
        fi
        sleep "$INTERVAL"
    done

    if [ "$fail_count" -ge "$MAX_FAILURES" ]; then
        echo "[ALERT] Koneksi dianggap putus. Menjalankan siklus mode pesawat..." | tee -a "$LOG_FILE"

        retry=1
        while [ "$retry" -le "$MAX_RETRIES" ]; do
            echo "[ACTION] Mode pesawat ON (percobaan ke-$retry)..." | tee -a "$LOG_FILE"
            adb shell su -c 'settings put global airplane_mode_on 1'
            adb shell su -c 'am broadcast -a android.intent.action.AIRPLANE_MODE --ez state true'
            sleep 10

            echo "[ACTION] Mode pesawat OFF..." | tee -a "$LOG_FILE"
            adb shell su -c 'settings put global airplane_mode_on 0'
            adb shell su -c 'am broadcast -a android.intent.action.AIRPLANE_MODE --ez state false'
            sleep 5

            echo "[CHECK] Mengecek koneksi..." | tee -a "$LOG_FILE"
            if ping -c 1 -W 2 "$TARGET_HOST" > /dev/null 2>&1 || \
               curl -X "HEAD" --connect-timeout 3 -so /dev/null "http://bing.com"; then
                echo "[RECOVERY] Koneksi pulih setelah percobaan ke-$retry." | tee -a "$LOG_FILE"
                curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendMessage" \
                    -d chat_id="$TELEGRAM_CHAT_ID" \
                    -d text="✅ Koneksi ke $TARGET_HOST telah pulih pada $(date '+%Y-%m-%d %H:%M:%S')" > /dev/null
                fail_count=0
                break
            else
                echo "[RETRY] Koneksi belum pulih. Ulangi siklus..." | tee -a "$LOG_FILE"
                retry=$((retry + 1))
            fi
        done

        if [ "$retry" -gt "$MAX_RETRIES" ]; then
            echo "[FAILED] Gagal pulihkan koneksi setelah $MAX_RETRIES percobaan." | tee -a "$LOG_FILE"
        fi
    fi
done
