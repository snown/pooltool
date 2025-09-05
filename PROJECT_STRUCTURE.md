# PooltTool Project Structure - Quick Reference

**🔧 Built on [Bash with Nails](https://github.com/mindaugasbarysas/bashwithnails)** - Framework providing module loading, namespacing, and dependency management.

## 📁 Essential Files for AI Assistants

```
pooltool/
├── 📖 README.md                    # Project overview + AI instructions  
├── 📖 DEVELOPER_GUIDE.md           # 🚨 MANDATORY: Coding patterns & performance
├── 📖 .ai-context                  # 🚨 MANDATORY: AI assistant guidelines
├── 📖 INTERACTIVE_DRIVE_MANAGEMENT_PLAN.md  # 🚨 Architecture & status
├── 🔧 bootstrap.sh                 # 🚨 CRITICAL: Bash with Nails module system core
├── 🔧 pooltool.sh                  # Main entry point + test commands
│
├── 📁 modules/pooltool/
│   ├── 📁 commands/                # Command implementations
│   │   ├── health                  # Health monitoring (Phase 3.1 ✅)
│   │   ├── disk                    # Drive management
│   │   ├── blink                   # LED control
│   │   └── ...
│   ├── driveutils                  # Device mapping & unified data
│   ├── healthutils                 # SMART data collection (bulk)
│   ├── capacityutils               # Storage capacity monitoring
│   └── drivevisualizer            # Grid-based visualization
│
└── 📁 .vscode/
    └── settings.json               # AI context file references
```

## 🚨 Before Making ANY Changes

1. **Read**: DEVELOPER_GUIDE.md, .ai-context, INTERACTIVE_DRIVE_MANAGEMENT_PLAN.md
2. **Study**: [Bash with Nails Documentation](https://github.com/mindaugasbarysas/bashwithnails/blob/master/docs/man.md)
3. **Understand**: Bootstrap namespace transformation in bootstrap.sh
4. **Test**: Use `./pooltool.sh test-*` commands for validation
5. **Follow**: Exact patterns from existing commands

## 🔥 Critical Performance Rules

- ✅ **Bulk operations**: `pooltool::get_all_health_info_efficient`
- ❌ **Individual loops**: `for drive; do get_drive_health; done`
- ⚡ **Result**: 20x performance difference

## 🎯 Namespace Pattern (Bash with Nails)

```bash
# In modules/pooltool/commands/mycommand:
#NAMESPACE=pooltool::commands

function mycommand::print_help {    # ✅ Module-prefixed (avoids collisions)
function mycommand {               # ✅ Main command name
    this::mycommand::print_help    # ✅ Use this::modulename:: for internal calls
}
```

**Critical**: Helper functions MUST be prefixed with module name to avoid namespace collisions between modules. The Bash with Nails bootstrap automatically transforms to full namespaces.
