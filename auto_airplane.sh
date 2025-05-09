#!/bin/sh

# Load config
CONFIG_FILE="/etc/auto_airplane/auto_airplane.env"
LOG_FILE="/var/log/auto_airplane.log"
MAX_LOG_SIZE=1048576  # 1 MB

if [ ! -f "$CONFIG_FILE" ]; then
    echo "[ERROR] Config file not found: $CONFIG_FILE" | tee -a "$LOG_FILE"
    exit 1
fi
. "$CONFIG_FILE"

if ! command -v adb >/dev/null 2>&1; then
    echo "[ERROR] adb command not found!" | tee -a "$LOG_FILE"
    exit 1
fi

if [ -z "$TARGET_HOST" ]; then
    echo "[ERROR] TARGET_HOST is not set in config!" | tee -a "$LOG_FILE"
    exit 1
fi

MAX_FAILURES=3
MAX_RETRIES=3
INTERVAL=3
fail_count=0
TARGET_URL="$TARGET_HOST"

touch "$LOG_FILE"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

rotate_log() {
    if [ "$(stat -c %s "$LOG_FILE")" -ge "$MAX_LOG_SIZE" ]; then
        mv "$LOG_FILE" "$LOG_FILE.old"
        touch "$LOG_FILE"
        log "[INFO] Log rotated: $LOG_FILE.old"
    fi
}

check_if_home() {
    display_status=$(adb shell dumpsys power | grep "mHoldingDisplaySuspendBlocker" || true)
    if echo "$display_status" | grep -iq "true"; then
        return 0  # layar hidup, dianggap sudah di home
    else
        return 1  # layar mati, dianggap bukan di home
    fi
}

log "[INIT] Monitoring connection to $TARGET_HOST..."

while true; do
    rotate_log

    AIRPLANE_STATE=$(adb shell settings get global airplane_mode_on | tr -d '\r')
    if [ "$AIRPLANE_STATE" = "1" ]; then
        log "[INFO] Device is in airplane mode, skipping connection check"
        sleep "$INTERVAL"
        continue
    fi

    if ping -c 1 -W 5 "$TARGET_HOST" >/dev/null 2>&1 && \
       curl -X "HEAD" --connect-timeout 5 -so /dev/null "$TARGET_URL"; then
        log "[OK] Connection check passed"
        fail_count=0
    else
        log "[WARN] Connection check failed (ping or HTTP)"
        fail_count=$((fail_count + 1))
    fi

    sleep "$INTERVAL"

    if [ "$fail_count" -ge "$MAX_FAILURES" ]; then
        log "[ALERT] Connection lost. Preparing airplane mode cycle..."

        retry=1
        success=0
        while [ "$retry" -le "$MAX_RETRIES" ]; do
            # Check if already at home
            if check_if_home; then
                log "[INFO] Device is already at home screen, skipping unlock"
            else
                log "[ACTION] Waking up and unlocking the device"
                adb shell input keyevent KEYCODE_WAKEUP
                adb shell input keyevent 82
                sleep 2
            fi

            log "[TRY $retry] Enabling airplane mode..."
            if ! adb shell su -c 'settings put global airplane_mode_on 1' || \
               ! adb shell su -c 'am broadcast -a android.intent.action.AIRPLANE_MODE --ez state true'; then
                log "[ERROR] Failed to enable airplane mode!"
            fi

            sleep 5

            log "[TRY $retry] Disabling airplane mode..."
            if ! adb shell su -c 'settings put global airplane_mode_on 0' || \
               ! adb shell su -c 'am broadcast -a android.intent.action.AIRPLANE_MODE --ez state false'; then
                log "[ERROR] Failed to disable airplane mode!"
            fi

            sleep 15

            if ping -c 1 -W 10 "$TARGET_HOST" >/dev/null 2>&1 && \
               curl -X "HEAD" --connect-timeout 10 -so /dev/null "$TARGET_URL"; then
                log "[SUCCESS] Connection restored after try $retry"
                if [ -n "$TELEGRAM_TOKEN" ] && [ -n "$TELEGRAM_CHAT_ID" ]; then
                    curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendMessage" \
                         -d chat_id="$TELEGRAM_CHAT_ID" \
                         -d text="✅ Connection to $TARGET_HOST restored at $(date '+%Y-%m-%d %H:%M:%S')" >/dev/null
                fi
                success=1
                break
            else
                log "[RETRY] Connection still down. Retrying..."
                retry=$((retry + 1))
            fi
        done

        if [ "$success" -eq 0 ]; then
            log "[FAILED] Could not restore connection after $MAX_RETRIES tries."
            if [ -n "$TELEGRAM_TOKEN" ] && [ -n "$TELEGRAM_CHAT_ID" ]; then
                curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendMessage" \
                     -d chat_id="$TELEGRAM_CHAT_ID" \
                     -d text="❌ FAILED to restore connection to $TARGET_HOST after $MAX_RETRIES tries!" >/dev/null
            fi
        fi

        fail_count=0
    fi
done
