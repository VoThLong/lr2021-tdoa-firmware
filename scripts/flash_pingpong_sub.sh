#!/bin/bash

# ==========================================================
# FLASH PINGPONG SUBORDINATE
# ==========================================================

BOARD_UID=$1
PROJECT_ROOT="/home/dashtrad/Documents/lr2021-tdoa-firmware"
VENV_PATH="/home/dashtrad/lora_usp_workspace/.venv"
ZEPHYR_BASE_PATH="/home/dashtrad/lora_usp_workspace/zephyr"
ZEPHYR_ENV="$ZEPHYR_BASE_PATH/zephyr-env.sh"

# Setup Environment
export ZEPHYR_BASE="$ZEPHYR_BASE_PATH"
source "$VENV_PATH/bin/activate"
source "$ZEPHYR_ENV"

# Update code for Subordinate role
sed -i 's/#define FORCE_MASTER_MODE [0-1]/#define FORCE_MASTER_MODE 0/g' "$PROJECT_ROOT/src/pingpong/main.c"

cd "$PROJECT_ROOT"
echo "Cleaning old build directory..."
rm -rf build/

echo "Building application: PINGPONG (SUBORDINATE)..."
west build -b xiao_nrf54l15/nrf54l15/cpuapp --shield semtech_wio_lr2021 -- -DAPP_TYPE=pingpong

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
