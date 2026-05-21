#!/bin/bash

# ==========================================================
# SCRIPT NẠP SUBORDINATE - CHUẨN ZEPHYR WEST
# ==========================================================

PROJECT_ROOT="/home/dashtrad/Documents/lr2021-tdoa-firmware"
VENV_PATH="/home/dashtrad/lora_usp_workspace/.venv"
ZEPHYR_ENV="/home/dashtrad/lora_usp_workspace/zephyr/zephyr-env.sh"
export ZEPHYR_BASE="/home/dashtrad/lora_usp_workspace/zephyr"

echo "----------------------------------------------------"
echo "🛠️  Đang cấu hình mạch làm SUBORDINATE..."
echo "----------------------------------------------------"

# 1. Sửa code thành Subordinate
sed -i 's/#define FORCE_MASTER_MODE [0-1]/#define FORCE_MASTER_MODE 0/g' "$PROJECT_ROOT/src/main.c"

# 2. Kích hoạt môi trường
source "$VENV_PATH/bin/activate"
source "$ZEPHYR_ENV"

# 3. Build và Flash dùng WEST
cd "$PROJECT_ROOT"
echo "📦 Đang biên dịch và nạp (WEST FLASH)..."
rm -rf build

UID_ARG=""
if [ ! -z "$1" ]; then
    echo "🎯 Nhắm mục tiêu Board UID: $1"
    UID_ARG="-i $1"
fi

west build -b xiao_nrf54l15/nrf54l15/cpuapp --shield semtech_wio_lr2021 -p always && west flash $UID_ARG -- --erase

if [ $? -eq 0 ]; then
    echo "----------------------------------------------------"
    echo "✅ THÀNH CÔNG: Mạch đã được nạp làm SUBORDINATE."
    echo "----------------------------------------------------"
else
    echo "❌ THẤT BẠI: Quá trình Build hoặc Flash gặp lỗi."
fi
