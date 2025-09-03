#!/usr/bin/env bash

RAID_LOCATION="/media/tRAID"
DRU_MOUNT_POINT="/mnt"

DIR=`dirname "$(realpath ${BASH_SOURCE[0]})"`
if [[ -f $DIR/bootstrap.sh ]]
then
    . $DIR/bootstrap.sh
else
    echo "bootstrap not found"
    exit 256
fi

bootstrap_load_module pooltool/commands/find
bootstrap_load_module pooltool/commands/cp
bootstrap_load_module pooltool/commands/mv
bootstrap_load_module pooltool/commands/disk
bootstrap_load_module pooltool/commands/blink
bootstrap_load_module pooltool/commands/drivemap
bootstrap_load_module pooltool/driveutils
bootstrap_load_module pooltool/drivevisualizer
bootstrap_load_module pooltool/capacityutils
bootstrap_load_module pooltool/healthutils
bootstrap_load_module snapraid/devices
bootstrap_load_module snown/pansi
bootstrap_load_module snown/here_printf

function print_help {
  cat << 'EOF'
USAGE:
  pooltool [-h|--help]
  pooltool <command> [-h|--help] [<args>]
  
FLAGS:
  -h, --help  Print this help message.
  
COMMANDS:
  find        Find files and directories in the pool
  cp          Copy files within the pool
  mv          Move files within the pool  
  disk        Manage and add new disks to the pool
  devices     Show snapraid device information
  drivemap    Show visual drive bay layout
  overview    Show system overview with health and capacity summary
  select      Interactive drive selection interface
  blink       Blink drive LEDs to identify drives in snapraid

EXAMPLES:
  pooltool devices                    # Show all snapraid devices
  pooltool overview                   # Show system health and capacity overview
  pooltool select                     # Interactive drive selection interface
  pooltool blink                      # Blink all snapraid drives
  pooltool drivemap                   # Show drive bay layout map
  pooltool drivemap --numbered        # Show numbered drive positions  
  pooltool blink --help               # Show blink command help
  pooltool find /path/to/search       # Find files in pool

For detailed help on a specific command, use:
  pooltool <command> --help
EOF
}

