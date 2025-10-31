#!/bin/bash
# Log File Analyzer Script - Accuknox Assignment
# Author: Preethi
# Description: Analyzes web server logs for 404 errors, top pages, and top IPs.
# Usage: bash log_analyzer.sh <path-to-log-file>

LOG_FILE=$1
REPORT_DIR=~/monitoring
REPORT_FILE="$REPORT_DIR/log_report_$(date +%F).txt"

# Default log file path if none given
if [ -z "$LOG_FILE" ]; then
    LOG_FILE="/var/log/nginx/access.log"
fi

# Check if the log file exists
if [ ! -f "$LOG_FILE" ]; then
    echo "ERROR: Log file not found: $LOG_FILE"
    echo "Usage: bash log_analyzer.sh <path-to-log-file>"
    exit 1
fi

# Create report directory if not exists
mkdir -p "$REPORT_DIR"

# Start writing report
echo "----------------------------------------" > "$REPORT_FILE"
echo "Log File Analysis Report" >> "$REPORT_FILE"
echo "Date: $(date)" >> "$REPORT_FILE"
echo "Log File: $LOG_FILE" >> "$REPORT_FILE"
echo "----------------------------------------" >> "$REPORT_FILE"

# 1️⃣ Total number of requests
TOTAL_REQUESTS=$(wc -l < "$LOG_FILE")
echo "Total requests: $TOTAL_REQUESTS" >> "$REPORT_FILE"

# 2️⃣ Count of 404 errors
ERROR_404=$(grep " 404 " "$LOG_FILE" | wc -l)
echo "404 errors: $ERROR_404" >> "$REPORT_FILE"

# 3️⃣ Top 5 requested pages
echo -e "\nTop 5 Requested Pages:" >> "$REPORT_FILE"
awk '{print $7}' "$LOG_FILE" | sort | uniq -c | sort -nr | head -5 >> "$REPORT_FILE"

# 4️⃣ Top 5 IP addresses
echo -e "\nTop 5 IP Addresses:" >> "$REPORT_FILE"
awk '{print $1}' "$LOG_FILE" | sort | uniq -c | sort -nr | head -5 >> "$REPORT_FILE"

echo "----------------------------------------" >> "$REPORT_FILE"
echo "Report saved to: $REPORT_FILE"

# Print report summary on screen
cat "$REPORT_FILE"
