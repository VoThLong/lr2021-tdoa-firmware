/**
 * @file      main.c
 *
 * @brief     Application main
 *
 * The Clear BSD License
 * Copyright Semtech Corporation 2025. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted (subject to the limitations in the disclaimer
 * below) provided that the following conditions are met:
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of the Semtech corporation nor the
 *       names of its contributors may be used to endorse or promote products
 *       derived from this software without specific prior written permission.
 *
 * NO EXPRESS OR IMPLIED LICENSES TO ANY PARTY'S PATENT RIGHTS ARE GRANTED BY
 * THIS LICENSE. THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND
 * CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT
 * NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 * PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL SEMTECH CORPORATION BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

#include <stdint.h>   // C99 types
#include <stdbool.h>  // bool type

#include <zephyr/kernel.h>
#include <zephyr/drivers/gpio.h>

#include <zephyr/kernel.h>
#include <zephyr/drivers/gpio.h>
#include <zephyr/devicetree.h>
#include <zephyr/device.h>

#include "app_periodic_uplink.h"
#include "app_ping_pong.h"
#define SMTC_HAL_DBG_TRACE_C
#include "main_ping_pong.h"

#include "smtc_hal_dbg_trace.h"
#include <smtc_zephyr_usp_api.h>
#include "smtc_sw_platform_helper.h"

#include <zephyr/lorawan_lbm/lorawan_hal_init.h>
#include <smtc_modem_hal.h>

#if DT_HAS_CHOSEN( zephyr_display )
#include "oled_display.h"
#endif

/*
 * -----------------------------------------------------------------------------
 * --- PRIVATE MACROS-----------------------------------------------------------
 */

#define FORCE_MASTER_MODE 1  // Set to 1 to force this device as Master on startup

LOG_MODULE_REGISTER( usp, LOG_LEVEL_INF );

/*
 * -----------------------------------------------------------------------------
 * --- PRIVATE CONSTANTS -------------------------------------------------------
 */

/**
 * @brief Watchdog counter reload value during sleep (The period must be lower than MCU watchdog period (here 32s))
 */
#define WATCHDOG_RELOAD_PERIOD_MS 20000

/**
 * @brief Blue user button or BUTTON 1 on nrf52840-dk
 */

#define USER_BUTTON_NODE DT_ALIAS( smtc_user_button )
#if !DT_NODE_HAS_STATUS( USER_BUTTON_NODE, okay )
#error "Unsupported board: smtc-user-button devicetree alias is not defined"
#endif
static const struct gpio_dt_spec button = GPIO_DT_SPEC_GET_OR( USER_BUTTON_NODE, gpios, { 0 } );
static struct gpio_callback      button_cb_data;

/*
 * -----------------------------------------------------------------------------
 * --- PRIVATE TYPES -----------------------------------------------------------
 */
static volatile bool user_button_is_press;  // Flag for button status

/*
 * -----------------------------------------------------------------------------
 * --- PRIVATE VARIABLES -------------------------------------------------------
 */

/*
 * -----------------------------------------------------------------------------
 * --- PRIVATE FUNCTIONS DECLARATION -------------------------------------------
 * Prototypes for internal helper functions.
 */

/**
 * @brief User callback for button EXTI
 *
 * @param context Define by the user at the init
 */
static void user_button_callback( const void* context );

/**
 * @brief Configure User Button
 *
 */
static int configure_user_button( void );

/*
 * -----------------------------------------------------------------------------
 * --- PUBLIC FUNCTIONS DEFINITION ---------------------------------------------
 */

/* A binary semaphore to notify the main LBM loop */
K_SEM_DEFINE( periodical_uplink_event_sem, 0, 1 );

/* for zephyr compat*/
void button_pressed( const struct device* dev, struct gpio_callback* cb, uint32_t pins )
{
    printk( "%s", __func__ );
    user_button_callback( dev );
}

