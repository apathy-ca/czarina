#!/bin/bash
# Start Czar Watchdog - Continuous monitoring with alerts

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
LOG_FILE="$SCRIPT_DIR/czar-watchdog.log"
ALERT_FILE="$SCRIPT_DIR/czar-alerts.txt"

echo "🎭 Starting Czar Watchdog (checking every 5 minutes)"
echo "   Log: $LOG_FILE"
echo "   Alerts: $ALERT_FILE"
echo ""

# Clear old alerts
> "$ALERT_FILE"

# Run initial check
"$SCRIPT_DIR/czar-watchdog.sh"

# Continuous monitoring loop
while true; do
    sleep 300  # 5 minutes
    
    echo "" >> "$LOG_FILE"
    echo "========================================" >> "$LOG_FILE"
    
    # Run watchdog
    if ! "$SCRIPT_DIR/czar-watchdog.sh"; then
        # Issues detected - create alert
        TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
        echo "[$TIMESTAMP] 🚨 CZAR ATTENTION NEEDED" >> "$ALERT_FILE"
        echo "See $LOG_FILE for details" >> "$ALERT_FILE"
        echo "" >> "$ALERT_FILE"
        
        # Also print to console
        echo ""
        echo "🚨🚨🚨 ALERT: Worker issues detected! 🚨🚨🚨"
        echo "Check: $ALERT_FILE"
        echo ""
    fi
done
