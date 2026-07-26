database -open rtl_wave -shm -into runs/manual_tcl_util65/rtl_wave.shm
probe -create -database rtl_wave cpu_4bit_tb -all -depth all
run
exit
