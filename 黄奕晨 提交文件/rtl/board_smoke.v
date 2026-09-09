`timescale 1ns/1ps
// EES-338 clock/JTAG sanity check. LED0 toggles about once per second.
module board_smoke(input clk_100m,input resetn,output led0);
 reg [25:0] count=0;
 always @(posedge clk_100m) begin
  if(!resetn) count<=0;
  else count<=count+1'b1;
 end
 assign led0=count[25];
endmodule
