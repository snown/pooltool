# Pooltool Blink Feature - Complete Implementation Documentation

## Project Overview

The `pooltool blink` feature was implemented to help physically identify drives in a snapraid configuration by blinking their LEDs. This solves the problem of identifying which drive slots contain snapraid drives versus available slots for expansion.

## Implementation Summary

**Status**: ✅ **COMPLETE** - All phases successfully implemented and tested  
**Success Rate**: 96% device mapping (22/23 drives mapped)  
**Implementation Date**: August 30, 2025

## Architecture

### Three-Phase Implementation

#### Phase 1: Command Structure & Help System ✅
- Enhanced `pooltool.sh` main help system
- Added `blink` command to main command dispatcher
- Created comprehensive `pooltool/commands/blink` module
- Implemented full argument parsing and help system

#### Phase 2: Device Mapping Logic ✅
- Robust WWN (World Wide Name) based device mapping
- Cross-reference between snapraid devices and arcconf device IDs
- Multiple selection modes (in-raid, not-in-raid, specific drives)
- Comprehensive error handling and verbose reporting

#### Phase 3: LED Blinking Implementation ✅
- arcconf IDENTIFY START/STOP command integration
- Duration-based and indefinite blinking modes
- Multi-device simultaneous blinking
- Proper signal handling for Ctrl+C interruption

## Technical Implementation

### Device Mapping Strategy

**Problem**: Map Linux device names (`/dev/sdX`) from snapraid to arcconf device IDs
**Solution**: Use WWN (World Wide Name) as hardware identifier

```bash
# snapraid devices output:
8:16    /dev/sdb        8:17    /dev/sdb1       DRU01

# Linux lsblk output:
sdb      7.3T ZCT0JLAK             0x5000c500b43807d6 ST8000DM004-2CX188

# arcconf GETCONFIG output:
Device #1
    World-wide name: 5000C500B43807D6
    Reported Channel,Device(T:L): 0,1(1:0)
```

**Mapping Result**: DRU01 (/dev/sdb) → arcconf device #1 (channel 0, device 1)

### Command Syntax

The final arcconf command format:
```bash
# Start blinking
arcconf IDENTIFY 1 DEVICE 0 1 START

# Stop blinking  
arcconf IDENTIFY 1 DEVICE 0 1 STOP
```

## Features Implemented

### Selection Modes

1. **`--in-raid`** (default): Blink drives that ARE in snapraid
2. **`--not-in-raid`**: Blink drives that are NOT in snapraid (available slots)
3. **`--drives NAMES`**: Blink specific snapraid drives by name (parity, data1, etc.)
4. **`--mount-names NAMES`**: Blink specific drives by mount name (DRU01, PPU01, etc.)

### Duration Control

1. **`--duration N`**: Blink for N seconds then auto-stop
2. **No duration**: Blink indefinitely until Ctrl+C

### Additional Options

- `--dry-run`: Show what would be blinked without actually blinking
- `--verbose`: Show detailed device mapping and command execution
- `--controller N`: Target specific controller (future expansion)
- `--help`: Comprehensive help system

## Usage Examples

### Basic Usage
```bash
# Blink all snapraid drives for 10 seconds
pooltool blink --duration 10

# Find available drive slots
pooltool blink --not-in-raid --duration 5
```

### Specific Drive Selection
```bash
# Blink parity drives only
pooltool blink --drives parity 2-parity --duration 3

# Blink specific data drives
pooltool blink --mount-names DRU01 DRU02 DRU03 --duration 5
```

### Troubleshooting & Analysis
```bash
# Dry run with verbose output
pooltool blink --dry-run --verbose

# Test indefinite blinking (stop with Ctrl+C)
pooltool blink --mount-names DRU01
```

## Implementation Statistics

### Device Mapping Success
- **Total drives detected**: 23
- **Successfully mapped**: 22 (96%)
- **Mapping method**: WWN (World Wide Name)
- **Unmapped drives**: 1 (DRU07 - no WWN available, likely USB-connected)

### Test Results
- ✅ Single device blinking
- ✅ Multiple device simultaneous blinking  
- ✅ Duration-based auto-stop
- ✅ Indefinite blinking with Ctrl+C handling
- ✅ All selection modes (in-raid, not-in-raid, specific drives)
- ✅ Error handling for unmapped devices
- ✅ Verbose output and dry-run mode

## File Structure

```
/media/tRAID/local/src/pooltool/
├── pooltool.sh                           # Main script (enhanced help system)
├── modules/
│   ├── pooltool/commands/
│   │   └── blink                         # Complete blink implementation
│   └── snapraid/
│       └── devices                       # Existing snapraid device module
└── BLINK_FEATURE_DOCUMENTATION.md       # This documentation
```

## Dependencies

### Required Commands
- `snapraid` - For device information
- `arcconf` - For LED control (via wrapper script)
- `lsblk` - For WWN extraction

### Integration Points
- Uses existing `snapraid::devices` module
- Integrates with `arcconf` wrapper script in `~/.local/bin/arcconf`
- Follows existing pooltool module architecture

## Error Handling

### Graceful Degradation
- Continues with other devices if one fails to map
- Clear warnings for unmapped devices
- Preserves functionality for mapped devices

### User Feedback
- Verbose mode shows detailed mapping process
- Clear error messages with suggested actions
- Progress reporting during multi-device operations

## Future Enhancements

### Potential Improvements
1. **Multiple Controller Support**: Framework exists, needs testing
2. **WWN Fallback Methods**: Serial number or model/size matching for devices without WWN
3. **Configuration Caching**: Cache device mappings for faster subsequent runs
4. **LED Patterns**: Different blink patterns for different drive types

### USB Drive Support
- Current limitation: DRU07 (/dev/sdx) not mapped due to missing WWN
- Could implement fallback mapping using serial numbers or mount points

## Technical Lessons Learned

### arcconf Command Quirks
- `TIME` parameter syntax unreliable
- `START`/`STOP` approach more robust than duration-based commands
- Channel/Device format: `0 1` not `#1`

### Bash Scripting Best Practices
- Signal handling for proper cleanup
- Array management for multi-device operations
- Modular function design for maintainability

### Device Identification
- WWN provides most reliable hardware-level mapping
- Linux device names (/dev/sdX) can change between boots
- arcconf device numbers are stable within controller context

## Success Metrics

### Primary Goals Achieved ✅
1. **Identify snapraid drives**: Can blink all drives in the array
2. **Identify available slots**: Can blink drives NOT in snapraid
3. **Specific drive targeting**: Can blink individual drives by name
4. **User-friendly interface**: Comprehensive help and intuitive options

### Quality Attributes ✅
- **Reliability**: 96% device mapping success rate
- **Usability**: Clear help system and error messages  
- **Maintainability**: Modular design following project patterns
- **Robustness**: Graceful error handling and recovery

## Conclusion

The `pooltool blink` feature represents a complete, production-ready solution for physical drive identification in snapraid configurations. The implementation successfully combines robust device mapping, comprehensive user options, and reliable LED control to solve a practical storage management problem.

The modular architecture and comprehensive error handling ensure the feature integrates seamlessly with the existing pooltool ecosystem while providing a solid foundation for future enhancements.

---

**Implementation Team**: GitHub Copilot & User Collaboration  
**Testing Environment**: Ubuntu Linux with Adaptec ASR72405 RAID Controller  
**Snapraid Version**: Compatible with standard snapraid device output format
