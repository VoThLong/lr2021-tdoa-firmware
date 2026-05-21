#!/bin/bash

# ==========================================================
# PHAO CỨU SINH - LR2021 EVK (nRF54L15)
# Tác dụng: Nạp lại firmware gốc LoRa Studio Hardware Modem
# ==========================================================

FIRMWARE_PATH="./bin/LoRaStudio_nrf54l15_xiao_v1.5.2.elf"
VENV_PYOCD="/home/dashtrad/lora_usp_workspace/.venv/bin/pyocd"

echo "----------------------------------------------------"
echo "🚀 Đang cưỡng bức nạp firmware gốc (Factory Reset)..."
echo "----------------------------------------------------"

# 1. Kiểm tra file firmware
if [ ! -f "$FIRMWARE_PATH" ]; then
    echo "❌ Lỗi: Không tìm thấy file $FIRMWARE_PATH"
    exit 1
fi

# 2. Thực hiện lệnh nạp với Target ID chuẩn: nrf54l
# Sử dụng trực tiếp pyocd từ venv để có đủ CMSIS-Packs
echo "📦 Đang nạp: $FIRMWARE_PATH"
echo "🎯 Target: nrf54l"

$VENV_PYOCD flash -t nrf54l "$FIRMWARE_PATH"

if [ $? -eq 0 ]; then
    echo "----------------------------------------------------"
    echo "✅ THÀNH CÔNG: Bo mạch đã quay về trạng thái xuất xưởng."
    echo "💡 Bây giờ bạn có thể kết nối với LoRa Studio trên Windows."
    echo "----------------------------------------------------"
else
    echo "----------------------------------------------------"
    echo "❌ THẤT BẠI: Vẫn không nhận diện được chip hoặc lỗi kết nối."
    echo "💡 Gợi ý: Kiểm tra cáp USB và đảm bảo board đã cấp nguồn."
    echo "----------------------------------------------------"
fi
