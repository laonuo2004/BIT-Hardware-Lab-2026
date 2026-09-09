`timescale 1ns/1ps
module address_guard_tb;
reg [31:0] addr;wire bad;wire [1:0] reason;
address_guard dut(addr,bad,reason);
task check;input [31:0] a;input [1:0] why;begin
 addr=a;#1;if(bad!==(why!=0)||reason!==why) $fatal(1,"ADDRESS_GUARD addr=%h reason=%d",addr,reason);
end endtask
initial begin
 check(0,0);check('h3fc,0);check('h40000000,0);check('h40000004,0);check('h40000008,0);check('h4000000c,0);
 check(2,1);check('h3ff,1);check('h400,2);check('h80000000,2);check('h40000010,2);check('h40000011,1);
 $display("ADDRESS_GUARD_PASS");$finish;
end
endmodule
