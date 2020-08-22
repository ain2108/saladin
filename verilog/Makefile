

.PHONY: compile sim clean test
.SILENT: compile sim clean test

compile:
	iverilog -g2005-sv -o sim -c modules.txt -s rr_scheduling_kernel_tb

sim:
	echo "finish" | vvp sim -lxt2
	/Applications/gtkwave.app/Contents/Resources/bin/gtkwave test.vcd

test:
	iverilog -g2005-sv -o memory_sim -c modules.txt -s memory_tb
	echo "finish" | vvp memory_sim -lxt2
	rm memory_sim


clean:
	rm sim
	rm test.vcd
	rm memory_sim
