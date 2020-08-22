
`define assert_true(condition, error_string) \
    if (!condition) begin \
        $display("ASSERTION FAILED: %s", error_string); \
        $finish; \
    end

`define assert(signal, value) \
    if (signal !== value) begin \
        $display("ASSERTION FAILED in %m: actual: %h != expected: %h", signal, value); \
        $finish; \
    end