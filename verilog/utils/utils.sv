`define assert(signal, value) \
    if (signal !== value) begin \
        $display("ASSERTION FAILED in %m: actual: %h != expected: %h", signal, value); \
        $finish; \
    end