function main {
  if [[ $# == 0 ]]; then
    print_help
    exit 1
  fi
  
  case "$1" in
  find)
    if command -v pooltool::commands::find &>/dev/null; then
      shift
      pooltool::commands::find "$@"
    else
      echo "'$1' command not currently supported"
      print_help
      exit 1
    fi
    ;;
  cp)
    if command -v pooltool::commands::cp &>/dev/null; then
      shift
      pooltool::commands::cp "$@"
    else
      echo "'$1' command not currently supported"
      print_help
      exit 1
    fi
    ;;
  mv)
    if command -v pooltool::commands::mv &>/dev/null; then
      shift
      pooltool::commands::mv "$@"
    else
      echo "'$1' command not currently supported"
      print_help
      exit 1
    fi
    ;;
  disk)
    if command -v pooltool::commands::disk &>/dev/null; then
      shift
      pooltool::commands::disk "$@"
    else
      echo "'$1' command not currently supported"
      print_help
      exit 1
    fi
    ;;
  devices)
    if command -v snapraid::devices &>/dev/null; then
      shift
      snapraid::devices "$@"
    else
      echo "'$1' command not currently supported"
      print_help
      exit 1
    fi
    ;;
  blink)
    if command -v pooltool::commands::blink &>/dev/null; then
      shift
      pooltool::commands::blink "$@"
    else
      echo "'$1' command not currently supported"
      print_help
      exit 1
    fi
    ;;
  drivemap)
    if command -v pooltool::commands::drivemap &>/dev/null; then
      shift
      pooltool::commands::drivemap "$@"
    else
      echo "'$1' command not currently supported"
      print_help
      exit 1
    fi
    ;;
  overview)
    echo "SnapRAID System Overview"
    echo "========================"
    controller="${2:-1}"
    
    # Get unified device data
    unified_data=$(pooltool::create_unified_mapping "$controller")
    if [[ -n "$unified_data" ]]; then
      mapfile -t unified_array <<< "$unified_data"
      echo
      pooltool::generate_system_overview_header "${unified_array[@]}"
      echo
    else
      echo "No system data available"
    fi
    ;;
  select)
    echo "Interactive Drive Selection"
    echo "=========================="
    controller="${2:-1}"
    
    # Load the input handling module
    bootstrap_load_module pooltool/ask_question
    
    # Get unified device data (same approach as drivemap command)
    unified_data=$(pooltool::create_unified_mapping "$controller" 2>/dev/null)
    if [[ -n "$unified_data" ]]; then
      mapfile -t unified_array <<< "$unified_data"
      
      # Get the physical layout from the unified data
      layout_data=$(pooltool::get_physical_layout "${unified_array[@]}")
      if [[ -n "$layout_data" ]]; then
        # Show numbered layout first
        echo
        echo "Drive Bay Layout with Position Numbers:"
        echo
        pooltool::render_drive_grid_enhanced "$layout_data" "mount" "" true false false false true "${unified_array[@]}"
        
        echo
        echo "Commands: [1-24] = Show drive details | 'h' = Help | 'q' = Quit"
        echo
        
        # Interactive loop
        while true; do
          user_input="$(bashful input -p "Select drive position:" -d "")"
          
          case "$user_input" in
            [1-9]|1[0-9]|2[0-4])
              echo "Drive Position $user_input Details:"
              echo "=================================="
              
              # Find the drive at this position by iterating through all drives and calculating their positions
              local drive_found=false
              local position_num="$user_input"
              
              # Find the drive record for this position
              for record in "${unified_array[@]}"; do
                if [[ "$record" =~ ^([^:]+):([^:]+):([^:]+):([^:]+):([^:]*):([^:]+):([^:]*):([^:]*):([^:]*):([^:]*):([^:]*):([^:]*):([^:]*)$ ]]; then
                  local rec_connector="${BASH_REMATCH[3]}"
                  local rec_device="${BASH_REMATCH[4]}"
                  
                  # Calculate the position for this drive using the same formula as the visualizer
                  local calc_position=$(( rec_connector * 4 + (4 - rec_device) ))
                  
                  if [[ "$calc_position" == "$position_num" ]]; then
                    drive_found=true
                    local mount_name="${BASH_REMATCH[1]}"
                    local arcconf_id="${BASH_REMATCH[2]}"
                    local snapraid_name="${BASH_REMATCH[5]}"
                    local system_device="${BASH_REMATCH[6]}"
                    local wwn="${BASH_REMATCH[7]}"
                    local serial="${BASH_REMATCH[8]}"
                    local model="${BASH_REMATCH[11]}"
                    local size="${BASH_REMATCH[12]}"
                    
                    echo "Mount Name: $mount_name"
                    echo "Device Path: $system_device"
                    echo "Model: $model"
                    echo "Size: $size"
                    echo "Serial: $serial"
                    if [[ -n "$snapraid_name" ]]; then
                      echo "SnapRAID Role: $snapraid_name"
                    else
                      echo "SnapRAID Role: Not assigned"
                    fi
                    echo "Arcconf Position: Channel 0, Device $arcconf_id"
                                        echo "Physical Position: Connector $rec_connector, Slot $rec_device"
                    
                    # Get health information if available
                    if [[ "$system_device" != "N/A" ]]; then
                      echo
                      echo "Health Information:"
                      health_info=$(pooltool::get_drive_health "$system_device" "$controller")
                      if [[ "$health_info" =~ ^([^:]+):([^:]+):([^:]+):([^:]+)$ ]]; then
                        local health_status="${BASH_REMATCH[1]}"
                        local temperature="${BASH_REMATCH[2]}"
                        local power_hours="${BASH_REMATCH[3]}"
                        local reallocated="${BASH_REMATCH[4]}"
                        
                        echo "  Status: $health_status"
                        if [[ $temperature -gt 0 ]]; then
                          echo "  Temperature: ${temperature}°C"
                        fi
                        if [[ $power_hours -gt 0 ]]; then
                          local years=$((power_hours / 8760))
                          local days=$(( (power_hours % 8760) / 24 ))
                          echo "  Power-on Time: ${power_hours}h (${years}y ${days}d)"
                        fi
                        if [[ $reallocated -gt 0 ]]; then
                          echo "  Reallocated Sectors: $reallocated"
                        fi
                      fi
                    fi
                    
                    # Get capacity information if mounted
                    if [[ "$mount_name" =~ ^(DRU|PPU) ]]; then
                      local expected_mount="/mnt/${mount_name}"
                      if mountpoint -q "$expected_mount" 2>/dev/null; then
                        echo
                        echo "Capacity Information:"
                        local df_output
                        if df_output=$(df -h "$expected_mount" 2>/dev/null | tail -n1); then
                          local size_h used_h avail_h use_percent
                          read -r _ size_h used_h avail_h use_percent _ <<< "$df_output"
                          echo "  Total Size: $size_h"
                          echo "  Used Space: $used_h"
                          echo "  Available: $avail_h"
                          echo "  Usage: $use_percent"
                        fi
                      else
                        echo
                        echo "Capacity Information: Not mounted"
                      fi
                    fi
                    
                    echo
                    break
                  fi
                fi
              done
              
              if [[ "$drive_found" == false ]]; then
                echo "Position $position_num: Empty bay"
                echo
              fi
              ;;
            "h"|"help")
              echo
              echo "Interactive Drive Selection Help"
              echo "================================"
              echo
              echo "Commands:"
              echo "  1-24    Show details for drive at position number"
              echo "  h       Show this help message"
              echo "  q       Quit and return to shell"
              echo
              echo "Drive positions are numbered 1-24 from top-left to bottom-right"
              echo "in the 6x4 drive bay layout shown above."
              echo
              echo "Examples:"
              echo "  5       Show details for drive at position 5"
              echo "  12      Show details for drive at position 12"
              echo "  h       Show help"
              echo "  q       Quit"
              echo
              ;;
            "q"|"quit"|"exit")
              echo "Exiting interactive drive selection."
              break
              ;;
            "")
              echo "Please enter a drive position (1-24), 'h' for help, or 'q' to quit."
              ;;
            *)
              echo "Invalid input '$user_input'. Please enter 1-24, 'h' for help, or 'q' to quit."
              ;;
          esac
        done
      else
        echo "Error: Failed to generate physical layout"
      fi
    else
      echo "No system data available"
    fi
    ;;
  test-numbered)
    echo "Testing numbered drive positions..."
    controller="${2:-1}"
    
    # Get unified device data
    unified_data=$(pooltool::create_unified_mapping "$controller")
    if [[ -n "$unified_data" ]]; then
      mapfile -t unified_array <<< "$unified_data"
      
      echo -e "\n=== Drive Layout with Position Numbers ==="
      pooltool::render_drive_grid_enhanced "PHYSICAL_LAYOUT" "mount" "" true false false false true "${unified_array[@]}"
    else
      echo "No unified data available"
    fi
    ;;
  test-input)
    echo "Testing bashful input functionality..."
    echo "====================================="
    
    # Test basic input
    echo "Testing basic text input:"
    user_input="$(bashful input -p "Enter some text:" -d "default_value")"
    echo "You entered: '$user_input'"
    
    echo
    echo "Testing numeric input with validation:"
    while true; do
        user_number="$(bashful input -p "Enter a number (1-24) or 'q' to quit:" -d "")"
        
        case "$user_number" in
            [1-9]|1[0-9]|2[0-4])
                echo "Valid drive number: $user_number"
                break
                ;;
            "q"|"quit")
                echo "Quitting test..."
                break
                ;;
            "")
                echo "Please enter a number or 'q'"
                ;;
            *)
                echo "Invalid input '$user_number'. Please enter 1-24 or 'q'."
                ;;
        esac
    done
    
    echo "Input testing complete!"
    ;;
  -h|--help)
    local subcommands=(
    find
    cp
    mv
    disk
    blink
    drivemap
    )
    if bashful in_array "$2" "${subcommands[@]}"; then
      pooltool::commands::$2 -h
    elif [[ "$2" == "devices" ]]; then
      snapraid::devices -h
    else
      print_help
      exit 0
    fi
    ;;
  # Test commands for development
  test-drives)
    echo "Testing drive utilities module..."
    
    echo -e "\nTesting create_unified_mapping..."
    pooltool::create_unified_mapping 1
    
    echo -e "\nTesting get_physical_layout..."
    unified_data=$(pooltool::create_unified_mapping 1 2>/dev/null)
    if [[ -n "$unified_data" ]]; then
      mapfile -t unified_array <<< "$unified_data"
      pooltool::get_physical_layout "${unified_array[@]}"
    else
      echo "No unified data available"
    fi
    ;;
  drivemap)
    if command -v pooltool::commands::drivemap &>/dev/null; then
      shift
      pooltool::commands::drivemap "$@"
    else
      echo "'$1' command not currently supported"
      print_help
      exit 1
    fi
    ;;
  blink)
    if command -v pooltool::commands::blink &>/dev/null; then
      shift
      pooltool::commands::blink "$@"
    else
      echo "'$1' command not currently supported"
      print_help
      exit 1
    fi
    ;;
  test-drives)
    echo "Testing drive utilities module..."
    
    echo "Getting arcconf devices..."
    pooltool::get_arcconf_devices 1
    
    echo -e "\nGetting snapraid devices..."
    pooltool::get_snapraid_devices
    
    echo -e "\nCreating unified mapping..."
    pooltool::create_unified_mapping 1
    
    echo -e "\nGetting physical layout..."
    unified_data=$(pooltool::create_unified_mapping 1 2>/dev/null)
    if [[ -n "$unified_data" ]]; then
      mapfile -t unified_array <<< "$unified_data"
      pooltool::get_physical_layout "${unified_array[@]}"
    else
      echo "No unified data available"
    fi
    ;;
  test-visual)
    echo "Testing drive visualizer module..."
    pooltool::debug_visualization "${@:2}"
    ;;
  test-grid)
    echo "Testing different grid label types..."
    controller="${2:-1}"
    echo "Testing with controller $controller..."
    
    # Get unified device data
    unified_data=$(pooltool::create_unified_mapping "$controller")
    if [[ -n "$unified_data" ]]; then
      mapfile -t unified_array <<< "$unified_data"
      
      echo -e "\n=== Mount Name Labels ==="
      pooltool::render_drive_grid "PHYSICAL_LAYOUT" "mount" "" true "${unified_array[@]}"
      
      echo -e "\n=== Device Path Labels ==="
      pooltool::render_drive_grid "PHYSICAL_LAYOUT" "device" "" true "${unified_array[@]}"
      
      echo -e "\n=== Arcconf Position Labels ==="
      pooltool::render_drive_grid "PHYSICAL_LAYOUT" "arcconf" "" true "${unified_array[@]}"
      
      echo -e "\n=== SnapRAID Name Labels ==="
      pooltool::render_drive_grid "PHYSICAL_LAYOUT" "snapraid" "" true "${unified_array[@]}"
    else
      echo "No unified data available"
    fi
    ;;
  test-debug)
    echo "Testing dimension calculations..."
    controller="${2:-1}"
    label_type="${3:-mount}"
    echo "Testing with controller $controller and label type $label_type..."
    
    # Call debug function with correct parameter order: controller, label_type, use_colors
    pooltool::debug_visualization "$controller" "$label_type" true
    ;;
  test-health-debug)
    echo "Testing health monitoring with debug output..."
    controller="${2:-1}"
    
    echo -e "\n=== Debug: Testing individual drive health with tracing ==="
    echo "Testing health for /dev/sda with debug:"
    
    # Add debug mode to health function
    bash -c "
    source modules/bootstrap.sh
    bootstrap_load_module pooltool/healthutils
    
    # Debug version of health check
    system_device='/dev/sda'
    controller=1
    
    echo 'Getting arcconf SMART data...'
    smart_output=\$(arcconf GETSMARTSTATS \$controller tabular 2>/dev/null)
    
    if [[ -n \"\$smart_output\" ]]; then
        echo 'Got SMART data, parsing...'
        
        health_status='good'
        temperature=0
        power_hours=0
        reallocated_sectors=0
        in_attribute=false
        current_attribute=''
        looking_for_raw_value=false
        
        while IFS= read -r line; do
            [[ -z \"\$line\" ]] && continue
            
            if [[ \"\$line\" =~ Attribute[[:space:]]*\$ ]]; then
                echo 'Found Attribute section'
                in_attribute=true
                current_attribute=''
                looking_for_raw_value=false
                continue
            fi
            
            if [[ \"\$in_attribute\" == true ]]; then
                if [[ \"\$line\" =~ id[[:space:]]*\\.[[:space:]]*0xC2 ]]; then
                    echo 'Found temperature attribute (0xC2)'
                    current_attribute='temperature'
                    looking_for_raw_value=true
                elif [[ \"\$looking_for_raw_value\" == true && \"\$line\" =~ rawValue[[:space:]]*\\.[[:space:]]*([0-9]+) ]]; then
                    local raw_value=\"\${BASH_REMATCH[1]}\"
                    echo \"Found rawValue: \$raw_value for attribute: \$current_attribute\"
                    case \"\$current_attribute\" in
                        'temperature') temperature=\"\$raw_value\" ;;
                        'power_hours') power_hours=\"\$raw_value\" ;;
                        'reallocated') reallocated_sectors=\"\$raw_value\" ;;
                    esac
                    looking_for_raw_value=false
                    current_attribute=''
                elif [[ \"\$line\" =~ Status[[:space:]]*\\.[[:space:]]*(.+) ]]; then
                    local attr_status=\"\${BASH_REMATCH[1]}\"
                    echo \"Found Status: \$attr_status\"
                    if [[ \"\$attr_status\" != 'OK' ]]; then
                        health_status='critical'
                    fi
                fi
                
                if [[ \"\$line\" =~ ^[[:space:]]*\$ ]]; then
                    in_attribute=false
                fi
            fi
            
            if [[ \$temperature -gt 0 ]]; then
                echo \"Got temperature \$temperature, breaking...\"
                break
            fi
        done <<< \"\$smart_output\"
        
        echo \"Final results: health_status=\$health_status, temperature=\$temperature, power_hours=\$power_hours, reallocated_sectors=\$reallocated_sectors\"
    else
        echo 'No SMART data received'
    fi
    "
    ;;
  test-health-performance)
    echo "Testing health monitoring performance..."
    controller="${2:-1}"
    
    echo -e "\n=== Performance test: Multiple individual health calls ==="
    echo "Testing individual health calls (simulating old approach):"
    
    time_start=$(date +%s%N)
    
    for device in /dev/sda /dev/sdb /dev/sdc /dev/sdd; do
        echo -n "  $device: "
        pooltool::get_drive_health "$device" "$controller"
    done
    
    time_end=$(date +%s%N)
    time_diff=$(( (time_end - time_start) / 1000000 ))  # Convert to milliseconds
    echo "Total time for 4 drives: ${time_diff}ms"
    
    echo -e "\n=== Performance test: Cached approach ==="
    echo "Forcing cache refresh and testing again:"
    
    # Clear cache to simulate fresh start
    pooltool::refresh_smart_cache "$controller"
    
    time_start=$(date +%s%N)
    
    for device in /dev/sda /dev/sdb /dev/sdc /dev/sdd; do
        echo -n "  $device: "
        pooltool::get_drive_health "$device" "$controller"
    done
    
    time_end=$(date +%s%N)
    time_diff=$(( (time_end - time_start) / 1000000 ))
    echo "Total time for 4 drives (with caching): ${time_diff}ms"
    
    echo -e "\n=== Cache info ==="
    echo "SMART_CACHE_TTL: $SMART_CACHE_TTL seconds"
    echo "Cache timestamp: $SMART_DATA_TIMESTAMP"
    echo "Current time: $(date +%s)"
    ;;
  test-health)
    echo "Testing health monitoring functionality..."
    controller="${2:-1}"
    
    echo -e "\n=== Testing efficient health monitoring ==="
    echo "Getting unified device mapping..."
    unified_data=$(pooltool::create_unified_mapping "$controller" 2>/dev/null)
    if [[ -n "$unified_data" ]]; then
        mapfile -t unified_array <<< "$unified_data"
        
        echo "Getting health info for all drives efficiently..."
        time_start=$(date +%s%N)
        
        health_results=$(pooltool::get_all_health_info_efficient "$controller" "${unified_array[@]}")
        
        time_end=$(date +%s%N)
        time_diff=$(( (time_end - time_start) / 1000000 ))
        
        echo "Health data retrieved in ${time_diff}ms"
        echo -e "\nFirst few health results:"
        echo "$health_results" | head -4
        
        echo -e "\n=== Individual drive health samples ==="
        # Extract specific drives from the results for comparison
        while IFS= read -r line; do
            if [[ "$line" =~ :(/dev/sd[a-d]):.*:([^:]+):([^:]+):([^:]+):([^:]+)$ ]]; then
                local device="${BASH_REMATCH[1]}"
                local health="${BASH_REMATCH[2]}"
                local temp="${BASH_REMATCH[3]}" 
                local hours="${BASH_REMATCH[4]}"
                local sectors="${BASH_REMATCH[5]}"
                echo "$device: $health:$temp:$hours:$sectors"
            fi
        done <<< "$health_results"
    else
        echo "Failed to get unified device mapping"
    fi
    
    echo -e "\n=== Testing health indicators ==="
    echo "Testing health indicator for good:"
    pooltool::get_health_indicator "good"
    
    echo "Testing health indicator for warning:"
    pooltool::get_health_indicator "warning"
    
    echo "Testing health indicator for critical:"
    pooltool::get_health_indicator "critical"
    
    echo -e "\n=== Testing all health info collection ==="
    echo "Health monitoring optimization complete!"
    echo "Total drives processed: $(echo "$health_results" | wc -l)"
    ;;
  test-enhanced)
    echo "Testing enhanced drive visualization with health..."
    controller="${2:-1}"
    mode="${3:-overview}"
    
    echo "Testing enhanced visualization with controller $controller in $mode mode..."
    
    # Get unified device data
    unified_data=$(pooltool::create_unified_mapping "$controller")
    if [[ -n "$unified_data" ]]; then
      mapfile -t unified_array <<< "$unified_data"
      
      case "$mode" in
        capacity)
          echo -e "\n=== Enhanced Capacity View ==="
          pooltool::render_drive_grid_enhanced "PHYSICAL_LAYOUT" "mount" "" true true false false "${unified_array[@]}"
          ;;
        health)
          echo -e "\n=== Enhanced Health View ==="
          pooltool::render_drive_grid_enhanced "PHYSICAL_LAYOUT" "mount" "" true false true false "${unified_array[@]}"
          ;;
        overview)
          echo -e "\n=== Enhanced Overview (Capacity + Health) ==="
          pooltool::render_drive_grid_enhanced "PHYSICAL_LAYOUT" "mount" "" true false false true "${unified_array[@]}"
          ;;
        *)
          echo "Invalid mode: $mode. Use: capacity, health, or overview"
          exit 1
          ;;
      esac
    else
      echo "No unified data available"
    fi
    ;;
  test-overview-header)
    echo "Testing System Overview Header..."
    controller="${2:-1}"
    
    echo "Testing system overview header with controller $controller..."
    
    # Get unified device data
    unified_data=$(pooltool::create_unified_mapping "$controller")
    if [[ -n "$unified_data" ]]; then
      mapfile -t unified_array <<< "$unified_data"
      
      echo -e "\n=== Testing standalone system overview header ==="
      pooltool::generate_system_overview_header "${unified_array[@]}"
      
      echo -e "\n=== Testing integrated overview with drive grid ==="
      pooltool::render_drive_grid_enhanced "PHYSICAL_LAYOUT" "mount" "" true false false true "${unified_array[@]}"
    else
      echo "No unified data available"
    fi
    ;;
  -h|--help)
    print_help
    exit 0
    ;;
  *)
    echo "Invalid command: $1"
    print_help
    exit 1
  esac
}

function bashful {
  (
    local bashful_path="$(find /tmp/ -name "jmcantrell-bashful-*" -print -quit 2>/dev/null)"
    if [[ -z ${bashful_path:+x} ]]; then
      curl -fsSL https://github.com/jmcantrell/bashful/tarball/master | tar xz -C /tmp/
      bashful_path="$(find /tmp/ -name "jmcantrell-bashful-*" -print -quit 2>/dev/null)"
    fi
    if [[ -z ${bashful_path:+x} ]]; then
      echo "Couldn't find bashful"
      exit 1
    fi
    
    pushd "${bashful_path}"/bin/ >/dev/null
    source "${bashful_path}/bin/bashful"
    popd >/dev/null
    
    "$@"
  )
}

main "$@"