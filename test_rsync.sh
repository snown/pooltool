#!/bin/bash

# Test script for enhanced rsync functionality
# Uses small test data instead of full drive transfer

set -e

# Load pooltool environment properly
cd "$(dirname "$0")"
source pooltool.sh --source-only 2>/dev/null || {
    # Alternative: load modules directly
    export POOLTOOL_ROOT="$(pwd)"
    source modules/pooltool/core/bootstrap
    bootstrap_load_module pooltool::workflow_engine
    bootstrap_load_module snown::sudo
}

# Source the workflow module to access our functions
source modules/pooltool/workflows/replace_drive

# Test parameters
TEST_SOURCE="/mnt/DRU13/Books"  # 13M test dataset
TEST_RUNID="test_$(date +%s)"
TEMP_MOUNTPOINT="/tmp/rsync_test_${TEST_RUNID}"

echo "🧪 Enhanced Rsync Testing Script"
echo "================================="
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
        if replace_upgrade_rsync_foreground "$TEST_SOURCE" "$TEMP_MOUNTPOINT" "$TEST_RUNID"; then
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
        if replace_upgrade_rsync_background "$TEST_SOURCE" "$TEMP_MOUNTPOINT" "$TEST_RUNID"; then
            echo ""
            echo "✅ Background test initiated successfully!"
            echo "💡 Monitor with: tail -f /tmp/pooltool_rsync_${TEST_RUNID}.log"
            echo "💡 Check status: cat /tmp/pooltool_rsync_${TEST_RUNID}.status"
            echo ""
            echo "⏳ Waiting for background transfer to complete..."
            
            # Wait for completion
            while [[ ! -f "/tmp/pooltool_rsync_${TEST_RUNID}.status" ]]; do
                echo -n "."
                sleep 1
            done
            echo ""
            
            if grep -q "rsync_success=true" "/tmp/pooltool_rsync_${TEST_RUNID}.status" 2>/dev/null; then
                echo "✅ Background transfer completed successfully!"
                echo "📊 Test results:"
                echo "   Target size: $(du -sh "$TEMP_MOUNTPOINT" 2>/dev/null | cut -f1)"
                echo "   File count: $(find "$TEMP_MOUNTPOINT" -type f | wc -l) files"
            else
                echo "❌ Background transfer failed"
                echo "📋 Status file contents:"
                cat "/tmp/pooltool_rsync_${TEST_RUNID}.status" 2>/dev/null || echo "Status file not found"
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
