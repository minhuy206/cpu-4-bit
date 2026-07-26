database -open postlayout_wave -shm -into runs/manual_tcl_util65/post_layout_wave.shm
probe -create -database postlayout_wave cpu_4bit_tb_gls -all -depth all
run
exit
