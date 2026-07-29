# Mesoscope Microscope Stand — Pi5 + AI-HAT + Sangaboard

## Problem

The upstream OpenFlexure stand is designed for Pi4 + Sangaboard directly
on the GPIO header. Our stack is:

```
Drawer base
  → Pi5 on 5.5mm standoffs
    → AI-HAT+ on 8.5mm GPIO stacking header
      → Sangaboard on 8.5mm GPIO stacking header
```

This adds ~11.5mm to the stack height and puts the Sangaboard one
"floor" higher than the upstream design.

## Changes

| Parameter | Upstream | Mesoscope |
|-----------|----------|-----------|
| `pi_version` | 4 | 5 |
| `sanga_version` | `stack_8.5mm` | `ai_hat_stack` |
| `electronics_drawer_h` | 47mm | 60mm |
| Sangaboard stand height | 18mm | 29.5mm |
| AI-HAT lugs | none | added at Z=14mm |

## Files

| File | Purpose |
|------|---------|
| `microscope_stand_mesoscope.scad` | Entry point (replaces microscope_stand.scad) |
| `lib_microscope_stand_mesoscope.scad` | Full library with Pi5 + HAT stack support |
| `build_stand.sh` | Copies files into upstream repo and builds STL |

## Build

```bash
cd hardware/stand/openscad
./build_stand.sh
```

Output: `hardware/stl/models/microscope_stand_mesoscope.stl`
