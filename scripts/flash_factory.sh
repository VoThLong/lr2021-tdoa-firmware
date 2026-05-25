#!/bin/bash

# ==========================================================
# FACTORY RESET - LR2021 EVK (nRF54L15)
# Purpose: Flash original LoRa Studio Hardware Modem firmware
# ==========================================================

FIRMWARE_PATH="./bin/LoRaStudio_nrf54l15_xiao_v1.5.2.elf"
VENV_PYOCD="/home/dashtrad/lora_usp_workspace/.venv/bin/pyocd"

echo "----------------------------------------------------"
echo "Starting Factory Reset (Original Firmware)..."
echo "----------------------------------------------------"

if [ ! -f "$FIRMWARE_PATH" ]; then
    echo "ERROR: Firmware file not found at $FIRMWARE_PATH"
    exit 1
fi

echo "Flashing: $FIRMWARE_PATH"
$VENV_PYOCD flash -t nrf54l "$FIRMWARE_PATH"

if [ $? -eq 0 ]; then
    echo "SUCCESS: Board restored to factory state."
else
    echo "FAILURE: Flash error or connection issue."
fi
