# TÀI LIỆU KỸ THUẬT: VI CHƯƠNG TRÌNH ĐỊNH VỊ TDoA (LR2021 TDoA Firmware)

**Kiến trúc:** Ứng dụng Zephyr Out-of-Tree (OOT)
**Nền tảng Phần cứng:** Vi điều khiển Seeed Studio XIAO nRF54L15 tích hợp bộ thu phát vô tuyến Semtech LR2021 (LoRa Plus)
**Mục tiêu Ứng dụng:** Phát triển hệ thống nút mạng vô tuyến phục vụ thuật toán định vị Time Difference of Arrival (TDoA).

Kho lưu trữ này chứa mã nguồn logic ứng dụng và các kịch bản tự động hóa (Automation Scripts) được thiết kế theo mô hình tách biệt nhân hệ điều hành (Out-of-Tree). Thiết kế này bảo đảm tính cô lập của mã nguồn nghiên cứu khỏi các thay đổi của nền tảng lõi.

---

## 1. ĐIỀU KIỆN TIÊN QUYẾT (PREREQUISITES)

Quá trình biên dịch mã nguồn đòi hỏi một môi trường nền tảng (Upstream Workspace) chứa nhân Zephyr RTOS và các trình điều khiển phần cứng từ nhà sản xuất.

1.  **Hệ điều hành:** Khuyến nghị các bản phân phối Linux (Ubuntu/Fedora).
2.  **Chuỗi công cụ biên dịch chéo:** Zephyr SDK phiên bản v0.16.8 (Đã thiết lập đường dẫn toàn cục).
3.  **Không gian làm việc Nền tảng (Semtech USP Workspace):** Cần được khởi tạo hợp lệ trên hệ thống máy chủ (Host).

### 1.1. Khởi tạo Không gian làm việc Nền tảng
Trong trường hợp hệ thống chưa được thiết lập thư viện cốt lõi của Semtech, tiến hành thực thi các lệnh sau để khởi tạo không gian làm việc thông qua công cụ điều phối `west`:

```bash
mkdir -p ~/lora_usp_workspace
cd ~/lora_usp_workspace
west init -m https://github.com/Lora-net/usp_zephyr.git --mr main
west update
```

---

## 2. QUY TRÌNH THIẾT LẬP VÀ BIÊN DỊCH DỰ ÁN

**Bước 1: Khởi tạo Môi trường Ảo biệt lập (Isolated Virtual Environment)**
Nhằm loại bỏ các rủi ro xung đột thư viện với hệ điều hành máy chủ, việc thiết lập một không gian Python biệt lập cho dự án là bắt buộc:
```bash
python3 -m venv .venv
source .venv/bin/activate
pip install west pyocd
```

**Bước 2: Khai báo Phân vùng Hệ điều hành (Zephyr Base Mapping)**
Chỉ định biến môi trường `ZEPHYR_BASE` nhằm điều hướng hệ thống CMake tham chiếu đến nhân hệ điều hành nằm tại không gian nền tảng:
```bash
export ZEPHYR_BASE="~/lora_usp_workspace/zephyr"
source $ZEPHYR_BASE/zephyr-env.sh
```
*(Lưu ý: Thay thế `~/lora_usp_workspace` tương ứng với cấu trúc thư mục thực tế trên hệ thống).*

**Bước 3: Thực thi Tiến trình Biên dịch (Compilation)**
Tiến hành biên dịch mã nguồn với chỉ định cấu trúc phần cứng (Board) và cờ liên kết lớp trừu tượng vô tuyến (Shield) tương ứng với LR2021:
```bash
west build -b xiao_nrf54l15/nrf54l15/cpuapp --shield semtech_wio_lr2021 -p always
```

---

## 3. TRIỂN KHAI VÀ GỠ LỖI TỰ ĐỘNG (AUTOMATED DEPLOYMENT)

Dự án tích hợp sẵn các kịch bản Bash nhằm chuẩn hóa và tự động hóa quy trình phân bổ vai trò Máy trạng thái (FSM) và chuyển giao mã nhị phân xuống phần cứng vật lý.

**Tham số Yêu cầu:** Quá trình nạp đa thiết bị đòi hỏi cung cấp tham số Định danh Duy nhất (Unique ID - UID) thông qua cờ `-i` nhằm phân lập mục tiêu. Có thể trích xuất UID thông qua lệnh: `pyocd list`.

*   **Định tuyến thiết bị Chủ quản (Master Node - Initiator):**
    Thiết bị được cấp quyền chủ động kích hoạt máy phát (TX) và khởi tạo chu kỳ giao tiếp.
    ```bash
    ./scripts/flash_master.sh [TARGET_UID]
    ```

*   **Định tuyến thiết bị Cấp dưới (Subordinate Node - Responder):**
    Thiết bị được cấu hình ở trạng thái chờ thu (RX) và phản hồi khi có tín hiệu định tuyến hợp lệ.
    ```bash
    ./scripts/flash_subordinate.sh [TARGET_UID]
    ```

*Lưu ý Kỹ thuật: Các kịch bản trên đã được tích hợp cờ `--erase` nhằm can thiệp và vô hiệu hóa thuật toán Memory Diffing của trình nạp `pyocd`, bảo đảm mã thực thi FSM mới được ghi đè hoàn toàn lên phân vùng Non-Volatile Memory (NVM) của vi điều khiển.*
