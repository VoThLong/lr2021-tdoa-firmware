# LR2021 TDoA Firmware (Out-of-Tree Zephyr Application)

Dự án phát triển firmware cho hệ thống định vị TDoA sử dụng vi điều khiển **Seeed Studio XIAO nRF54L15** và chip thu phát vô tuyến **Semtech LR2021 (LoRa Plus)**.

Dự án này được thiết kế theo kiến trúc **Out-of-Tree (OOT)** của Zephyr RTOS, cho phép tách biệt mã nguồn ứng dụng khỏi nhân hệ điều hành.

## 1. Yêu cầu Hệ thống (Prerequisites)

Dự án này **bắt buộc** phải có môi trường nền tảng (Upstream Workspace) từ Semtech để biên dịch.

1. Hệ điều hành: Linux (Ubuntu/Fedora)
2. Zephyr SDK v0.16.8 (Cài đặt toàn cục).
3. Workspace Semtech USP đã được khởi tạo.

### Hướng dẫn khởi tạo Môi trường Nền tảng (Semtech USP)
Nếu bạn chưa có, hãy tạo một thư mục trống và dùng `west` để kéo toàn bộ nhân Zephyr và Driver Semtech về:

```bash
mkdir -p ~/lora_usp_workspace
cd ~/lora_usp_workspace
west init -m https://github.com/Lora-net/usp_zephyr.git --mr main
west update
```

## 2. Thiết lập Dự án và Biên dịch

**Bước 1: Khởi tạo môi trường ảo Python cục bộ (Khuyên dùng)**
Tại thư mục dự án này (`lr2021-tdoa-firmware`), tạo một môi trường Python riêng để chứa công cụ biên dịch:
```bash
python3 -m venv .venv
source .venv/bin/activate
pip install west pyocd
```

**Bước 2: Nạp biến môi trường Zephyr Base**
Bạn phải chỉ định cho CMake biết nhân Zephyr nằm ở đâu:
```bash
export ZEPHYR_BASE="~/lora_usp_workspace/zephyr"
source $ZEPHYR_BASE/zephyr-env.sh
```
*(Thay `~/lora_usp_workspace` bằng đường dẫn thực tế trên máy bạn).*

**Bước 3: Biên dịch (Build)**
Biên dịch dự án cho bo mạch XIAO nRF54L15, bắt buộc đi kèm tham số `--shield` để kích hoạt driver LR2021:
```bash
west build -b xiao_nrf54l15/nrf54l15/cpuapp --shield semtech_wio_lr2021 -p always
```

## 3. Quy trình Nạp tự động (Automated Flashing)

Dự án cung cấp sẵn 2 kịch bản Bash để tự động hóa việc thay đổi vai trò FSM (Máy trạng thái) và nạp cứng xuống chip.

**Yêu cầu:** Gắn cờ UID (`-i`) của mạch để tránh nạp đè nếu cắm nhiều thiết bị. Lấy UID bằng lệnh: `pyocd list`.

*   **Nạp mạch Master (Chủ động phát PING):**
    ```bash
    ./scripts/flash_master.sh [UID_CỦA_MẠCH]
    ```

*   **Nạp mạch Subordinate (Chờ nhận và phản hồi PONG):**
    ```bash
    ./scripts/flash_subordinate.sh [UID_CỦA_MẠCH]
    ```

*Lưu ý: Các script này sử dụng lệnh `--erase` để ép buộc xóa NVM trước khi nạp, khắc phục lỗi thuật toán Memory Diffing của pyocd.*
