#!/usr/bin/env bash

# Demo script to show blinking device visualization
cd "$(dirname "$0")"

echo "=== Drive Visualization Demo ==="
echo "Demonstrating different label types and blinking device indicators"
echo

echo -e "2. Testing with simulated blinking devices (arcconf IDs 3,7,15):"

# Get unified data directly without sourcing bootstrap to avoid conflicts
unified_data=$(./pooltool.sh test-drives 2>/dev/null | grep -E "^[^:]+:[^:]+:[^:]+:" | grep -v "UNMAPPED_DEVICES")
if [[ -n "$unified_data" ]]; then
    mapfile -t unified_array <<< "$unified_data"
    
    echo "Found ${#unified_array[@]} devices"
    echo "Sample device record: ${unified_array[0]}"
    
    # Load modules properly
    source bootstrap.sh
    
    # Simulate blinking devices 3, 7, and 15
    echo -e "\nMount Name Labels with Blinking Devices:"
    pooltool::render_drive_grid "PHYSICAL_LAYOUT" "mount" "3,7,15" true "${unified_array[@]}"
    
    echo -e "\nArcconf Position Labels with Same Blinking Devices:"
    pooltool::render_drive_grid "PHYSICAL_LAYOUT" "arcconf" "3,7,15" true "${unified_array[@]}"
    
    echo -e "\nDevice Path Labels (No Color):"
    pooltool::render_drive_grid "PHYSICAL_LAYOUT" "device" "3,7" false "${unified_array[@]}"
else
    echo "No device data available"
fi

echo -e "\n=== Demo Complete ==="
