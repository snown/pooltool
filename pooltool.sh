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
bootstrap_load_module pooltool/commands/drives
bootstrap_load_module pooltool/commands/blink
bootstrap_load_module pooltool/commands/drivemap
bootstrap_load_module pooltool/commands/health
bootstrap_load_module pooltool/commands/replace-drive
bootstrap_load_module pooltool/commands/monitor
bootstrap_load_module pooltool/commands/workflow
bootstrap_load_module pooltool/commands/test-background
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
  drives      Unified drive information and management
  devices     Show snapraid device information (deprecated - use 'drives')
  drivemap    Show visual drive bay layout
  overview    Show system overview with health and capacity summary
  select      Interactive drive selection interface
  health      Check drive health status (supports automation flags)
  blink       Blink drive LEDs to identify drives in snapraid
  replace-drive  Guided workflow for safe drive replacement
  monitor     Monitor and manage background processes
  workflow    Manage and monitor workflows

EXAMPLES:
  pooltool drives                     # Show all drives in table format
  pooltool drives --json              # Show drives in JSON format
  pooltool drives available           # Show only available drives
  pooltool drives select              # Interactive drive selection
  pooltool devices                    # Show snapraid devices (deprecated)
  pooltool overview                   # Show system health and capacity overview
  pooltool select                     # Interactive drive selection interface
  pooltool health 5                   # Check health of drive at position 5
  pooltool health --all --quiet       # Check all drives, minimal output
  pooltool health --json              # JSON output for automation
  pooltool blink                      # Blink all snapraid drives
  pooltool drivemap                   # Show drive bay layout map
  pooltool drivemap --numbered        # Show numbered drive positions  
  pooltool replace-drive              # Start drive replacement wizard
  pooltool monitor                    # Show active background processes
  pooltool workflow list              # Show all workflows
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
    # Legacy command - redirect to new drives command
    echo "ℹ️  The 'devices' command has been replaced with 'drives'"
    echo "   Use 'pooltool drives --help' for the new interface"
    echo ""
    
    if command -v pooltool::commands::drives &>/dev/null; then
      shift
      pooltool::commands::drives "$@"
    else
      echo "'drives' command not currently supported"
      print_help
      exit 1
    fi
    ;;
  drives)
    if command -v pooltool::commands::drives &>/dev/null; then
      shift
      pooltool::commands::drives "$@"
    else
      echo "'drives' command not currently supported"
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
  health)
    shift
    pooltool::commands::health "$@"
    ;;
  replace-drive)
    if command -v cmd_replace &>/dev/null; then
      shift
      cmd_replace "$@"
    else
      echo "'$1' command not currently supported"
      print_help
      exit 1
    fi
    ;;
  test-background)
    if command -v pooltool::commands::test-background &>/dev/null; then
      shift
      pooltool::commands::test-background "$@"
    else
      echo "'test-background' command not currently supported"
      print_help
      exit 1
    fi
    ;;
  monitor)
    if command -v pooltool::commands::monitor &>/dev/null; then
      shift
      pooltool::commands::monitor "$@"
    else
      echo "'monitor' command not currently supported"
      print_help
      exit 1
    fi
    ;;
  workflow)
    if command -v pooltool::commands::workflow &>/dev/null; then
      shift
      pooltool::commands::workflow "$@"
    else
      echo "'workflow' command not currently supported"
      print_help
      exit 1
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
        echo "Extended: [b1-24] = Blink LED | [h1-24] = Health | [c1-24] = Capacity | 'refresh' = Update data"
        echo
        
        # Interactive loop
        while true; do
          user_input="$(bashful input -p "Select drive position or command:" -d "")"
          
          # Check for EOF or empty input in non-interactive mode
          if [[ -z "$user_input" ]] && ! [ -t 0 ]; then
            echo "End of input reached - exiting."
            break
          fi
          
          case "$user_input" in
            # Extended Commands - Phase 2.3
            b[1-9]|b1[0-9]|b2[0-4])
              # Blink LED command: b + position number
              local blink_position="${user_input#b}"
              echo
              echo "🔆 BLINKING DRIVE LED AT POSITION $blink_position"
              echo "══════════════════════════════════════════════"
              
              # Find the drive at this position
              local blink_drive_found=false
              for record in "${unified_array[@]}"; do
                if [[ "$record" =~ ^([^:]+):([^:]+):([^:]+):([^:]+):([^:]*):([^:]+):([^:]*):([^:]*):([^:]*):([^:]*):([^:]*):([^:]*):([^:]*)$ ]]; then
                  local rec_connector="${BASH_REMATCH[3]}"
                  local rec_device="${BASH_REMATCH[4]}"
                  local calc_position=$(( rec_connector * 4 + (4 - rec_device) ))
                  
                  if [[ "$calc_position" == "$blink_position" ]]; then
                    blink_drive_found=true
                    local system_device="${BASH_REMATCH[6]}"
                    local mount_name="${BASH_REMATCH[1]}"
                    
                    if [[ "$system_device" != "N/A" && "$system_device" != "NONE" ]]; then
                      echo "Blinking LED for drive $mount_name at position $blink_position ($system_device)..."
                      if timeout 10 pooltool::commands::blink --device "$system_device" 2>/dev/null; then
                        echo "✅ Drive LED blink command sent successfully"
                        echo "💡 Look for the blinking LED on the physical drive"
                      else
                        echo "⚠️  Blink command failed - drive may not support LED control"
                      fi
                    else
                      echo "⚠️  Cannot blink LED - drive not available or unallocated"
                    fi
                    break
                  fi
                fi
              done
              
              if [[ "$blink_drive_found" == false ]]; then
                echo "❌ No drive found at position $blink_position"
              fi
              echo
              ;;
            h[1-9]|h1[0-9]|h2[0-4])
              # Health analysis command: h + position number  
              local health_position="${user_input#h}"
              echo
              echo "🏥 HEALTH ANALYSIS FOR POSITION $health_position"
              echo "═══════════════════════════════════════════════"
              
              # Find the drive at this position
              local health_drive_found=false
              for record in "${unified_array[@]}"; do
                if [[ "$record" =~ ^([^:]+):([^:]+):([^:]+):([^:]+):([^:]*):([^:]+):([^:]*):([^:]*):([^:]*):([^:]*):([^:]*):([^:]*):([^:]*)$ ]]; then
                  local rec_connector="${BASH_REMATCH[3]}"
                  local rec_device="${BASH_REMATCH[4]}"
                  local calc_position=$(( rec_connector * 4 + (4 - rec_device) ))
                  
                  if [[ "$calc_position" == "$health_position" ]]; then
                    health_drive_found=true
                    local system_device="${BASH_REMATCH[6]}"
                    local mount_name="${BASH_REMATCH[1]}"
                    local model="${BASH_REMATCH[11]}"
                    
                    printf "  %-20s %s (%s)\n" "Drive:" "$mount_name" "$model"
                    printf "  %-20s %s\n" "Position:" "$health_position"
                    
                    if [[ "$system_device" != "N/A" && "$system_device" != "NONE" ]]; then
                      echo
                      health_info=$(pooltool::get_drive_health "$system_device" "$controller")
                      if [[ "$health_info" =~ ^([^:]+):([^:]+):([^:]+):([^:]+)$ ]]; then
                        local health_status="${BASH_REMATCH[1]}"
                        local temperature="${BASH_REMATCH[2]}"
                        local power_hours="${BASH_REMATCH[3]}"
                        local reallocated="${BASH_REMATCH[4]}"
                        
                        # Health status with color coding
                        local status_display
                        case "$health_status" in
                          "good") status_display="✅ Healthy" ;;
                          "warning") status_display="⚠️  Warning" ;;
                          "critical") status_display="❌ Critical" ;;
                          *) status_display="❓ Unknown" ;;
                        esac
                        printf "  %-20s %s\n" "Health Status:" "$status_display"
                        
                        if [[ $temperature -gt 0 ]]; then
                          local temp_status
                          if [[ $temperature -gt 55 ]]; then
                            temp_status="🔥 High"
                          elif [[ $temperature -gt 45 ]]; then
                            temp_status="🔶 Warm"
                          else
                            temp_status="❄️  Cool"
                          fi
                          printf "  %-20s %s (%s)\n" "Temperature:" "${temperature}°C" "$temp_status"
                        fi
                        
                        if [[ $power_hours -gt 0 ]]; then
                          local years=$((power_hours / 8760))
                          local days=$(( (power_hours % 8760) / 24 ))
                          local hours=$((power_hours % 24))
                          printf "  %-20s %s (%dy %dd %dh)\n" "Power-on Time:" "${power_hours}h" "$years" "$days" "$hours"
                        fi
                        
                        if [[ $reallocated -gt 0 ]]; then
                          printf "  %-20s %s ⚠️\n" "Reallocated Sectors:" "$reallocated"
                        else
                          printf "  %-20s %s ✅\n" "Reallocated Sectors:" "None"
                        fi
                      else
                        echo "⚠️  Unable to retrieve health data"
                      fi
                    else
                      echo "⚠️  Cannot analyze health - drive not available"
                    fi
                    break
                  fi
                fi
              done
              
              if [[ "$health_drive_found" == false ]]; then
                echo "❌ No drive found at position $health_position"
              fi
              echo
              ;;
            c[1-9]|c1[0-9]|c2[0-4])
              # Capacity analysis command: c + position number
              local capacity_position="${user_input#c}"
              echo
              echo "💾 CAPACITY ANALYSIS FOR POSITION $capacity_position"
              echo "═══════════════════════════════════════════════════"
              
              # Find the drive at this position
              local capacity_drive_found=false
              for record in "${unified_array[@]}"; do
                if [[ "$record" =~ ^([^:]+):([^:]+):([^:]+):([^:]+):([^:]*):([^:]+):([^:]*):([^:]*):([^:]*):([^:]*):([^:]*):([^:]*):([^:]*)$ ]]; then
                  local rec_connector="${BASH_REMATCH[3]}"
                  local rec_device="${BASH_REMATCH[4]}"
                  local calc_position=$(( rec_connector * 4 + (4 - rec_device) ))
                  
                  if [[ "$calc_position" == "$capacity_position" ]]; then
                    capacity_drive_found=true
                    local mount_name="${BASH_REMATCH[1]}"
                    local model="${BASH_REMATCH[11]}"
                    local size="${BASH_REMATCH[12]}"
                    
                    printf "  %-20s %s (%s)\n" "Drive:" "$mount_name" "$model"
                    printf "  %-20s %s\n" "Position:" "$capacity_position"
                    printf "  %-20s %s\n" "Capacity:" "$size"
                    
                    # Get capacity information if mounted
                    if [[ "$mount_name" =~ ^(DRU|PPU) ]]; then
                      local expected_mount="/mnt/${mount_name}"
                      if mountpoint -q "$expected_mount" 2>/dev/null; then
                        echo
                        local df_output
                        if df_output=$(df -h "$expected_mount" 2>/dev/null | tail -n1); then
                          local size_h used_h avail_h use_percent
                          read -r _ size_h used_h avail_h use_percent _ <<< "$df_output"
                          
                          printf "  %-20s %s\n" "Total Space:" "$size_h"
                          printf "  %-20s %s\n" "Used Space:" "$used_h"
                          printf "  %-20s %s\n" "Available Space:" "$avail_h"
                          
                          # Usage percentage with visual bar
                          local usage_num=$(echo "$use_percent" | tr -d '%')
                          local usage_status
                          if [[ $usage_num -gt 95 ]]; then
                            usage_status="🔴 Critical"
                          elif [[ $usage_num -gt 85 ]]; then
                            usage_status="🔶 High"
                          elif [[ $usage_num -gt 70 ]]; then
                            usage_status="🔶 Moderate"
                          else
                            usage_status="✅ Good"
                          fi
                          
                          # Create usage bar
                          local bar_length=20
                          local filled_length=$((usage_num * bar_length / 100))
                          local usage_bar=""
                          for ((i=0; i<filled_length; i++)); do
                            usage_bar+="▓"
                          done
                          for ((i=filled_length; i<bar_length; i++)); do
                            usage_bar+="░"
                          done
                          
                          printf "  %-20s %s [%s] %s\n" "Usage:" "$use_percent" "$usage_bar" "$usage_status"
                          
                          # Storage recommendation
                          echo
                          if [[ $usage_num -gt 95 ]]; then
                            echo "  🚨 RECOMMENDATION: Urgent space cleanup required"
                          elif [[ $usage_num -gt 85 ]]; then
                            echo "  ⚠️  RECOMMENDATION: Consider freeing up space soon"
                          elif [[ $usage_num -gt 70 ]]; then
                            echo "  💡 RECOMMENDATION: Monitor space usage"
                          else
                            echo "  ✅ RECOMMENDATION: Healthy space usage"
                          fi
                        fi
                      else
                        echo
                        printf "  %-20s %s\n" "Mount Status:" "🔶 Not mounted"
                        printf "  %-20s %s\n" "Availability:" "Drive ready for mounting"
                      fi
                    else
                      echo
                      printf "  %-20s %s\n" "Drive Status:" "🔶 Unallocated"
                      printf "  %-20s %s\n" "Availability:" "Ready for allocation"
                    fi
                    break
                  fi
                fi
              done
              
              if [[ "$capacity_drive_found" == false ]]; then
                echo "❌ No drive found at position $capacity_position"
              fi
              echo
              ;;
            info[1-9]|info1[0-9]|info2[0-4])
              # Comprehensive info command: info + position number
              local info_position="${user_input#info}"
              echo
              echo "📊 COMPREHENSIVE INFO FOR POSITION $info_position"
              echo "═══════════════════════════════════════════════════"
              
              # Find the drive at this position
              local info_drive_found=false
              for record in "${unified_array[@]}"; do
                if [[ "$record" =~ ^([^:]+):([^:]+):([^:]+):([^:]+):([^:]*):([^:]+):([^:]*):([^:]*):([^:]*):([^:]*):([^:]*):([^:]*):([^:]*)$ ]]; then
                  local rec_connector="${BASH_REMATCH[3]}"
                  local rec_device="${BASH_REMATCH[4]}"
                  local calc_position=$(( rec_connector * 4 + (4 - rec_device) ))
                  
                  if [[ "$calc_position" == "$info_position" ]]; then
                    info_drive_found=true
                    local mount_name="${BASH_REMATCH[1]}"
                    local arcconf_id="${BASH_REMATCH[2]}"
                    local snapraid_name="${BASH_REMATCH[5]}"
                    local system_device="${BASH_REMATCH[6]}"
                    local wwn="${BASH_REMATCH[7]}"
                    local serial="${BASH_REMATCH[8]}"
                    local model="${BASH_REMATCH[11]}"
                    local size="${BASH_REMATCH[12]}"
                    
                    echo "🔧 HARDWARE DETAILS"
                    echo "────────────────────"
                    printf "  %-20s %s\n" "Mount Name:" "$mount_name"
                    printf "  %-20s %s\n" "Device Path:" "$system_device"
                    printf "  %-20s %s\n" "Model:" "$model"
                    printf "  %-20s %s\n" "Size:" "$size"
                    printf "  %-20s %s\n" "Serial Number:" "$serial"
                    if [[ -n "$wwn" && "$wwn" != "N/A" ]]; then
                      printf "  %-20s %s\n" "WWN:" "$wwn"
                    fi
                    printf "  %-20s %s\n" "Physical Position:" "$info_position"
                    printf "  %-20s %s\n" "Connector/Slot:" "$rec_connector/$rec_device"
                    printf "  %-20s %s\n" "Arcconf ID:" "Channel 0, Device $arcconf_id"
                    
                    echo
                    echo "🔧 SNAPRAID INTEGRATION"
                    echo "────────────────────────"
                    if [[ -n "$snapraid_name" && "$snapraid_name" != "NONE" ]]; then
                      printf "  %-20s %s\n" "SnapRAID Role:" "$snapraid_name"
                    else
                      printf "  %-20s %s\n" "SnapRAID Role:" "🔶 Not assigned"
                    fi
                    
                    # Get quick health summary
                    if [[ "$system_device" != "N/A" ]]; then
                      echo
                      echo "💚 HEALTH SUMMARY"
                      echo "─────────────────"
                      health_info=$(pooltool::get_drive_health "$system_device" "$controller")
                      if [[ "$health_info" =~ ^([^:]+):([^:]+):([^:]+):([^:]+)$ ]]; then
                        local health_status="${BASH_REMATCH[1]}"
                        local temperature="${BASH_REMATCH[2]}"
                        
                        local status_display
                        case "$health_status" in
                          "good") status_display="✅ Healthy" ;;
                          "warning") status_display="⚠️  Warning" ;;
                          "critical") status_display="❌ Critical" ;;
                          *) status_display="❓ Unknown" ;;
                        esac
                        printf "  %-20s %s\n" "Status:" "$status_display"
                        
                        if [[ $temperature -gt 0 ]]; then
                          printf "  %-20s %s°C\n" "Temperature:" "$temperature"
                        fi
                      fi
                    fi
                    
                    # Get quick capacity summary
                    if [[ "$mount_name" =~ ^(DRU|PPU) ]]; then
                      local expected_mount="/mnt/${mount_name}"
                      if mountpoint -q "$expected_mount" 2>/dev/null; then
                        echo
                        echo "💾 CAPACITY SUMMARY"
                        echo "───────────────────"
                        local df_output
                        if df_output=$(df -h "$expected_mount" 2>/dev/null | tail -n1); then
                          local size_h used_h avail_h use_percent
                          read -r _ size_h used_h avail_h use_percent _ <<< "$df_output"
                          printf "  %-20s %s\n" "Usage:" "$use_percent of $size_h"
                          printf "  %-20s %s\n" "Available:" "$avail_h"
                        fi
                      fi
                    fi
                    break
                  fi
                fi
              done
              
              if [[ "$info_drive_found" == false ]]; then
                echo "❌ No drive found at position $info_position"
              fi
              echo
              ;;
            refresh)
              echo
              echo "🔄 REFRESHING SYSTEM DATA"
              echo "═════════════════════════"
              echo "Refreshing all drive information..."
              
              # Clear the health cache to force fresh data
              if command -v pooltool::refresh_smart_cache >/dev/null 2>&1; then
                pooltool::refresh_smart_cache "$controller"
                echo "✅ SMART cache refreshed"
              fi
              
              # Get fresh unified data
              unified_data=$(pooltool::create_unified_mapping "$controller" 2>/dev/null)
              if [[ -n "$unified_data" ]]; then
                mapfile -t unified_array <<< "$unified_data"
                echo "✅ Drive mapping refreshed"
              fi
              
              # Get fresh layout data
              layout_data=$(pooltool::get_physical_layout "${unified_array[@]}")
              echo "✅ Physical layout refreshed"
              
              echo "✅ System data refresh complete!"
              echo
              echo "Updated drive layout:"
              echo
              pooltool::render_drive_grid_enhanced "$layout_data" "mount" "" true false false false true "${unified_array[@]}"
              echo
              ;;
            help)
              echo
              echo "📖 INTERACTIVE COMMAND REFERENCE"
              echo "════════════════════════════════"
              echo
              echo "🔍 Basic Commands:"
              echo "  [1-24]     Show detailed drive information for position"
              echo "  h          Show this help message"
              echo "  q          Quit and return to shell"
              echo
              echo "⚡ Extended Commands (Phase 2.3):"
              echo "  b[1-24]    Blink LED for drive at position (e.g., 'b5')"
              echo "  h[1-24]    Show health analysis for drive at position (e.g., 'h12')"
              echo "  c[1-24]    Show capacity analysis for drive at position (e.g., 'c8')"
              echo "  info[1-24] Show comprehensive info for drive at position (e.g., 'info15')"
              echo "  refresh    Refresh all system data (SMART, mapping, layout)"
              echo "  help       Show this detailed command reference"
              echo
              echo "📍 Position Examples:"
              echo "  5          Show full details for drive at position 5"
              echo "  b12        Blink LED for drive at position 12"
              echo "  h3         Quick health check for drive at position 3"
              echo "  c18        Quick capacity check for drive at position 18"
              echo "  info24     Quick info summary for drive at position 24"
              echo
              echo "💡 Tips:"
              echo "  - Drive positions are numbered 1-24 from top-left to bottom-right"
              echo "  - Extended commands provide quick access without entering drive details"
              echo "  - Use 'refresh' if drive data seems outdated"
              echo "  - Use 'b' commands to physically identify drives in the bay"
              echo
              ;;
            [1-9]|1[0-9]|2[0-4])
              echo
              echo "╔════════════════════════════════════════════════════════════════════╗"
              echo "║                     Drive Position $user_input Details                      ║"
              echo "╚════════════════════════════════════════════════════════════════════╝"
              
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
                    
                    # Drive Header Section
                    echo
                    echo "📊 DRIVE OVERVIEW"
                    echo "═════════════════"
                    printf "  %-20s %s\n" "Mount Name:" "$mount_name"
                    printf "  %-20s %s\n" "Device Path:" "$system_device"
                    printf "  %-20s %s\n" "Model:" "$model"
                    printf "  %-20s %s\n" "Size:" "$size"
                    printf "  %-20s %s\n" "Serial Number:" "$serial"
                    if [[ -n "$wwn" && "$wwn" != "N/A" ]]; then
                      printf "  %-20s %s\n" "WWN:" "$wwn"
                    fi
                    
                    # SnapRAID Section
                    echo
                    echo "🔧 SNAPRAID INTEGRATION"
                    echo "════════════════════════"
                    if [[ -n "$snapraid_name" && "$snapraid_name" != "NONE" ]]; then
                      printf "  %-20s %s\n" "SnapRAID Role:" "$snapraid_name"
                      if [[ "$snapraid_name" =~ ^data ]]; then
                        printf "  %-20s %s\n" "Function:" "Data Storage Drive"
                      elif [[ "$snapraid_name" =~ ^parity ]]; then
                        printf "  %-20s %s\n" "Function:" "Parity Protection Drive"
                      fi
                    else
                      printf "  %-20s %s\n" "SnapRAID Role:" "🔶 Not assigned"
                      printf "  %-20s %s\n" "Status:" "Available for assignment"
                    fi
                    
                    # Physical Location Section  
                    echo
                    echo "📍 PHYSICAL LOCATION"
                    echo "═════════════════════"
                    printf "  %-20s %s\n" "Physical Position:" "Position $position_num"
                    printf "  %-20s %s\n" "Connector:" "$rec_connector"
                    printf "  %-20s %s\n" "Device Slot:" "$rec_device"
                    printf "  %-20s %s\n" "Arcconf ID:" "Channel 0, Device $arcconf_id"
                    
                    # Get health information if available
                    if [[ "$system_device" != "N/A" ]]; then
                      echo
                      echo "💚 HEALTH & MONITORING"
                      echo "═══════════════════════"
                      health_info=$(pooltool::get_drive_health "$system_device" "$controller")
                      if [[ "$health_info" =~ ^([^:]+):([^:]+):([^:]+):([^:]+)$ ]]; then
                        local health_status="${BASH_REMATCH[1]}"
                        local temperature="${BASH_REMATCH[2]}"
                        local power_hours="${BASH_REMATCH[3]}"
                        local reallocated="${BASH_REMATCH[4]}"
                        
                        # Health status with color coding
                        local status_display
                        case "$health_status" in
                          "good") status_display="✅ Healthy" ;;
                          "warning") status_display="⚠️  Warning" ;;
                          "critical") status_display="❌ Critical" ;;
                          *) status_display="❓ Unknown" ;;
                        esac
                        printf "  %-20s %s\n" "Overall Status:" "$status_display"
                        
                        if [[ $temperature -gt 0 ]]; then
                          local temp_status
                          if [[ $temperature -gt 55 ]]; then
                            temp_status="🔥 High"
                          elif [[ $temperature -gt 45 ]]; then
                            temp_status="🔶 Warm"
                          else
                            temp_status="❄️  Cool"
                          fi
                          printf "  %-20s %s (%s)\n" "Temperature:" "${temperature}°C" "$temp_status"
                        fi
                        
                        if [[ $power_hours -gt 0 ]]; then
                          local years=$((power_hours / 8760))
                          local days=$(( (power_hours % 8760) / 24 ))
                          local hours=$((power_hours % 24))
                          printf "  %-20s %s (%dy %dd %dh)\n" "Power-on Time:" "${power_hours}h" "$years" "$days" "$hours"
                          
                          # Age assessment
                          local age_status
                          if [[ $years -gt 5 ]]; then
                            age_status="🔶 Mature drive"
                          elif [[ $years -gt 3 ]]; then
                            age_status="✅ Established"
                          else
                            age_status="🆕 Relatively new"
                          fi
                          printf "  %-20s %s\n" "Age Assessment:" "$age_status"
                        fi
                        
                        if [[ $reallocated -gt 0 ]]; then
                          printf "  %-20s %s ⚠️\n" "Reallocated Sectors:" "$reallocated"
                        else
                          printf "  %-20s %s ✅\n" "Reallocated Sectors:" "None"
                        fi
                      fi
                    fi
                    
                    # Get capacity information if mounted
                    if [[ "$mount_name" =~ ^(DRU|PPU) ]]; then
                      local expected_mount="/mnt/${mount_name}"
                      if mountpoint -q "$expected_mount" 2>/dev/null; then
                        echo
                        echo "💾 CAPACITY & USAGE"
                        echo "════════════════════"
                        local df_output
                        if df_output=$(df -h "$expected_mount" 2>/dev/null | tail -n1); then
                          local size_h used_h avail_h use_percent
                          read -r _ size_h used_h avail_h use_percent _ <<< "$df_output"
                          
                          printf "  %-20s %s\n" "Total Capacity:" "$size_h"
                          printf "  %-20s %s\n" "Used Space:" "$used_h"
                          printf "  %-20s %s\n" "Available Space:" "$avail_h"
                          
                          # Usage percentage with visual bar
                          local usage_num=$(echo "$use_percent" | tr -d '%')
                          local usage_status
                          if [[ $usage_num -gt 95 ]]; then
                            usage_status="🔴 Critical"
                          elif [[ $usage_num -gt 85 ]]; then
                            usage_status="🔶 High"
                          elif [[ $usage_num -gt 70 ]]; then
                            usage_status="🔶 Moderate"
                          else
                            usage_status="✅ Good"
                          fi
                          
                          # Create usage bar
                          local bar_length=20
                          local filled_length=$((usage_num * bar_length / 100))
                          local usage_bar=""
                          for ((i=0; i<filled_length; i++)); do
                            usage_bar+="▓"
                          done
                          for ((i=filled_length; i<bar_length; i++)); do
                            usage_bar+="░"
                          done
                          
                          printf "  %-20s %s [%s] %s\n" "Usage:" "$use_percent" "$usage_bar" "$usage_status"
                        fi
                      else
                        echo
                        echo "💾 CAPACITY & USAGE"
                        echo "════════════════════"
                        printf "  %-20s %s\n" "Mount Status:" "🔶 Not mounted"
                        printf "  %-20s %s\n" "Availability:" "Drive ready for use"
                      fi
                    else
                      echo
                      echo "💾 CAPACITY & USAGE"  
                      echo "════════════════════"
                      printf "  %-20s %s\n" "Drive Status:" "🔶 Unallocated"
                      printf "  %-20s %s\n" "Availability:" "Ready for allocation"
                    fi
                    
                    # Actions Section
                    echo
                    echo "⚡ AVAILABLE ACTIONS"
                    echo "════════════════════"
                    echo "  b  - Blink drive LED for physical identification"
                    echo "  r  - Refresh drive information"  
                    echo "  s  - Show detailed SMART analysis"
                    echo "  Enter - Return to drive selection"
                    
                    echo
                    echo "────────────────────────────────────────────────────────────────────"
                    
                    # Sub-action prompt
                    local sub_action
                    sub_action="$(bashful input -p "Action (b/r/s or Enter to continue):" -d "")"
                    
                    case "$sub_action" in
                      "b"|"blink")
                        echo
                        echo "🔆 BLINKING DRIVE LED"
                        echo "═════════════════════"
                        if [[ "$system_device" != "N/A" && "$system_device" != "NONE" ]]; then
                          echo "Blinking LED for drive at position $position_num ($system_device)..."
                          if timeout 10 pooltool::commands::blink --device "$system_device" 2>/dev/null; then
                            echo "✅ Drive LED blink command sent successfully"
                            echo "💡 Look for the blinking LED on the physical drive"
                          else
                            echo "⚠️  Blink command failed - drive may not support LED control"
                          fi
                        else
                          echo "⚠️  Cannot blink LED - drive not available or unallocated"
                        fi
                        echo
                        echo "Press Enter to continue..."
                        read -r
                        ;;
                      "r"|"refresh")
                        echo
                        echo "🔄 REFRESHING DRIVE DATA"
                        echo "════════════════════════"
                        echo "Refreshing SMART cache and drive information..."
                        
                        # Clear the health cache to force fresh data
                        if command -v pooltool::refresh_smart_cache >/dev/null 2>&1; then
                          pooltool::refresh_smart_cache "$controller"
                          echo "✅ SMART cache refreshed"
                        fi
                        
                        # Get fresh unified data
                        unified_data=$(pooltool::create_unified_mapping "$controller" 2>/dev/null)
                        if [[ -n "$unified_data" ]]; then
                          mapfile -t unified_array <<< "$unified_data"
                          echo "✅ Drive mapping refreshed"
                        fi
                        
                        echo "✅ Data refresh complete"
                        echo
                        echo "Press Enter to continue..."
                        read -r
                        ;;
                      "s"|"smart")
                        echo
                        echo "🔍 DETAILED SMART ANALYSIS"
                        echo "═══════════════════════════"
                        if [[ "$system_device" != "N/A" && "$system_device" != "NONE" ]]; then
                          echo "Performing detailed SMART analysis for $system_device..."
                          echo
                          
                          # Get extended health info
                          health_info=$(pooltool::get_drive_health "$system_device" "$controller")
                          if [[ "$health_info" =~ ^([^:]+):([^:]+):([^:]+):([^:]+)$ ]]; then
                            local health_status="${BASH_REMATCH[1]}"
                            local temperature="${BASH_REMATCH[2]}"
                            local power_hours="${BASH_REMATCH[3]}"
                            local reallocated="${BASH_REMATCH[4]}"
                            
                            echo "📊 SMART DATA SUMMARY"
                            echo "──────────────────────"
                            printf "  %-25s %s\n" "Health Status:" "$health_status"
                            printf "  %-25s %s°C\n" "Current Temperature:" "$temperature"
                            printf "  %-25s %s hours\n" "Total Power-on Time:" "$power_hours"
                            printf "  %-25s %s\n" "Reallocated Sectors:" "$reallocated"
                            
                            echo
                            echo "🏥 HEALTH ASSESSMENT"
                            echo "────────────────────"
                            
                            # Temperature assessment
                            if [[ $temperature -gt 0 ]]; then
                              if [[ $temperature -gt 60 ]]; then
                                echo "  🔥 Temperature: CRITICAL - Drive running very hot"
                              elif [[ $temperature -gt 55 ]]; then
                                echo "  🔶 Temperature: WARNING - Drive running hot"
                              elif [[ $temperature -gt 45 ]]; then
                                echo "  🔶 Temperature: MODERATE - Drive warm but acceptable"
                              else
                                echo "  ✅ Temperature: GOOD - Drive running cool"
                              fi
                            fi
                            
                            # Power-on time assessment
                            if [[ $power_hours -gt 0 ]]; then
                              local years=$((power_hours / 8760))
                              if [[ $years -gt 7 ]]; then
                                echo "  🔶 Age: MATURE - Consider replacement planning"
                              elif [[ $years -gt 5 ]]; then
                                echo "  🔶 Age: ESTABLISHED - Monitor closely"
                              elif [[ $years -gt 3 ]]; then
                                echo "  ✅ Age: PRIME - Drive in good operational period"
                              else
                                echo "  ✅ Age: NEW - Drive has plenty of life remaining"
                              fi
                            fi
                            
                            # Reallocated sectors assessment
                            if [[ $reallocated -gt 0 ]]; then
                              if [[ $reallocated -gt 100 ]]; then
                                echo "  ❌ Sectors: CRITICAL - High reallocated sector count"
                              elif [[ $reallocated -gt 10 ]]; then
                                echo "  ⚠️  Sectors: WARNING - Monitor reallocated sectors"
                              else
                                echo "  🔶 Sectors: MINOR - Small number of reallocated sectors"
                              fi
                            else
                              echo "  ✅ Sectors: PERFECT - No reallocated sectors detected"
                            fi
                            
                            echo
                            echo "💡 RECOMMENDATION"
                            echo "─────────────────"
                            if [[ "$health_status" == "critical" || $reallocated -gt 100 || $temperature -gt 60 ]]; then
                              echo "  ❌ IMMEDIATE ACTION: Consider drive replacement"
                            elif [[ "$health_status" == "warning" || $reallocated -gt 0 || $temperature -gt 55 || $years -gt 7 ]]; then
                              echo "  ⚠️  MONITOR CLOSELY: Watch for degradation"
                            else
                              echo "  ✅ HEALTHY: Drive operating normally"
                            fi
                          else
                            echo "⚠️  Unable to retrieve detailed SMART data"
                          fi
                        else
                          echo "⚠️  Cannot analyze SMART data - drive not available"
                        fi
                        echo
                        echo "Press Enter to continue..."
                        read -r
                        ;;
                      ""|" ")
                        # Just continue - no action needed
                        ;;
                      *)
                        echo "Invalid action '$sub_action'. Available: b(blink), r(refresh), s(smart)"
                        echo "Press Enter to continue..."
                        read -r
                        ;;
                    esac
                    break
                  fi
                fi
              done
              
              if [[ "$drive_found" == false ]]; then
                echo
                echo "📭 EMPTY BAY"
                echo "═════════════"
                printf "  %-20s %s\n" "Position:" "$position_num"
                printf "  %-20s %s\n" "Status:" "🔶 No drive installed"  
                printf "  %-20s %s\n" "Availability:" "Ready for drive installation"
                echo
                echo "💡 You can install a new drive in this position."
                echo
              fi
              ;;
            "h"|"help")
              echo
              echo "📖 INTERACTIVE DRIVE SELECTION HELP"
              echo "═══════════════════════════════════"
              echo
              echo "🔍 Basic Commands:"
              echo "  [1-24]     Show detailed drive information for position"
              echo "  h          Show this help message"
              echo "  q          Quit and return to shell"
              echo
              echo "⚡ Quick Commands (Phase 2.3 Extended):"
              echo "  b[1-24]    Blink LED for drive at position (e.g., 'b5')"
              echo "  h[1-24]    Show health analysis for drive at position (e.g., 'h12')"
              echo "  c[1-24]    Show capacity analysis for drive at position (e.g., 'c8')"
              echo "  info[1-24] Show comprehensive info for drive at position (e.g., 'info15')"
              echo "  refresh    Refresh all system data (SMART, mapping, layout)"
              echo "  help       Show extended command reference"
              echo
              echo "📍 Position Guide:"
              echo "  Drive positions are numbered 1-24 from top-left to bottom-right"
              echo "  in the 6x4 drive bay layout shown above."
              echo
              echo "💡 Examples:"
              echo "  5          Show full interactive details for drive at position 5"
              echo "  b12        Blink LED for drive at position 12"
              echo "  h3         Quick health check for drive at position 3"
              echo "  c18        Quick capacity analysis for drive at position 18"
              echo "  info24     Quick summary info for drive at position 24"
              echo "  refresh    Update all drive data"
              echo
              ;;
            "q"|"quit"|"exit")
              echo "Exiting interactive drive selection."
              break
              ;;
            "")
              echo "Please enter a command:"
              echo "  [1-24] = Drive details | b[1-24] = Blink | h[1-24] = Health | c[1-24] = Capacity"
              echo "  info[1-24] = Info | refresh = Update | help = Commands | q = Quit"
              ;;
            *)
              echo "Invalid input '$user_input'."
              echo "Valid commands: [1-24], b[1-24], h[1-24], c[1-24], info[1-24], refresh, help, q"
              echo "Examples: '5' (details), 'b12' (blink), 'h3' (health), 'c8' (capacity), 'help'"
              ;;
          esac
          
          # Exit after processing command in non-interactive mode
          if ! [ -t 0 ] && [[ -n "$user_input" ]]; then
            echo "Command processed in non-interactive mode - exiting."
            break
          fi
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
  test-health-compare)
    echo "Testing health command comparison..."
    position="${2:-3}"
    controller="${3:-1}"
    
    echo "=== TESTING HEALTH COMPARISON FOR POSITION $position ==="
    echo
    
    # Test 1: Working select h3 command
    echo "1. Testing working select h$position command:"
    echo "────────────────────────────────────────────────"
    echo "h$position" | pooltool select
    
    echo
    echo "2. Testing standalone health $position command:"
    echo "────────────────────────────────────────────────"
    pooltool health "$position"
    
    echo
    echo "3. Direct health function test:"
    echo "────────────────────────────────────────────────"
    # Get unified data like both commands do
    unified_data=$(pooltool::create_unified_mapping "$controller" 2>/dev/null)
    if [[ -n "$unified_data" ]]; then
      mapfile -t unified_array <<< "$unified_data"
      
      # Find drive at position using same logic as working code
      for record in "${unified_array[@]}"; do
        if [[ "$record" =~ ^([^:]+):([^:]+):([^:]+):([^:]+):([^:]*):([^:]+):([^:]*):([^:]*):([^:]*):([^:]*):([^:]*):([^:]*):([^:]*)$ ]]; then
          local rec_connector="${BASH_REMATCH[3]}"
          local rec_device="${BASH_REMATCH[4]}"
          local calc_position=$(( rec_connector * 4 + (4 - rec_device) ))
          
          if [[ "$calc_position" == "$position" ]]; then
            local system_device="${BASH_REMATCH[6]}"
            local mount_name="${BASH_REMATCH[1]}"
            
            echo "Found drive: $mount_name at $system_device"
            echo "Calling: pooltool::get_drive_health \"$system_device\" \"$controller\""
            
            health_result=$(pooltool::get_drive_health "$system_device" "$controller")
            echo "Raw result: $health_result"
            
            if [[ "$health_result" =~ ^([^:]+):([^:]+):([^:]+):([^:]+)$ ]]; then
              echo "Parsed: status=${BASH_REMATCH[1]}, temp=${BASH_REMATCH[2]}, hours=${BASH_REMATCH[3]}, sectors=${BASH_REMATCH[4]}"
            else
              echo "Failed to parse health result"
            fi
            break
          fi
        fi
      done
    else
      echo "Failed to get unified data"
    fi
    
    echo
    echo "=== COMPARISON COMPLETE ==="
    ;;
  test-health-simple)
    echo "Testing health function availability..."
    
    echo "1. Checking if health function exists:"
    if command -v pooltool::commands::health &>/dev/null; then
      echo "✅ pooltool::commands::health function found"
    else
      echo "❌ pooltool::commands::health function NOT found"
    fi
    
    echo
    echo "2. Listing available pooltool::commands:: functions:"
    declare -F | grep "pooltool::commands::" | head -5
    
    echo
    echo "3. Testing health module bootstrap:"
    bootstrap_load_module pooltool/commands/health
    echo "Health module loaded"
    
    if command -v pooltool::commands::health &>/dev/null; then
      echo "✅ pooltool::commands::health function found after bootstrap"
      echo "4. Testing simple health call:"
      pooltool::commands::health --help 2>&1 | head -5
    else
      echo "❌ pooltool::commands::health function STILL NOT found"
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