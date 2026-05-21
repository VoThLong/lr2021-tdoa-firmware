cmake_minimum_required(VERSION 3.20)

# Trỏ tới Zephyr RTOS trong thư mục gốc của hãng
set(ZEPHYR_BASE /home/dashtrad/lora_usp_workspace/zephyr)
find_package(Zephyr REQUIRED HINTS $ENV{ZEPHYR_BASE})

project(lr2021-tdoa-firmware)

# Đường dẫn gốc của thư mục hãng (để tham chiếu file)
set(VENDOR_WS /home/dashtrad/lora_usp_workspace)

# Thêm mã nguồn: file main.c của bạn + các file logic mẫu từ thư mục hãng
target_sources(app PRIVATE 
    src/main.c
    ${VENDOR_WS}/modules/lib/usp/examples/main_examples/ping_pong_example/app_periodic_uplink.c
    ${VENDOR_WS}/modules/lib/usp/examples/main_examples/ping_pong_example/app_ping_pong.c
)

# Thêm đường dẫn include (chỉ đọc) từ thư mục hãng
zephyr_include_directories(
    ${VENDOR_WS}/modules/lib/usp/examples/main_examples/ping_pong_example
)

# Fix cho lỗi busy-wait: tăng thời gian xử lý phản hồi lên 50ms
target_compile_definitions(app PRIVATE SUBORDINATE_PROCESSING_TIME_MS=50)

# Đăng ký module USP từ thư mục hãng để Zephyr nhận diện được driver radio
list(APPEND ZEPHYR_EXTRA_MODULES ${VENDOR_WS}/application)
