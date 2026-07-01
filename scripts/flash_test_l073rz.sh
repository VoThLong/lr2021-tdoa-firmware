#!/bin/bash

# ==========================================================
# FLASH CUSTOM L073RZ BOARD (TEST ZEPHYR)
# ==========================================================

BOARD_UID=$1
PROJECT_ROOT="/home/dashtrad/Documents/lr2021-tdoa-firmware"
WORKSPACE_ROOT="/home/dashtrad/lora_usp_workspace"
VENV_PATH="/home/dashtrad/lora_usp_workspace/.venv"
ZEPHYR_BASE_PATH="/home/dashtrad/lora_usp_workspace/zephyr"
ZEPHYR_ENV="$ZEPHYR_BASE_PATH/zephyr-env.sh"

# Kích hoạt môi trường (Động cơ Zephyr)
export ZEPHYR_BASE="$ZEPHYR_BASE_PATH"
source "$VENV_PATH/bin/activate"
source "$ZEPHYR_ENV"

cd "$PROJECT_ROOT"
echo "Cleaning old build directory..."
rm -rf build/

echo "Building application for NUCLEO-L073RZ..."
# Lệnh build tinh gọn, chỉ gọi tên board, hệ thống sẽ tự động quét file .overlay
west build -p always -b nucleo_l073rz "$PROJECT_ROOT" -d "$PROJECT_ROOT/build" -- -DAPP_TYPE=ranging -DCONF_FILE="prj.conf;boards/nucleo_l073rz.conf" -DEXTRA_CFLAGS="-DRANGING_DEVICE_MODE=1 -DRF_FREQ_IN_HZ=915000000"

if [ $? -ne 0 ]; then
    echo "ERROR: Build failed."
    exit 1
fi

UID_ARG=""
if [ ! -z "$BOARD_UID" ]; then
    # Dùng cho trường hợp cắm nhiều mạch ST-Link cùng lúc
    UID_ARG="-i $BOARD_UID"
fi

echo "Flashing target device via ST-Link..."
west flash -d "$PROJECT_ROOT/build" $UID_ARG

if [ $? -eq 0 ]; then
    echo "SUCCESS: STM32L073RZ Flashing completed."
else
    echo "ERROR: Flashing failed. Check ST-Link connection."
fi