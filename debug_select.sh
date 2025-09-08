#!/bin/bash

# Test drive selection logic
cd /media/tRAID/local/src/pooltool

# Load framework and modules like pooltool.sh does
DIR=`dirname "$(realpath ${BASH_SOURCE[0]})"`
if [[ -f $DIR/bootstrap.sh ]]; then
    . $DIR/bootstrap.sh
else
    echo "bootstrap not found"
    exit 1
fi

bootstrap_load_module pooltool/driveutils

echo "Testing unified data access..."

# Get the unified data like the select function does
if ! unified_data=$(pooltool::create_unified_mapping); then
    echo "Failed to get unified data"
    exit 1
fi

echo "Raw unified data (first 3 lines):"
echo "$unified_data" | head -3
echo ""

echo "Testing position calculation for a specific drive..."
while IFS= read -r drive_record; do
    if [[ -z "$drive_record" ]]; then continue; fi
    
    # Parse unified record format like in the select function
    if [[ "$drive_record" =~ ^([^:]+):([^:]*):([^:]*):([^:]*):([^:]*):([^:]*):([^:]*):([^:]*):([^:]*):([^:]*):([^:]*):([^:]*):([^:]*)$ ]]; then
        local mount_name="${BASH_REMATCH[1]}"
        local arcconf_id="${BASH_REMATCH[2]}"
        local connector="${BASH_REMATCH[3]}"
        local device_slot="${BASH_REMATCH[4]}"
        local device_path="${BASH_REMATCH[5]}"
        
        echo "Drive: $mount_name, connector: $connector, slot: $device_slot, device: $device_path"
        
        # Calculate position
        if [[ -n "$connector" && -n "$device_slot" && "$connector" != "NONE" && "$device_slot" != "NONE" ]]; then
            local position=$(( connector * 4 + (4 - device_slot) ))
            echo "  -> Position: $position"
        else
            echo "  -> No position (missing connector/slot data)"
        fi
        echo ""
    else
        echo "Failed to parse: $drive_record"
        echo ""
    fi
done <<< "$unified_data"
