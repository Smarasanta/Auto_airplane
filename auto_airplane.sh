#!/bin/sh

# Load config
CONFIG_FILE="/etc/auto_airplane/auto_airplane.env"
if [ ! -f "$CONFIG_FILE" ]; then
    echo "[ERROR] Config file not found: $CONFIG_FILE" | tee -a "$LOG_FILE"
    exit 1
fi
. "$CONFIG_FILE"

# Settings
MAX_FAILURES=3
MAX_RETRIES=3
INTERVAL=3
fail_count=0
LOG_FILE="/var/log/auto_airplane.log"
TARGET_URL="http://$TARGET_HOST"  # Default to HTTP if no protocol specified

# Ensure log file exists
touch "$LOG_FILE"

echo "[INIT] Monitoring connection to $TARGET_HOST..." | tee -a "$LOG_FILE"

while true; do
    # Check connection (ping + HTTP)
    if ping -c 1 -W 1 "$TARGET_HOST"  && \
       curl -X "HEAD" --connect-timeout 3 -so "$TARGET_URL"; then
        echo "[OK] Connection check passed" | tee -a "$LOG_FILE"
        fail_count=0
    else
        echo "[WARN] Connection check failed (ping or HTTP)" | tee -a "$LOG_FILE"
        fail_count=$((fail_count + 1))
    fi

    sleep "$INTERVAL"

    # If max failures reached, trigger airplane mode
    if [ "$fail_count" -ge "$MAX_FAILURES" ]; then
        echo "[ALERT] Connection lost. Starting airplane mode cycle..." | tee -a "$LOG_FILE"

        retry=1
        success=0
        while [ "$retry" -le "$MAX_RETRIES" ]; do
            echo "[TRY $retry] Enabling airplane mode..." | tee -a "$LOG_FILE"
            if ! adb shell su -c 'settings put global airplane_mode_on 1' || \
               ! adb shell su -c 'am broadcast -a android.intent.action.AIRPLANE_MODE --ez state true'; then
                echo "[ERROR] Failed to enable airplane mode!" | tee -a "$LOG_FILE"
            fi

            sleep 10

            echo "[TRY $retry] Disabling airplane mode..." | tee -a "$LOG_FILE"
            if ! adb shell su -c 'settings put global airplane_mode_on 0' || \
               ! adb shell su -c 'am broadcast -a android.intent.action.AIRPLANE_MODE --ez state false'; then
                echo "[ERROR] Failed to disable airplane mode!" | tee -a "$LOG_FILE"
            fi

            sleep 5

            # Verify connection
            if ping -c 1 -W 2 "$TARGET_HOST" > /dev/null 2>&1 && \
               curl -X "HEAD" --connect-timeout 3 -so /dev/null "$TARGET_URL"; then
                echo "[SUCCESS] Connection restored after try $retry" | tee -a "$LOG_FILE"
                if [ -n "$TELEGRAM_TOKEN" ] && [ -n "$TELEGRAM_CHAT_ID" ]; then
                    curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendMessage" \
                         -d chat_id="$TELEGRAM_CHAT_ID" \
                         -d text="✅ Connection to $TARGET_HOST restored at $(date '+%Y-%m-%d %H:%M:%S')" > /dev/null
                fi
                success=1
                break
            else
                echo "[RETRY] Connection still down. Retrying..." | tee -a "$LOG_FILE"
                retry=$((retry + 1))
            fi
        done

        if [ "$success" -eq 0 ]; then
            echo "[FAILED] Could not restore connection after $MAX_RETRIES tries." | tee -a "$LOG_FILE"
            if [ -n "$TELEGRAM_TOKEN" ] && [ -n "$TELEGRAM_CHAT_ID" ]; then
                curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendMessage" \
                     -d chat_id="$TELEGRAM_CHAT_ID" \
                     -d text="❌ FAILED to restore connection to $TARGET_HOST after $MAX_RETRIES tries!" > /dev/null
            fi
        fi

        fail_count=0  # Reset counter after recovery attempt
    fi
done
