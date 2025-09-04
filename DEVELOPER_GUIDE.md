# PooltTool Developer Guide

## Module and Namespace Pattern

When creating new commands for pooltool, follow this **exact pattern** used by all existing modules:

### File Structure
```
modules/pooltool/commands/commandname
```

### Namespace Declaration
```bash
#!/usr/bin/env bash
#NAMESPACE=pooltool::commands
```

### Function Naming Pattern

**❌ WRONG - Don't use full namespace in function definitions:**
```bash
func pooltool::commands::health::helper_name {  # WRONG pattern
func pooltool::commands::health {               # WRONG pattern
```

**✅ CORRECT - Use short names, bootstrap handles namespace:**
```bash
function helper_name {          # Helper functions use short names
function commandname {          # Main command uses command name only
```

### Internal Function Calls

**❌ WRONG - Don't use full namespace for internal calls:**
```bash
pooltool::commands::health::helper_name
```

**✅ CORRECT - Use `this::` prefix for internal calls:**
```bash
this::helper_name              # Bootstrap converts to full namespace
```

### How Bootstrap Magic Works

The bootstrap system (`/bootstrap.sh`) automatically transforms:

1. **Function definitions**: `func name {` → `func pooltool::commands::name {`
2. **Internal calls**: `this::helper` → `pooltool::commands::commandname::helper`
3. **Creates proper namespacing** without verbose function names in source

### Example Template

```bash
#!/usr/bin/env bash
#NAMESPACE=pooltool::commands

dependencies::register_module "pooltool/commands/mycommand"

# Helper function - short name
function print_help {
    cat << 'EOF'
USAGE: pooltool mycommand [OPTIONS]
EOF
}

# Another helper - short name  
function parse_args {
    # Call other helpers with this::
    this::print_help
}

# Main command function - matches command name
function mycommand {
    this::parse_args "$@"
    # Implementation here
}
```

### Existing Examples

- `modules/pooltool/commands/disk` - Main: `func disk {`, Helpers: `func disk::*`
- `modules/pooltool/commands/blink` - Main: `func blink {`, Helpers: `func blink::*` 
- `modules/pooltool/commands/health` - Main: `func health {`, Helpers: `func *`

**Key Rule**: Let bootstrap handle the namespacing. Keep function names clean and simple in source code.

## Performance Best Practices

### Use Bulk Data Collection
When working with health data for multiple drives, always use the efficient bulk functions:

**❌ WRONG - Inefficient per-drive calls:**
```bash
for pos in "${positions[@]}"; do
    health_data=$(pooltool::get_drive_health "$device" "$controller")  # Slow!
done
```

**✅ CORRECT - Single bulk call:**
```bash
# Get all health data in one efficient call (uses cached SMART data)
health_results=$(pooltool::get_all_health_info_efficient "$controller" "${unified_array[@]}")
```

**Performance Impact**: 
- Individual calls: ~50+ seconds for 24 drives
- Bulk collection: ~3-4 seconds for 24 drives  
- **Performance gain: 15x faster**

The bulk functions use:
- Single `arcconf` call with 5-minute caching
- Efficient parsing of all drive data at once
- Eliminates per-drive command overhead

## Validation and Testing

### Module Testing Best Practices

**❌ NEVER call `bootstrap_load_module` directly for testing:**
```bash
# This is WRONG and will cause issues:
bootstrap_load_module snapraid/devices && snapraid::devices names
```

**❌ NEVER parse visual layouts for data access:**
```bash
# This is WRONG - visual layout is OUTPUT, not source data:
pooltool drivemap | grep "Position 1"
```

**✅ ALWAYS use pooltool.sh commands for module testing:**
```bash
# This is CORRECT - uses proper module loading:
./pooltool.sh command-that-uses-module

# For drive data, use the unified mapping:
./pooltool.sh test-drives  # Shows real drive mapping data
```

**✅ ALWAYS use driveutils for real drive data:**
```bash
# This is CORRECT - access the actual data infrastructure:
# In your code, use: pooltool::create_unified_mapping
# This provides the real drive data that feeds all visualizations
```

**Why**: 
- Direct bootstrap calls bypass proper namespace handling and module initialization
- Visual layouts are OUTPUT displays - the real data comes from driveutils infrastructure
- The unified mapping system is the single source of truth for all drive information

### Before Committing Changes

**Always run these validation checks:**

```bash
# 1. Test module loading
./pooltool.sh test-health-simple

# 2. Verify function namespacing  
declare -F | grep "pooltool::commands::" | head -5

# 3. Performance test for health operations
time ./pooltool.sh health --quiet

# 4. Test specific new functionality
./pooltool.sh your-new-command --help
```

### Common Issues and Solutions

**Problem**: Function not found after module loading
```bash
❌ func pooltool::commands::health::helper_name {
✅ function helper_name {
```

**Problem**: Slow performance on multi-drive operations
```bash
❌ for drive in drives; do individual_call; done
✅ bulk_result=$(pooltool::get_all_health_info_efficient ...)
```

**Problem**: Bootstrap transformation not working
```bash
❌ pooltool::commands::health::helper_call
✅ this::helper_call
```

## AI Assistant Guidelines

**For AI assistants working on this project:**

1. **ALWAYS** read this guide completely before making changes
2. **NEVER** use full namespace paths in function definitions  
3. **ALWAYS** use bulk operations for multi-drive tasks
4. **VERIFY** changes with the test commands shown above
5. **UPDATE** this guide if you discover new patterns or issues

**Red Flags - Stop and reconsider if you see:**
- Functions defined with full namespace patterns in the name
- Health calls inside loops for multiple drives
- Missing `#NAMESPACE=pooltool::commands` declarations
- Commands that don't follow the template pattern

## Sudo Handling Best Practices

When creating scripts that require root privileges, handle both user and sudo execution gracefully:

**✅ GOOD - Check if already root:**
```bash
script_sudo() {
    # If already running as root, don't use sudo
    if [[ $EUID -eq 0 ]]; then
        "$@"
        return
    fi
    # Otherwise use sudo normally
    sudo "$@"
}
```

**❌ BAD - Always call sudo:**
```bash
# This fails when script is run with "sudo script.sh"
sudo arcconf "$@"  # Error: sudo called from within sudo
```

**Example**: The `arcconf.sh` wrapper handles both:
- `./arcconf.sh LIST` (prompts for password)
- `sudo ./arcconf.sh LIST` (no double-prompt)
