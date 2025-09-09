#!/bin/bash

# Test SSH persistence simulation
echo "🧪 SSH Persistence Test"
echo "======================"

# Create test environment
TEST_SOURCE="/mnt/DRU13/Books"
TEST_RUNID="persist_test_$(date +%s)"
TEMP_MOUNTPOINT="/tmp/persist_test_${TEST_RUNID}"

sudo mkdir -p "$TEMP_MOUNTPOINT"
sudo mount -t tmpfs -o size=100M tmpfs "$TEMP_MOUNTPOINT"

echo "Test Source: $TEST_SOURCE"
echo "Test Mount: $TEMP_MOUNTPOINT"
echo ""

# Start background process
echo "🔄 Starting background rsync with nohup..."
LOG_FILE="/tmp/persist_${TEST_RUNID}.log"
STATUS_FILE="/tmp/persist_${TEST_RUNID}.status"
PID_FILE="/tmp/persist_${TEST_RUNID}.pid"

nohup bash -c "
    echo \"\$(date) Background rsync started\" > '$LOG_FILE'
    echo \"\$(date) Process PID: \$\$\" >> '$LOG_FILE'
    
    # Simulate longer transfer by adding a delay
    echo \"\$(date) Starting rsync...\" >> '$LOG_FILE'
    sleep 2
    
    if rsync -ah --info=progress2 --no-i-r '$TEST_SOURCE/' '$TEMP_MOUNTPOINT/' 2>&1 | \\
       tee -a '$LOG_FILE'; then
        echo \"\$(date) Transfer completed successfully\" >> '$LOG_FILE'
        echo \"rsync_success=true\" > '$STATUS_FILE'
        echo \"rsync_completed_at=\$(date)\" >> '$STATUS_FILE'
    else
        echo \"\$(date) Transfer failed\" >> '$LOG_FILE'
        echo \"rsync_success=false\" > '$STATUS_FILE'
    fi
    
    rm -f '$PID_FILE'
" > /dev/null 2>&1 &

BG_PID=$!
echo "$BG_PID" > "$PID_FILE"

echo "✅ Background process started with PID: $BG_PID"
echo "📄 Log file: $LOG_FILE"
echo ""

# Simulate checking the process is running (as if we reconnected)
echo "🔍 Checking if background process is running..."
sleep 1

if kill -0 "$BG_PID" 2>/dev/null; then
    echo "✅ Background process still running (survives disconnection simulation)"
else
    echo "❌ Background process not running"
fi

# Wait for completion and show results
echo ""
echo "⏳ Waiting for completion..."
wait "$BG_PID"

echo ""
echo "📋 Final Results:"
echo "Log file contents:"
cat "$LOG_FILE"

echo ""
echo "Status file contents:"
cat "$STATUS_FILE" 2>/dev/null || echo "No status file found"

# Cleanup
echo ""
echo "🧹 Cleaning up..."
sudo umount "$TEMP_MOUNTPOINT" 2>/dev/null || true
sudo rmdir "$TEMP_MOUNTPOINT" 2>/dev/null || true
rm -f "$LOG_FILE" "$STATUS_FILE" "$PID_FILE"

echo "✅ SSH persistence test complete"
