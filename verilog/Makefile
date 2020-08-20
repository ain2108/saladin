

.PHONY: compile sim clean

compile:
	iverilog -g2005-sv -o sim -c modules.txt -s rr_scheduling_kernel_tb

sim:
	echo "finish" | vvp sim -lxt2
	/Applications/gtkwave.app/Contents/Resources/bin/gtkwave test.vcd

clean:
	rm sim
	rm test.vcd
