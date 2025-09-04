# pooltool - Interactive Drive Management System

## 🤖 **FOR AI AGENTS: REQUIRED READING**

**⚠️ CRITICAL: Before making ANY changes to this codebase, you MUST read these files:**

1. **[DEVELOPER_GUIDE.md](./DEVELOPER_GUIDE.md)** - Module patterns, namespace conventions, performance best practices
2. **[INTERACTIVE_DRIVE_MANAGEMENT_PLAN.md](./INTERACTIVE_DRIVE_MANAGEMENT_PLAN.md)** - Architecture overview and implementation status  
3. **[bootstrap.sh](./bootstrap.sh)** - Understand the module loading system

**Key Rules for AI Agents:**
- ✅ Always follow the namespace pattern in DEVELOPER_GUIDE.md
- ✅ Use bulk health collection functions (not per-drive calls)
- ✅ Test changes with existing test commands in pooltool.sh
- ❌ Never use full namespaces in function definitions
- ❌ Never make individual arcconf calls for multiple drives

## Overview
`pooltool` is a modular Bash-based utility for managing files and disks in a RAID storage environment. It provides commands for finding, copying, moving files, and managing disks and SnapRAID devices, with advanced interactive drive management and health monitoring capabilities.

## Usage

### Running pooltool
To use `pooltool`, run the main script:
```bash
./pooltool.sh <command> [options]
```

### Available Commands
- `find` — Locate files or paths within the RAID pool.
- `cp` — Copy files or directories into the RAID pool, ensuring the target is within the RAID.
- `mv` — Move files or directories into the RAID pool (uses `cp` then removes the source).
- `disk` — Manage disks, including adding new disks and labeling partitions.
- `devices` — Query SnapRAID devices for names, volumes, partitions, and mountpoints.

Use `-h` or `--help` with any command for usage information:
```bash
./pooltool.sh <command> -h
```

## Functionality
- Modular design: Commands are loaded dynamically via `bootstrap.sh`.
- Namespace support: Each command is namespaced for clarity and isolation.
- Dependency management: Modules declare dependencies and are loaded as needed.
- RAID safety: Copy and move operations require the target to be within the RAID location.
- Disk management: The `disk` command assists with adding and labeling disks, checking block devices, and integrating with SnapRAID.
- SnapRAID integration: The `devices` command provides detailed information about SnapRAID devices.

## Directory Structure
- `pooltool.sh` — Main entry point.
- `bootstrap.sh` — Module loader and environment setup.
- `modules/pooltool/commands/` — Command implementations (`find`, `cp`, `mv`, `disk`).
- `modules/snapraid/devices` — SnapRAID device management.

## Contributing
1. Fork or clone the repository.
2. Add new commands as separate scripts in `modules/pooltool/commands/`.
3. Register new modules and declare dependencies as needed.
4. Follow the existing namespace and modular structure.
5. Test your changes thoroughly.
6. Submit a pull request with a description of your changes.

## License
Specify your license here.

---
For more details, review the scripts in this directory and its subfolders. All code and documentation should remain self-contained within `media/tRAID/local/src/pooltool`.
