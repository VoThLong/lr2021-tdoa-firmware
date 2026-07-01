cmake_minimum_required(VERSION 3.20)

# ==========================================================
# Zephyr Configuration
# ==========================================================
set(ZEPHYR_BASE /home/dashtrad/lora_usp_workspace/zephyr)

# ==========================================================
# Semtech Driver Configuration (USP)
# ==========================================================
set(VENDOR_WS /home/dashtrad/lora_usp_workspace)
list(APPEND ZEPHYR_EXTRA_MODULES 
    ${VENDOR_WS}/application
    ${VENDOR_WS}/modules/lib/usp
    ${VENDOR_WS}/modules/lib/lora-basics-modem
)

list(APPEND BOARD_ROOT ${CMAKE_CURRENT_SOURCE_DIR})
find_package(Zephyr REQUIRED HINTS $ENV{ZEPHYR_BASE})

project(lr2021-tdoa-firmware)

# ==========================================================
# Application Selection (Default: pingpong)
# Usage: west build -b ... -- -DAPP_TYPE=ranging
# ==========================================================
set(APP_TYPE pingpong CACHE STRING "Application type to compile (pingpong or ranging)")

if(APP_TYPE STREQUAL "ranging")
    message(STATUS "Configuring application: RANGING")
    
    target_sources(app PRIVATE 
        src/ranging/main.c
        src/ranging/app_ranging_result_output.c
        src/ranging/oled_display.c
        src/ranging/app_ranging_hopping.c
    )
    zephyr_include_directories(src/ranging/)
    
    # Ranging specific definitions
    # target_compile_definitions(app PRIVATE DISABLE_RANGING_LOG)

else()
    message(STATUS "Configuring application: PINGPONG")
    
    target_sources(app PRIVATE 
        src/pingpong/main.c
        src/pingpong/app_periodic_uplink.c
        src/pingpong/app_ping_pong.c
        src/pingpong/oled_display.c
    )
    
    zephyr_include_directories(src/pingpong/)
    
    # Fix for pingpong busy-wait issue
    target_compile_definitions(app PRIVATE SUBORDINATE_PROCESSING_TIME_MS=50)
endif()

