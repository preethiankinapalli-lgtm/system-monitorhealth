#!/bin/bash
# log_analyzer.sh
# Simple Log File Analyzer (Bash)
# Usage: bash log_analyzer.sh <path-to-log-file>
# If no path provided, default = /var/log/nginx/access.log

set -euo pipefail

LOG_FILE="${1:-/var/log/nginx/access.log}"   # default if not provided
OUT_DIR="${2:-$HOME/monitoring}"
REPORT_FILE="$OUT_DIR/log_report_$(date +%F).txt"

mkdir -p "$OUT_DIR"

# Check file exists and readable
if [ ! -f "$LOG_FILE" ]; then
  echo "ERROR: Log file not found: $LOG_FILE"
  echo "Usage: bash log_analyzer.sh /path/to/access.log"
  exit 1
fi

if [ ! -r "$LOG_FILE" ]; then
  echo "ERROR: Log file not readable: $LOG_FILE"
  echo "Tip: you may need to run with sudo if it's in /var/log"
  exit 1
fi

echo "Analyzing: $LOG_FILE"
echo "Report: $REPORT_FILE"

{
  echo "----------------------------------------"
  echo "Log Analysis Report"
  echo "Generated: $(date)"
  echo "Source: $LOG_FILE"
  echo "----------------------------------------"

  # Total requests (lines)
  TOTAL=$(wc -l < "$LOG_FILE" | tr -d ' ')
  echo "Total requests: $TOTAL"

  # Count 404 responses (status code column)
  # Try robust awk scan for a 3-digit status code near the request
  NOTFOUND=$(awk '{ for(i=1;i<=NF;i++) if($i ~ /^[0-9]{3}$/){ if($i==404) c++ ; break } } END{print c+0}' "$LOG_FILE")
  echo "404 errors: $NOTFOUND"

  # Top requested pages (attempt to extract the request path)
  echo
  echo "Top 10 requested pages (path) with counts:"
  awk '{print $7}' "$LOG_FILE" 2>/dev/null | sort | uniq -c | sort -nr | head -n 10

  # Top IP addresses
  echo
  echo "Top 10 IP addresses with most requests:"
  awk '{print $1}' "$LOG_FILE" | sort | uniq -c | sort -nr | head -n 10

  # Top 5 user agents (combined log format; optional)
  echo
  echo "Top 5 User Agents (if available):"
  awk -F\" '{ if($6!="") print $6 }' "$LOG_FILE" 2>/dev/null | sort | uniq -c | sort -nr | head -n 5

  echo "----------------------------------------"
} > "$REPORT_FILE"

echo "Report saved to: $REPORT_FILE"
echo
# show the start of the report on screen
head -n 50 "$REPORT_FILE" || true

