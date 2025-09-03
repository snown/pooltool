# Pooltool Blink Feature Implementation Plan

## 📊 Project Status
**Overall Progress**: Phase 1 Complete ✅ | Phase 2 Ready 🔄 | Phase 3 Pending ⏳  
**Last Updated**: August 29, 2025  
**Current Status**: Phase 1 completed successfully, ready to begin Phase 2

## Overview
Add a new `blink` command to pooltool that can identify and blink drives in the snapraid array using arcconf, helping users visually identify which physical drive slots contain drives that are or are not part of their snapraid configuration.

## Goals
- Blink drives that ARE in snapraid (default behavior)
- Option to blink drives that are NOT in snapraid
- Option to blink specific individual drives by mount name
- Configurable blink duration (default: blink until canceled)
- Support for multiple controllers (future-proofing)
- Robust error handling for drives that can't be identified

## Technical Architecture

### New Module: `pooltool/commands/blink`
Location: `/media/tRAID/local/src/pooltool/modules/pooltool/commands/blink`

### Dependencies
- Existing `snapraid::devices` module for snapraid device information
- `arcconf` binary (accessible via PATH, uses our wrapper at `~/.local/bin/arcconf`)
- Hardware identifier mapping (WWN/Serial numbers for reliable device matching)
- Internal `snown::sudo` module for privilege escalation (single password prompt)

## Implementation Plan

### Phase 1: Core Infrastructure
1. **Create blink command module** (`modules/pooltool/commands/blink`)
   - Follow existing module pattern
   - Implement argument parsing for various options
   - Add proper help/usage information

2. **Add blink command to main pooltool.sh**
   - Add module loading
   - Add command case handler
   - Follow existing pattern

3. **Enhance help system**
   - Replace "No help for the wicked" with actual command listing
   - Add descriptions for each command

### Phase 2: Device Mapping Logic
1. **Get snapraid device information**
   - Use existing `snapraid::devices` to get partitions and mountpoints
   - Extract base device names (e.g., `/dev/sda1` -> `/dev/sda`)
   - Map snapraid names to mount names (DRU/PPU scheme)

2. **Get arcconf device information**
   - Use existing `snown::sudo` for any command that needs super user privileges
   - Parse `arcconf GETCONFIG` output for all controllers using `snown::sudo`
   - Extract device information including WWN/Serial numbers
   - Map device slots/IDs to controllers

3. **Create device mapping**
   - Match snapraid devices to arcconf devices using hardware identifiers
   - Support both snapraid names (parity, data1) and mount names (PPU01, DRU01)
   - Handle unmappable devices gracefully with warning messages
   - Create lookup tables for efficient blink operations

### Phase 3: Blink Operations
1. **Implement blink logic**
   - Use existing `snown::sudo` for any command that needs super user privileges
   - Use `arcconf IDENTIFY` command via `snown::sudo` to blink drives
   - Support controller-specific device addressing
   - Handle multiple controllers if present

2. **Add timing controls**
   - Configurable blink duration
   - Default: continuous until canceled (Ctrl+C)
   - Option for specific duration (e.g., `--duration 30s`)

3. **User interaction**
   - Clear status messages about which drives are being blinked
   - Instructions for stopping (Ctrl+C)
   - Summary of actions taken

## Command Interface

### Basic Usage
```bash
# Blink all snapraid drives (default)
pooltool blink

# Blink drives NOT in snapraid
pooltool blink --not-in-raid

# Blink specific drives by snapraid name
pooltool blink --drives parity 2-parity data1

# Blink specific drives by mount name (DRU/PPU scheme)
pooltool blink --mount-names DRU01 DRU02 PPU01

# Blink for specific duration
pooltool blink --duration 30s

# Show what would be blinked without actually blinking
pooltool blink --dry-run
```

### Options
- `--in-raid` (default): Blink drives that are in snapraid
- `--not-in-raid`: Blink drives that are NOT in snapraid
- `--drives NAMES...`: Blink specific drives by snapraid name (e.g., parity, data1, 2-parity)
- `--mount-names NAMES...`: Blink specific drives by mount name (e.g., DRU01, PPU01)
- `--duration DURATION`: Blink for specific duration (default: until canceled)
- `--dry-run`: Show what would be blinked without actually blinking
- `--controller N`: Target specific controller (default: all)
- `--verbose`: Show detailed device mapping information
- `--help`: Show command help

## File Structure
```
/media/tRAID/local/src/pooltool/
├── modules/pooltool/commands/
│   └── blink                           # New blink command module
├── pooltool.sh                         # Main script (updated)
└── BLINK_FEATURE_PLAN.md              # This file
```

## Dependencies and Requirements

### External Dependencies
- `arcconf` command available in PATH
- `snapraid` command for device information
- `lsblk`, `blkid`, or similar for device information gathering
- Administrative privileges (handled via internal `snown::sudo` module)

### Internal Dependencies
- `snapraid::devices` module (existing)
- `snown::sudo` module for privilege escalation (existing)
- Bootstrap system (existing)
- Core utilities (existing)

## Error Handling Strategy

