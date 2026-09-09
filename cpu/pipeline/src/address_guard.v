`timescale 1ns/1ps
module address_guard(input [31:0] addr, output bad, output [1:0] reason);
    wire aligned = (addr[1:0] == 2'b00);
    wire mapped = (addr < 32'h00000400) ||
                  (addr == 32'h40000000) || (addr == 32'h40000004) ||
                  (addr == 32'h40000008) || (addr == 32'h4000000c);
    assign bad = !aligned || !mapped;
    assign reason = !aligned ? 2'd1 : (!mapped ? 2'd2 : 2'd0);
endmodule