int main( void )
{
    // Wait for picocom to attach
    k_msleep(2000);
    printk("TRACE: Wake up after 2s!\n");
    printk("====== ENTERING MAIN ======\n");
    int err;
    uint32_t reset_cause;
    if( configure_user_button( ) != 0 )
    {
        LOG_ERR( "Issue when configuring user button, aborting\n" );
        return 1;
    }

    SMTC_HAL_TRACE_INFO( "===== Ping Pong example =====\r\n" );

    printk("TRACE: before SMTC_SW_PLATFORM_INIT\n");
    SMTC_SW_PLATFORM_INIT( );
    printk("TRACE: after SMTC_SW_PLATFORM_INIT, before smtc_rac_init\n");
    SMTC_SW_PLATFORM_VOID( smtc_rac_init( ) );

    printk("TRACE: before init_leds\n");
    // initialize LEDs
    init_leds( );

    printk("TRACE: before ping_pong_init\n");
    ping_pong_init( );
    printk("TRACE: before periodic_uplink_init\n");
    periodic_uplink_init( );
    printk("TRACE: before loop\n");
    set_led( SMTC_PF_LED_TX, false );
    set_led( SMTC_PF_LED_RX, false );

    // initialize and start applications
#if DT_HAS_CHOSEN( zephyr_display )
    oled_display_init( );
    oled_cls( );
    oled_show_str( 10, 3, "PING-PONG DEMO", 1 );
#endif

    ping_pong_init( );
    periodic_uplink_init( );

    if( FORCE_MASTER_MODE )
    {
        LOG_INF( "!!! FORCING MASTER MODE ON STARTUP !!!" );
        user_button_is_press = true;
    }

    // Main application loop
    uint32_t loop_count = 0;
    while( true )
    {
        // Check button
        if( user_button_is_press == true )
        {
            user_button_is_press = false;
            LOG_INF( "Button event detected, triggering Ping..." );
            ping_pong_on_button_press( );
            periodic_uplink_on_button_press( );
        }

        // Heartbeat log every ~10 seconds to confirm MCU is alive
        if( ++loop_count % 10 == 0 )
        {
            LOG_INF( "MCU Heartbeat - System is running stable" );
        }

        // Wait for button events or watchdog reload period
        k_sem_take( &periodical_uplink_event_sem, K_MSEC( 1000 ) );
    }
    return 0;
}

/*
 * -----------------------------------------------------------------------------
 * --- PRIVATE FUNCTIONS DEFINITION --------------------------------------------
 */

static int configure_user_button( void )
{
    int ret = 0;
    if( !gpio_is_ready_dt( &button ) )
    {
        printk( "Error: button device %s is not ready\n", button.port->name );
        return 1;
    }

    ret = gpio_pin_configure_dt( &button, GPIO_INPUT );
    if( ret != 0 )
    {
        printk( "Error %d: failed to configure %s pin %d\n", ret, button.port->name, button.pin );
        return 1;
    }

    ret = gpio_pin_interrupt_configure_dt( &button, GPIO_INT_EDGE_TO_ACTIVE );
    if( ret != 0 )
    {
        printk( "Error %d: failed to configure interrupt on %s pin %d\n", ret, button.port->name, button.pin );
        return 1;
    }

    gpio_init_callback( &button_cb_data, button_pressed, BIT( button.pin ) );
    gpio_add_callback( button.port, &button_cb_data );

    return 0;
}

static void user_button_callback( const void* context )
{
    LOG_INF( "Button pushed\n" );

    ( void ) context;  // Not used in the example - avoid warning

    static uint32_t last_press_timestamp_ms = 0;

    // Debounce the button press, avoid multiple triggers
    if( ( int32_t ) ( smtc_modem_hal_get_time_in_ms( ) - last_press_timestamp_ms ) > 500 )
    {
        last_press_timestamp_ms = smtc_modem_hal_get_time_in_ms( );
        user_button_is_press    = true;
    }
    // Wake up the main thread
    k_sem_give( &periodical_uplink_event_sem );
}

/* --- EOF ------------------------------------------------------------------ */
