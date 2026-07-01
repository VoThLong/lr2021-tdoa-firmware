openocd -f board/st_nucleo_l073rz.cfg &
OPENOCD_PID=$!
sleep 2
/home/dashtrad/.local/zephyr-sdk-1.0.1/gnu/arm-zephyr-eabi/bin/arm-zephyr-eabi-gdb build/zephyr/zephyr.elf -batch -ex "target extended-remote localhost:3333" -ex "monitor reset halt" -ex "b z_fatal_error" -ex "c" -ex "bt"
kill $OPENOCD_PID
