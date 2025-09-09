#!/bin/bash

# Simple rsync function test
cd /media/tRAID/local/src/pooltool

# Define minimal test functions
test_foreground_rsync() {
    local source_path="$1"
    local temp_mountpoint="$2"
    local runid="$3"
    
    echo "🧪 Testing Foreground Rsync"
    echo "Source: $source_path"
    echo "Target: $temp_mountpoint"
    echo "Run ID: $runid"
    echo ""
    
    local start_time=$(date +%s)
    echo "⏰ Copy started at: $(date)"
    
    # Use sudo to copy with clean progress
    if sudo rsync -ah --info=progress2 --no-i-r "$source_path/" "$temp_mountpoint/"; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        local duration_human=$(date -u -d @$duration +"%-Hh %-Mm %-Ss")
        
        echo ""
        echo "✅ Copy completed successfully!"
        echo "⏰ Duration: $duration_human" 
        echo "📊 Final size: $(du -sh "$temp_mountpoint" | cut -f1)"
        
        # Store completion info for workflow
        echo "rsync_success=true" > "/tmp/pooltool_rsync_${runid}.status"
        echo "rsync_duration=$duration_human" >> "/tmp/pooltool_rsync_${runid}.status"
        echo "rsync_size=$(du -sh "$temp_mountpoint" | cut -f1)" >> "/tmp/pooltool_rsync_${runid}.status"
        return 0
    else
        local rsync_exit=$?
        echo ""
        echo "❌ Copy failed with exit code: $rsync_exit"
        echo "rsync_success=false" > "/tmp/pooltool_rsync_${runid}.status"
        echo "rsync_exit_code=$rsync_exit" >> "/tmp/pooltool_rsync_${runid}.status"
        return 1
    fi
}

test_background_rsync() {
    local source_path="$1"
    local temp_mountpoint="$2"
    local runid="$3"
    
    echo "🧪 Testing Background Rsync"
    echo "Source: $source_path"
    echo "Target: $temp_mountpoint"
    echo "Run ID: $runid"
    echo ""
    
    local log_file="/tmp/pooltool_rsync_${runid}.log"
    local status_file="/tmp/pooltool_rsync_${runid}.status"
    local pid_file="/tmp/pooltool_rsync_${runid}.pid"
    
    # Start background rsync with nohup
    echo "🔄 Starting background transfer with nohup..."
    
    # Create the background command
    nohup bash -c "
        source_path='$source_path'
        temp_mountpoint='$temp_mountpoint'
        runid='$runid'
        
        echo \"\$(date '+%Y-%m-%d %H:%M:%S') Background rsync started\" > '$log_file'
        echo \"\$(date '+%Y-%m-%d %H:%M:%S') Source: \$source_path\" >> '$log_file'
        echo \"\$(date '+%Y-%m-%d %H:%M:%S') Target: \$temp_mountpoint\" >> '$log_file'
        
        if rsync -ah --info=progress2 --no-i-r \"\$source_path/\" \"\$temp_mountpoint/\" 2>&1 | \\
           tee -a '$log_file'; then
            echo \"\$(date '+%Y-%m-%d %H:%M:%S') Transfer completed successfully\" >> '$log_file'
            echo \"rsync_success=true\" > '$status_file'
            echo \"rsync_duration=\$(date)\" >> '$status_file'
            echo \"rsync_size=\$(du -sh \$temp_mountpoint | cut -f1)\" >> '$status_file'
        else
            rsync_exit=\$?
            echo \"\$(date '+%Y-%m-%d %H:%M:%S') Transfer failed with exit code: \$rsync_exit\" >> '$log_file'
            echo \"rsync_success=false\" > '$status_file'
            echo \"rsync_exit_code=\$rsync_exit\" >> '$status_file'
        fi
        
        rm -f '$pid_file'
    " > /dev/null 2>&1 &
    
    # Store PID
    local bg_pid=$!
    echo "$bg_pid" > "$pid_file"
    
    echo "✅ Background transfer started!"
    echo "📋 Process ID: $bg_pid"
    echo "📄 Log file: $log_file"
    echo "📊 Status file: $status_file"
    echo ""
    echo "💡 Monitor with:"
    echo "   tail -f $log_file"
    echo "   cat $status_file"
    
    return 0
}

# Test parameters
TEST_SOURCE="/mnt/DRU13/Books"  # 13M test dataset
TEST_RUNID="test_$(date +%s)"
TEMP_MOUNTPOINT="/tmp/rsync_test_${TEST_RUNID}"

echo "🧪 Simple Rsync Testing Script"
echo "=============================="
echo "Test Source: $TEST_SOURCE ($(du -sh "$TEST_SOURCE" 2>/dev/null | cut -f1))"
echo "Test Mount: $TEMP_MOUNTPOINT"
echo "Run ID: $TEST_RUNID"
echo ""

# Create test mount point
sudo mkdir -p "$TEMP_MOUNTPOINT"

# Mount a small tmpfs for testing (faster than disk)
echo "📁 Creating test mount point..."
sudo mount -t tmpfs -o size=100M tmpfs "$TEMP_MOUNTPOINT"

echo ""
echo "Choose test mode:"
echo "1. [F]oreground - Test foreground rsync"
echo "2. [B]ackground - Test background rsync" 
echo "3. [C]ancel - Exit"
echo ""

read -p "Select mode [F/B/C]: " -n 1 -r choice
echo ""

case "$choice" in
    [Ff1])
        echo "🧪 Testing Foreground Mode..."
        echo ""
        if test_foreground_rsync "$TEST_SOURCE" "$TEMP_MOUNTPOINT" "$TEST_RUNID"; then
            echo ""
            echo "✅ Foreground test completed successfully!"
            echo "📊 Test results:"
            echo "   Target size: $(du -sh "$TEMP_MOUNTPOINT" 2>/dev/null | cut -f1)"
            echo "   File count: $(find "$TEMP_MOUNTPOINT" -type f | wc -l) files"
        else
            echo "❌ Foreground test failed"
        fi
        ;;
    [Bb2])
        echo "🧪 Testing Background Mode..."
        echo ""
        if test_background_rsync "$TEST_SOURCE" "$TEMP_MOUNTPOINT" "$TEST_RUNID"; then
            echo ""
            echo "✅ Background test initiated successfully!"
            echo "💡 Monitor with: tail -f /tmp/pooltool_rsync_${TEST_RUNID}.log"
            echo "💡 Check status: cat /tmp/pooltool_rsync_${TEST_RUNID}.status"
            echo ""
            echo "⏳ Waiting 10 seconds to check progress..."
            sleep 10
            
            if [[ -f "/tmp/pooltool_rsync_${TEST_RUNID}.status" ]]; then
                echo "📋 Current status:"
                cat "/tmp/pooltool_rsync_${TEST_RUNID}.status"
            else
                echo "⏳ Transfer still in progress..."
                echo "📋 Log preview:"
                tail -3 "/tmp/pooltool_rsync_${TEST_RUNID}.log" 2>/dev/null || echo "No log yet"
            fi
        else
            echo "❌ Background test failed to start"
        fi
        ;;
    [Cc3])
        echo "🔙 Test cancelled"
        ;;
    *)
        echo "❓ Invalid choice"
        ;;
esac

# Cleanup
echo ""
echo "🧹 Cleaning up..."
sudo umount "$TEMP_MOUNTPOINT" 2>/dev/null || true
sudo rmdir "$TEMP_MOUNTPOINT" 2>/dev/null || true
rm -f "/tmp/pooltool_rsync_${TEST_RUNID}".*

echo "✅ Test cleanup complete"
