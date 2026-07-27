database -open postlayout_npcfix_wave -shm -into runs/manual_tcl_util65_v2/post_layout_npcfix_wave.shm
probe -create -database postlayout_npcfix_wave cpu_4bit_tb_postlayout -all -depth all
run
exit
