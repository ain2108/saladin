

.PHONY: compile sim clean test
.SILENT: compile sim clean test

compile:
	iverilog -g2005-sv -o sim -c modules.txt -s rr_scheduling_kernel_tb

sim:
	echo "finish" | vvp sim -lxt2
	/Applications/gtkwave.app/Contents/Resources/bin/gtkwave test.vcd

test:
	iverilog -g2005-sv -o test_sim -c modules.txt -s memory_tb
	vvp test_sim -lxt2
	rm test_sim
	
	iverilog -g2005-sv -o test_sim -c modules.txt -s test_pivots_rr_scheduling_kernel_tb
	vvp test_sim -lxt2
	rm test_sim
	
	iverilog -g2005-sv -o test_sim -c modules.txt -s test_request_selection_rr_scheduling_kernel_tb
	vvp test_sim -lxt2
	rm test_sim
	
	iverilog -g2005-sv -o test_sim -c modules.txt -s test_request_mux_tb
	vvp test_sim -lxt2
	rm test_sim

clean:
	rm -f sim
	rm -f test.vcd
	rm -f memory_sim
	rm -f memory_tb.vcd
