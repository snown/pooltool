# PooltTool Project Structure - Quick Reference

## 📁 Essential Files for AI Assistants

```
pooltool/
├── 📖 README.md                    # Project overview + AI instructions  
├── 📖 DEVELOPER_GUIDE.md           # 🚨 MANDATORY: Coding patterns & performance
├── 📖 .ai-context                  # 🚨 MANDATORY: AI assistant guidelines
├── 📖 INTERACTIVE_DRIVE_MANAGEMENT_PLAN.md  # 🚨 Architecture & status
├── 🔧 bootstrap.sh                 # 🚨 CRITICAL: Module system core
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
2. **Understand**: Bootstrap namespace transformation in bootstrap.sh
3. **Test**: Use `./pooltool.sh test-*` commands for validation
4. **Follow**: Exact patterns from existing commands

## 🔥 Critical Performance Rules

- ✅ **Bulk operations**: `pooltool::get_all_health_info_efficient`
- ❌ **Individual loops**: `for drive; do get_drive_health; done`
- ⚡ **Result**: 20x performance difference

## 🎯 Namespace Pattern

```bash
# In modules/pooltool/commands/mycommand:
#NAMESPACE=pooltool::commands

function print_help {          # ✅ Short name
function mycommand {           # ✅ Command name
    this::print_help           # ✅ Use this:: for internal calls
}
```

Bootstrap automatically transforms to full namespaces. Never write them manually!
