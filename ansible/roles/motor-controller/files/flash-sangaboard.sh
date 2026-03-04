#!/bin/bash
# Flash Sangaboard-compatible firmware to Arduino Nano
#
# Usage: ./flash.sh [port]
#   port: Serial port (default: auto-detect)
#
# This script compiles and uploads the Sangaboard firmware
# to an Arduino Nano (DIY workaround) or Arduino Leonardo (Sangaboard v0.3).

set -e

FIRMWARE_DIR="/opt/sangaboard/repo/arduino_code/sangaboard"
PORT="${1:-}"

if [ ! -f "$FIRMWARE_DIR/sangaboard.ino" ]; then
    echo "ERROR: Firmware not found at $FIRMWARE_DIR/sangaboard.ino"
    echo "Run the Ansible playbook to clone the repository first."
    exit 1
fi

# Auto-detect board
if [ -z "$PORT" ]; then
    echo "Auto-detecting Arduino..."
    BOARD_INFO=$(arduino-cli board list 2>/dev/null | grep -E "ttyUSB|ttyACM" | head -1)
    if [ -z "$BOARD_INFO" ]; then
        echo "ERROR: No Arduino detected. Connect the board and try again."
        exit 1
    fi
    PORT=$(echo "$BOARD_INFO" | awk '{print $1}')
    echo "Found board on $PORT"
fi

# Detect board type
if echo "$PORT" | grep -q "ttyACM"; then
    FQBN="arduino:avr:leonardo"
    echo "Board type: Arduino Leonardo / Sangaboard v0.3"
else
    FQBN="arduino:avr:nano:cpu=atmega328old"
    echo "Board type: Arduino Nano (DIY workaround)"
fi

echo "Compiling firmware..."
arduino-cli compile --fqbn "$FQBN" "$FIRMWARE_DIR"

echo "Uploading to $PORT..."
arduino-cli upload --fqbn "$FQBN" --port "$PORT" "$FIRMWARE_DIR"

echo ""
echo "Firmware flashed successfully."
echo "Verify with: python3 -c \"from sangaboard import Sangaboard; sb = Sangaboard('$PORT'); print(sb.query('version'))\""
