`define QUOTE(q) `"q`"

`define assert_true(condition, error_string) \
    if (!condition) begin \
        $display("ASSERTION FAILED: %s", error_string); \
        $finish; \
    end

`define assert(signal, value) \
    if (signal !== value) begin \
        $display("ASSERTION FAILED in %m on %s: actual: %h != expected: %h",`QUOTE(signal), signal, value); \
        $finish(1); \
    end