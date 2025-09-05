# PooltTool Developer Guide

## Framework Foundation

PooltTool is built on the **[Bash with Nails](https://github.com/mindaugasbarysas/bashwithnails)** framework, which provides:

- **Module System**: Automatic loading and dependency management
- **Namespace Support**: Automatic function prefixing with namespaces  
- **Named Parameters**: Function parameter validation
- **Bootstrap Magic**: Automatic code transformation during module loading

📖 **Framework Documentation**: [Bash with Nails Manual](https://github.com/mindaugasbarysas/bashwithnails/blob/master/docs/man.md)

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

### Critical Namespace Collision Rule

**🚨 CRITICAL**: Helper functions must be prefixed with module name to avoid namespace collisions!

**❌ WRONG - Causes namespace collisions:**
```bash
function print_help {          # Collides with other modules!
function helper_function {     # Gets overwritten by last loaded module!
```

**✅ CORRECT - Module-specific naming:**
```bash
function mycommand::print_help {      # Module-specific, no collision
function mycommand::helper_function { # Safe from overwrites
```

**Why**: Multiple modules defining `function print_help` will overwrite each other when the Bash with Nails bootstrap transforms them all to `pooltool::commands::print_help`. The last loaded module wins, breaking all others.

**Internal Function Calls**: Use `this::modulename::function_name` pattern:
```bash
# In mycommand module:
this::mycommand::print_help    # → pooltool::commands::mycommand::print_help
```

### How Bootstrap Magic Works

The **Bash with Nails** bootstrap system (`bootstrap.sh`) automatically transforms your code during module loading:

1. **Function definitions**: `function name {` → `function pooltool::commands::name {`
2. **Internal calls**: `this::helper` → `pooltool::commands::commandname::helper`  
3. **Named parameters**: `function name(a b) {` → automatic parameter validation
4. **Creates proper namespacing** without verbose function names in source

This is why you write simple, clean function names in your source code, but they become fully namespaced when loaded.

### Bash with Nails Key Features Used

- **`#NAMESPACE=pooltool::commands`**: Declares the namespace for all functions in the module
- **`this::`**: References functions within the same module namespace  
- **`dependencies::depends`**: Automatic loading of required modules
- **`dependencies::register_module`**: Registers module as loaded

### Example Template

```bash
#!/usr/bin/env bash
#NAMESPACE=pooltool::commands

dependencies::register_module "pooltool/commands/mycommand"

# Helper function - MUST be prefixed with module name!
function mycommand::print_help {
    cat << 'EOF'
USAGE: pooltool mycommand [OPTIONS]
EOF
}

# Another helper - MUST be prefixed with module name!
function mycommand::parse_args {
    # Call other helpers with this::modulename::
    this::mycommand::print_help
}

# Main command function - matches command name only
function mycommand {
    this::mycommand::parse_args "$@"
    # Implementation here
}
```

### Existing Examples

- `modules/pooltool/commands/disk` - Main: `function disk {`, Helpers: `function disk::*`
- `modules/pooltool/commands/blink` - Main: `function blink {`, Helpers: `function blink::*` 
- `modules/pooltool/commands/health` - Main: `function health {`, Helpers: `function health::*`
- `modules/pooltool/commands/workflow` - Main: `function workflow {`, Helpers: `function workflow::*`

**Key Rule**: Main command uses command name only. Helper functions use `commandname::helper_name` pattern to avoid namespace collisions. Let Bash with Nails bootstrap handle the full namespacing.

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

# 4. Test new evaluation feature
./pooltool.sh health --evaluate --quiet
```

## Health Command and Drive Evaluation

### Drive Evaluation Feature

The health command includes an advanced `--evaluate` mode that provides comprehensive drive analysis:

```bash
# Basic health check
./pooltool.sh health

# Drive evaluation with upgrade recommendations  
./pooltool.sh health --evaluate

# Automation-friendly JSON output
./pooltool.sh health --evaluate --json --quiet
```

### Evaluation Criteria

The evaluation system analyzes multiple factors for upgrade prioritization:

**Age Analysis:**
- Power-on hours converted to approximate years
- Risk scoring: 70k+ hours (40 points), 50k+ hours (25 points), 30k+ hours (10 points)

**Capacity Assessment:**
- Small capacity drives (<4TB) get higher risk scores for upgrade value
- Size scoring: <4TB (+25 points), <8TB (+15 points), <12TB (+5 points)

**Usage Analysis:**
- High utilization increases upgrade priority
- Usage scoring: >95% (+20 points), >90% (+15 points), >80% (+10 points)

**Health Status:**
- Critical SMART status (+50 points, urgent replacement)
- Warning status (+30 points)  
- Temperature monitoring (+20 points for >50°C, +10 points for >45°C)

### Implementation Notes

- Uses `health::get_drive_capacity_info()` to extract capacity and usage from mounted filesystems
- Converts capacities to bytes for comparison using `health::capacity_to_bytes()`
- Sorts results by risk score (highest first) for prioritized recommendations
- Supports both human-readable and JSON output formats

# 4. Test specific new functionality
./pooltool.sh your-new-command --help
```

### Common Issues and Solutions

**Problem**: Function not found after module loading
```bash
❌ function print_help {                    # Namespace collision!
✅ function mycommand::print_help {         # Module-specific
```

**Problem**: Functions overwriting each other between modules
```bash
❌ function print_help { # in multiple modules  # Last loaded wins!
✅ function workflow::print_help {              # Safe namespace
✅ function monitor::print_help {               # Safe namespace  
```

**Problem**: Incorrect internal function calls
```bash
❌ this::print_help                        # Resolves to wrong function
✅ this::mycommand::print_help             # Resolves correctly
```

**Problem**: Slow performance on multi-drive operations
```bash
❌ for drive in drives; do individual_call; done
✅ bulk_result=$(pooltool::get_all_health_info_efficient ...)
```

**Problem**: Bootstrap transformation not working
```bash
❌ pooltool::commands::health::helper_call       # Don't use full namespace
✅ this::health::helper_call                     # Use this:: pattern
```

## AI Assistant Guidelines

**For AI assistants working on this project:**

1. **ALWAYS** read this guide and the [Bash with Nails documentation](https://github.com/mindaugasbarysas/bashwithnails/blob/master/docs/man.md) completely before making changes
2. **NEVER** use full namespace paths in function definitions  
3. **ALWAYS** prefix helper functions with module name (`modulename::helper`)
4. **ALWAYS** use bulk operations for multi-drive tasks
5. **VERIFY** changes with the test commands shown above
6. **UPDATE** this guide if you discover new patterns or issues

**Red Flags - Stop and reconsider if you see:**
- Functions defined with generic names like `print_help` (without module prefix)
- Multiple modules with identical function names (namespace collision risk)
- Health calls inside loops for multiple drives
- Missing `#NAMESPACE=pooltool::commands` declarations
- Commands that don't follow the Bash with Nails patterns

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
