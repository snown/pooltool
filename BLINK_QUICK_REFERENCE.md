# Pooltool Blink - Quick Reference Guide

## Most Common Use Cases

### 🔍 **Find Available Drive Slots**
```bash
# Blink drives NOT in snapraid for 10 seconds
pooltool blink --not-in-raid --duration 10
```
*Perfect for identifying empty slots when adding new drives*

### 💾 **Identify All Snapraid Drives**  
```bash
# Blink all drives in snapraid for 15 seconds
pooltool blink --duration 15
```
*Useful for general array verification*

### 🎯 **Target Specific Drives**
```bash
# Blink parity drives only
pooltool blink --drives parity 2-parity 3-parity 4-parity --duration 5

# Blink specific data drives
pooltool blink --mount-names DRU01 DRU02 DRU03 --duration 8
```
*Great for maintenance or troubleshooting specific drives*

## Quick Syntax Reference

| Option | Description | Example |
|--------|-------------|---------|
| `--in-raid` | Blink snapraid drives (default) | `pooltool blink --in-raid` |
| `--not-in-raid` | Blink available slots | `pooltool blink --not-in-raid` |
| `--drives NAME...` | Blink by snapraid name | `--drives parity data1` |
| `--mount-names NAME...` | Blink by mount name | `--mount-names DRU01 PPU01` |
| `--duration N` | Blink for N seconds | `--duration 10` |
| `--dry-run` | Show what would blink | `--dry-run` |
| `--verbose` | Show detailed info | `--verbose` |

## Drive Name Reference

### Snapraid Names
- `parity`, `2-parity`, `3-parity`, `4-parity` - Parity drives
- Individual drive names as shown in `pooltool devices`

### Mount Names  
- `DRU01`, `DRU02`, `DRU03`, ... - Data drives
- `PPU01`, `PPU02`, `PPU03`, `PPU04` - Parity drives

## Troubleshooting

### Check What Drives Are Available
```bash
pooltool devices
```

### Test Without Actually Blinking
```bash
pooltool blink --dry-run --verbose
```

### Get Detailed Help
```bash
pooltool blink --help
```

## Safety Notes

- ⚠️ **Ctrl+C to stop** indefinite blinking
- ⚠️ Use `--dry-run` first if unsure
- ⚠️ LEDs will blink until stopped - don't forget about them!

## Success Indicators

- ✅ "Command completed successfully" messages
- ✅ No error messages about failed device mapping
- ✅ Physical LED blinking visible on drives

---
*For complete documentation see: `BLINK_FEATURE_DOCUMENTATION.md`*