### Expected Error Cases
1. **Unmappable drives**: Snapraid devices that can't be found in arcconf
   - Show warning message
   - Continue with mappable drives
   - Provide summary of unmapped devices

2. **Controller communication failures**
   - Catch arcconf errors
   - Show specific error messages
   - Fail gracefully without affecting other operations

3. **Permission issues**
   - Use internal `snown::sudo` module for seamless privilege escalation
   - Clear messages about requirements if `snown::sudo` fails
   - Graceful handling without affecting other operations

4. **Hardware changes**
   - Detect when device mapping becomes invalid
   - Suggest re-running with verbose mode for debugging

## Testing Strategy

### Manual Testing Scenarios
1. **Basic functionality**
   - Blink all snapraid drives
   - Verify correct drives are blinking
   - Test Ctrl+C interruption

2. **Edge cases**
   - Empty snapraid configuration
   - Mixed drive types (SATA, SAS)
   - Disconnected drives
   - Multiple controllers

3. **Error conditions**
   - Invalid drive names
   - Controller communication failures
   - Permission issues

### Validation
- Cross-reference device mapping with manual inspection
- Verify blink operations affect correct physical drives
- Test all command-line options

## Future Enhancements

### Potential Additions
1. **Interactive mode**: Allow user to select drives from a menu
2. **Configuration file**: Save device mappings for faster subsequent runs
3. **Integration with other tools**: Export device mappings for use by other scripts
4. **LED patterns**: Different blink patterns for different drive types
5. **Web interface**: Remote drive identification through web browser

### Multi-controller Support
- Auto-detect all available controllers
- Support controller-specific commands
- Handle mixed controller types (future)

## Implementation Timeline

### ✅ Phase 1 (Foundation): COMPLETED
**Status**: ✅ Complete  
**Time Taken**: ~2 hours  
**Completed on**: August 29, 2025

#### Accomplishments:
- ✅ **Created blink command module** (`/media/tRAID/local/src/pooltool/modules/pooltool/commands/blink`)
  - Follows existing module pattern with proper namespace (`pooltool::commands`)
  - Comprehensive argument parsing for all planned options
  - Proper dependency declarations (`snown/script_sudo`, `snapraid/devices`)
  - Comprehensive help documentation with examples

- ✅ **Updated main pooltool.sh**
  - Added module loading for `pooltool/commands/blink`
  - Added command case handler following existing pattern
  - Integration works correctly

- ✅ **Enhanced help system**
  - Replaced "No help for the wicked" with comprehensive command listing
  - Added descriptions for all commands including the new blink command
  - Command-specific help works (`pooltool blink --help`)
  - Main help shows usage examples and command descriptions

- ✅ **Comprehensive argument parsing**
  - All planned options implemented: `--in-raid`, `--not-in-raid`, `--drives`, `--mount-names`
  - Additional options: `--duration`, `--dry-run`, `--controller`, `--verbose`
  - Different modes properly detected and stored
  - Error handling for unknown options
  - Multi-argument parsing for drive lists

- ✅ **Integration testing**
  - Verified `snapraid::devices` integration provides all needed data
  - Confirmed device mapping data is available (device names, paths, mount points)
  - Dry-run functionality working
  - Verbose output shows configuration and snapraid data

#### Testing Results:
```bash
# All tests passed:
./pooltool.sh --help                              # ✅ Enhanced help system
./pooltool.sh blink --help                        # ✅ Command-specific help
./pooltool.sh blink --dry-run --verbose           # ✅ Default mode (in-raid)
./pooltool.sh blink --mount-names DRU01 DRU02 --dry-run --verbose  # ✅ Mount name selection
./pooltool.sh blink --drives parity 2-parity --dry-run --verbose   # ✅ Snapraid name selection
```

#### Next Steps:
Ready to proceed to Phase 2 (Device Mapping Logic)

### Phase 2 (Device Mapping): ~3-4 hours
**Status**: 🔄 Ready to Start  
**Dependencies**: Phase 1 ✅ Complete

- Implement snapraid device detection
- Add arcconf device detection  
- Create device mapping logic
- Add error handling

### Phase 3 (Blink Operations): ~2-3 hours
**Status**: ⏳ Pending Phase 2  
**Dependencies**: Phase 2 completion

- Implement blink functionality
- Add timing controls
- User interaction and feedback
- Testing and refinement

**Total Estimated Time**: 7-10 hours  
**Actual Time (Phase 1)**: ~2 hours ✅

## Notes and Considerations

### Hardware Identifier Reliability
- WWN (World Wide Name) is most reliable but not always available
- Serial numbers are good fallback
- Device names (/dev/sdX) are least reliable due to enumeration order changes
- May need multiple identifier strategies

### Performance Considerations
- Cache device mappings within single command execution
- Avoid repeated arcconf calls where possible
- Consider async operations for multiple controllers

### User Experience
- Clear, actionable error messages
- Progress indicators for long operations
- Consistent command-line interface with other pooltool commands
- Good documentation and examples

---

*This plan serves as a roadmap for implementing the blink feature. It may be updated as implementation progresses and requirements are refined.*
