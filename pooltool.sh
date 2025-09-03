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
bootstrap_load_module snapraid/devices
bootstrap_load_module snown/pansi
bootstrap_load_module snown/here_printf

function print_help {
  snown::here_printf <<-HELP
$(snown::pansi --bold "USAGE:")
  pooltool [-h|--help]
  pooltool <command> [-h|--help] [<args>]
  
$(snown::pansi --bold "FLAGS:")
  -h, --help  Print this help message.
  
$(snown::pansi --bold "COMMANDS:")
  find    $(pooltool::commands::find::print_summary 10)
  cp      $(pooltool::commands::cp::print_summary 10)
  mv      $(pooltool::commands::mv::print_summary 10)
  disk    $(pooltool::commands::disk::print_summary 10) 
  blink   Blink drive LEDs with visual layout for drive identification
  drivemap Visual drive bay layout without LED blinking for reference
  devices $(snapraid::print_summary 10)
HELP
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