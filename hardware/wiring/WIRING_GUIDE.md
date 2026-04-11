# Motor Controller Wiring Guide

## Sangaboard v5 (Preferred)

The Sangaboard v5 is the official motor controller for OpenFlexure. Order from taulab.

### Wiring (Sangaboard v5)

1. Connect 3× 28BYJ-48 stepper motors to the Sangaboard motor headers (X, Y, Z)
2. Connect Sangaboard USB to Raspberry Pi 5
3. Verify: `ls /dev/ttyACM*` should show `/dev/ttyACM0`
4. Flash firmware if needed: `/opt/sangaboard/flash.sh /dev/ttyACM0`

---

## Arduino Nano DIY (Alternative)

If a Sangaboard v5 is unavailable, an Arduino Nano (ATmega328p) with ULN2003 driver
boards can be used as a DIY workaround. The firmware is identical to the Sangaboard.

### Parts

| Part | Qty | Notes |
|------|-----|-------|
| Arduino Nano (ATmega328p) | 1 | CH340 or FTDI variant |
| ULN2003 driver board | 3 | Usually bundled with 28BYJ-48 motors |
| 28BYJ-48 stepper motor | 3 | X, Y, Z axes |
| Female-to-female jumper wires | 19 | For ULN2003-to-Nano connections |
| USB Mini-B cable | 1 | Power + serial |

### Wiring Diagram

```
ULN2003 Driver Board Connections (per motor):

  ULN2003       Arduino Nano
  -------       -----------
  IN1    <--->  D2 (X) / D6 (Y) / D10 (Z)
  IN2    <--->  D3 (X) / D7 (Y) / D11 (Z)
  IN3    <--->  D4 (X) / D8 (Y) / D12 (Z)
  IN4    <--->  D5 (X) / D9 (Y) / D13 (Z)
  GND    <--->  GND
  VCC    <--->  5V (or external 5V supply for all 3)

Motor      ULN2003
-------    -------
Blue       Pin 1 (IN1)
Pink       Pin 2 (IN2)
Yellow     Pin 3 (IN3)
Orange     Pin 4 (IN4)
Red        +5V (common)
```

### Pin Mapping (X/Y/Z motors)

| Arduino Pin | Function | Motor |
|-------------|----------|-------|
| D2 | X-STEP | X ULN2003 IN1 |
| D3 | X-DIR | X ULN2003 IN2 |
| D4 | X-MS1 | X ULN2003 IN3 |
| D5 | X-MS2 | X ULN2003 IN4 |
| D6 | Y-STEP | Y ULN2003 IN1 |
| D7 | Y-DIR | Y ULN2003 IN2 |
| D8 | Y-MS1 | Y ULN2003 IN3 |
| D9 | Y-MS2 | Y ULN2003 IN4 |
| D10 | Z-STEP | Z ULN2003 IN1 |
| D11 | Z-DIR | Z ULN2003 IN2 |
| D12 | Z-MS1 | Z ULN2003 IN3 |
| D13 | Z-MS2 | Z ULN2003 IN4 |
| GND | Common ground | All ULN2003 GND |

> **Note:** Power all three ULN2003 boards from 5V. If motors jitter or skip,
> use an external 5V 2A supply instead of the Arduino's 5V regulator.

### Flash Firmware

```bash
# Auto-detect and flash
/opt/sangaboard/flash.sh

# Or specify port
/opt/sangaboard/flash.sh /dev/ttyUSB0
```

### Verify

```bash
# Check serial port
ls /dev/ttyUSB* /dev/ttyACM*

# Test with Python (in OpenFlexure venv)
/opt/openflexure/venv/bin/python3 -c "
from sangaboard import Sangaboard
sb = Sangaboard('/dev/ttyUSB0')
print('Firmware:', sb.query('version'))
print('Position:', sb.position)
"
```

### OpenFlexure Configuration

After wiring and flashing, update `ofm_config.json.j2` to use the real stage
instead of DummyStage:

```json
"stage": {
    "class": "openflexure_microscope_server.things.stage.sanga:SangaboardStage",
    "kwargs": {
        "port": "/dev/sangaboard"
    }
}
```

The udev rule (`99-sangaboard.rules`) creates `/dev/sangaboard` symlink automatically.