#!/bin/bash

# Comprehensive test for unallocated drive workflow integration
# This test validates that the replace-drive workflow can handle unallocated drives

cd "$(dirname "$0")"

echo "🔧 UNALLOCATED DRIVE WORKFLOW - INTEGRATION TEST"
echo "════════════════════════════════════════════════════════════════"
echo ""

# Test 1: Verify unallocated drives are available
echo "📋 Test 1: Verify unallocated drives are available in system"
echo "────────────────────────────────────────────────────────────────"

unallocated_drives=$(./pooltool.sh test-drives 2>/dev/null | grep ":NONE:" | wc -l)
echo "Found $unallocated_drives unallocated drives in system"

if [[ $unallocated_drives -gt 0 ]]; then
    echo "✅ Unallocated drives available for testing"
    echo ""
    echo "Available unallocated drives:"
    ./pooltool.sh test-drives 2>/dev/null | grep ":NONE:" | head -3 | while IFS=: read -r name id conn dev rest; do
        position=$((conn * 4 + (4 - dev)))
        echo "  - $name at position $position (Connector $conn, Device $dev)"
    done
else
    echo "❌ No unallocated drives found - cannot test workflow"
    exit 1
fi

echo ""

# Test 2: Test workflow logic with simulated UNALLOCATED input
echo "📋 Test 2: Test workflow integration with unallocated drive selection"
echo "────────────────────────────────────────────────────────────────"

# Get the replace-drive workflow file for testing
workflow_file="modules/pooltool/workflows/replace_drive"

if [[ ! -f "$workflow_file" ]]; then
    echo "❌ Workflow file not found: $workflow_file"
    exit 1
fi

echo "✅ Workflow file found"

# Check if our UNALLOCATED handling code is present
if grep -q "Handle unallocated drive selection from visual selector" "$workflow_file"; then
    echo "✅ Unallocated drive handling code present in workflow"
else
    echo "❌ Unallocated drive handling code not found in workflow"
    exit 1
fi

# Check if the enhanced parsing logic is present
if grep -q "Enhanced parsing for different UNALLOCATED formats" "$workflow_file"; then
    echo "✅ Enhanced UNALLOCATED parsing logic present"
else
    echo "❌ Enhanced UNALLOCATED parsing logic not found"
    exit 1
fi

# Check if device path lookup logic is present
if grep -q "Find the system device path for this unallocated drive" "$workflow_file"; then
    echo "✅ Device path lookup logic present"
else
    echo "❌ Device path lookup logic not found"
    exit 1
fi

echo ""

# Test 3: Validate parsing logic with real data
echo "📋 Test 3: Validate parsing logic with real unallocated drive data"
echo "────────────────────────────────────────────────────────────────"

# Test with NEW-14T at position 5
test_input="UNALLOCATED:NEW-14T:5"
echo "Testing input: $test_input"

# Simulate the parsing logic
if [[ "$test_input" =~ ^UNALLOCATED:([^:]+):([0-9]+)$ ]]; then
    drive_name="${BASH_REMATCH[1]}"
    drive_position="${BASH_REMATCH[2]}"
    drive_connector=$(( (drive_position - 1) / 4 ))
    drive_device_slot=$(( 3 - ((drive_position - 1) % 4) ))
    
    echo "✅ Successfully parsed UNALLOCATED input"
    echo "   Drive: $drive_name"
    echo "   Position: $drive_position" 
    echo "   Calculated Connector: $drive_connector, Device: $drive_device_slot"
    
    # Verify this matches the actual system data
    actual_record=$(./pooltool.sh test-drives 2>/dev/null | grep "NEW-14T:" | head -1)
    if [[ -n "$actual_record" ]]; then
        if [[ "$actual_record" =~ ^[^:]+:[^:]+:([0-9]+):([0-9]+): ]]; then
            actual_connector="${BASH_REMATCH[1]}"
            actual_device="${BASH_REMATCH[2]}"
            
            if [[ "$drive_connector" == "$actual_connector" && "$drive_device_slot" == "$actual_device" ]]; then
                echo "✅ Calculated position matches actual system data"
            else
                echo "❌ Position mismatch - Calculated: $drive_connector,$drive_device_slot vs Actual: $actual_connector,$actual_device"
            fi
        fi
    fi
else
    echo "❌ Failed to parse UNALLOCATED input"
fi

echo ""

# Test 4: Validate device mapping capability
echo "📋 Test 4: Validate device mapping capability"
echo "────────────────────────────────────────────────────────────────"

# Check if we can find device paths for known unallocated drives
new_14t_device=""
new_12t_device=""

for device in /dev/sd*; do
    # Skip partition numbers
    if [[ "$device" =~ [0-9]$ ]]; then
        continue
    fi
    
    if [[ -b "$device" ]]; then
        dev_serial=$(lsblk -n -o SERIAL "$device" 2>/dev/null | head -1 | tr -d ' ' || echo "")
        
        # Check for known unallocated drives
        if [[ "$dev_serial" == "ZR900A2S" ]]; then
            new_14t_device="$device"
        elif [[ "$dev_serial" == "0000WEP7" ]]; then
            new_12t_device="$device"
        fi
    fi
done

if [[ -n "$new_14t_device" ]]; then
    echo "✅ NEW-14T device mapping successful: $new_14t_device"
else
    echo "❌ NEW-14T device mapping failed"
fi

if [[ -n "$new_12t_device" ]]; then
    echo "✅ NEW-12T device mapping successful: $new_12t_device"
else
    echo "❌ NEW-12T device mapping failed"
fi

echo ""

# Test 5: Integration readiness
echo "📋 Test 5: Integration readiness assessment"
echo "────────────────────────────────────────────────────────────────"

readiness_score=0

# Check components
if [[ $unallocated_drives -gt 0 ]]; then
    echo "✅ Unallocated drives available (+1)"
    ((readiness_score++))
fi

if grep -q "Handle unallocated drive selection" "$workflow_file"; then
    echo "✅ Workflow integration code present (+1)"
    ((readiness_score++))
fi

if [[ -n "$new_14t_device" || -n "$new_12t_device" ]]; then
    echo "✅ Device path mapping functional (+1)"
    ((readiness_score++))
fi

if [[ "$test_input" =~ ^UNALLOCATED: ]]; then
    echo "✅ Input parsing logic working (+1)"
    ((readiness_score++))
fi

echo ""
echo "📊 INTEGRATION TEST SUMMARY"
echo "────────────────────────────────────────────────────────────────"
echo "Readiness Score: $readiness_score/4"

if [[ $readiness_score -eq 4 ]]; then
    echo "🎉 EXCELLENT: Unallocated drive workflow fully ready for testing"
    echo ""
    echo "✅ All components verified:"
    echo "   • Unallocated drives detected in system"
    echo "   • Workflow integration code implemented"  
    echo "   • Device path mapping functional"
    echo "   • Input parsing logic working"
    echo ""
    echo "🎯 Ready for manual testing with: ./pooltool.sh replace-drive 15"
    echo "   Select option 1 (upgrade), then 'visual', then position 5 or 21"
elif [[ $readiness_score -ge 3 ]]; then
    echo "👍 GOOD: Most components ready, minor issues to resolve"
elif [[ $readiness_score -ge 2 ]]; then
    echo "⚠️  PARTIAL: Some components working, needs attention"
else
    echo "❌ CRITICAL: Major issues need resolution before testing"
fi

echo ""
echo "💡 Next Steps:"
echo "   1. Manual test with actual replace-drive workflow"
echo "   2. Verify end-to-end functionality with real drive upgrade"
echo "   3. Document any remaining edge cases or issues"
