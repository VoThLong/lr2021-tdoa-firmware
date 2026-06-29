#!/bin/bash

# ==========================================================
# FLASH TX CW (INFINITE PREAMBLE)
# ==========================================================

BOARD_UID=$1
VENV_PATH="/home/dashtrad/lora_usp_workspace/.venv"
ZEPHYR_BASE_PATH="/home/dashtrad/lora_usp_workspace/zephyr"
ZEPHYR_ENV="$ZEPHYR_BASE_PATH/zephyr-env.sh"
TX_CW_APP_PATH="/home/dashtrad/lora_usp_workspace/application/samples/usp/sdk/tx_cw"

# Setup Environment
export ZEPHYR_BASE="$ZEPHYR_BASE_PATH"
source "$VENV_PATH/bin/activate"
source "$ZEPHYR_ENV"

echo "Building application: TX CW (INFINITE PREAMBLE)..."
# Compile the tx_cw app directly from the zephyr workspace
west build -b xiao_nrf54l15/nrf54l15/cpuapp --shield semtech_wio_lr2021 "$TX_CW_APP_PATH" --pristine -- -DEXTRA_CFLAGS="-DINFINITE_PREAMBLE"

if [ $? -ne 0 ]; then
    echo "ERROR: Build failed."
    exit 1
fi

UID_ARG=""
if [ ! -z "$BOARD_UID" ]; then
    UID_ARG="-i $BOARD_UID"
fi

echo "Flashing target device..."
west flash $UID_ARG -- --erase

if [ $? -eq 0 ]; then
    echo "SUCCESS: Operation completed."
else
    echo "ERROR: Flashing failed."
fi
