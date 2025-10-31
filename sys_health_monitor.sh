#!/usr/bin/env bash
# sys_health_monitor.sh
# Simple system health monitor (CPU, MEM, DISK, Processes)
# Save: ~/monitoring/sys_health_monitor.sh
# Run: bash ~/monitoring/sys_health_monitor.sh

LOG_DIR="$HOME/monitoring"
LOG_FILE="$LOG_DIR/sys_health.log"
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

# Thresholds (customize)
CPU_THRESHOLD=80       # percent
MEM_THRESHOLD=80       # percent
DISK_THRESHOLD=85      # percent (on /)
# Process threshold: example ensure 'nginx' is running at least 1 instance
PROCESS_NAME="nginx"
PROCESS_MIN_COUNT=1

mkdir -p "$LOG_DIR"

# --- CPU usage (average of 1 minute using top)
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk -F',' '{print $1}' | awk '{print $2+$4+$6+$8}' 2>/dev/null)
# CPU_USAGE fallback using mpstat or /proc if parsing fails
if [ -z "$CPU_USAGE" ] || ! [[ $CPU_USAGE =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
  # Use mpstat if available, or /proc/stat quick calc (simple)
  CPU_USAGE=$(grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$4+$5)} END {printf "%.1f", usage}')
fi
CPU_USAGE=${CPU_USAGE%.*} # integer

# --- Memory usage (percent)
MEM_USAGE=$(free | awk '/Mem:/ {printf("%d", $3/$2 * 100)}')

# --- Disk usage (percent for /)
DISK_USAGE=$(df -h / | awk 'NR==2 {gsub("%","",$5); print $5}')

# --- Process check
PROCESS_COUNT=$(pgrep -c -f "$PROCESS_NAME" || true)

# Build message
MSG="$TIMESTAMP - CPU:${CPU_USAGE}% MEM:${MEM_USAGE}% DISK:${DISK_USAGE}% ${PROCESS_NAME}_count:${PROCESS_COUNT}"

ALERT=0
ALERT_MSG=""

if [ "$CPU_USAGE" -ge "$CPU_THRESHOLD" ]; then
  ALERT=1
  ALERT_MSG+="CPU usage high (${CPU_USAGE}% >= ${CPU_THRESHOLD}%) ; "
fi
if [ "$MEM_USAGE" -ge "$MEM_THRESHOLD" ]; then
  ALERT=1
  ALERT_MSG+="Memory usage high (${MEM_USAGE}% >= ${MEM_THRESHOLD}%) ; "
fi
if [ "$DISK_USAGE" -ge "$DISK_THRESHOLD" ]; then
  ALERT=1
  ALERT_MSG+="Disk usage high (${DISK_USAGE}% >= ${DISK_THRESHOLD}%) ; "
fi
if [ "$PROCESS_COUNT" -lt "$PROCESS_MIN_COUNT" ]; then
  ALERT=1
  ALERT_MSG+="${PROCESS_NAME} count low (${PROCESS_COUNT} < ${PROCESS_MIN_COUNT}) ; "
fi

# Logging
if [ "$ALERT" -eq 1 ]; then
  echo "$MSG ALERT: $ALERT_MSG" | tee -a "$LOG_FILE"
else
  echo "$MSG OK" >> "$LOG_FILE"
fi

# Optional: keep last 1000 lines
tail -n 1000 "$LOG_FILE" > "$LOG_FILE.tmp" && mv "$LOG_FILE.tmp" "$LOG_FILE"
