`timescale 1ns/1ps
// EES-338 100 MHz -> 10 MHz check. LED0 toggles on the 10 MHz domain.
module board_clk(input clk_100m,input resetn,output led0);
 wire clk_10m;
 wire locked;
 clk_wiz_0 u_clk(
  .clk_in1(clk_100m),
  .resetn(resetn),
  .clk_out1(clk_10m),
  .locked(locked)
 );
 wire rst_n=resetn & locked;
 reg [23:0] count=0;
 always @(posedge clk_10m) begin
  if(!rst_n) count<=0;
  else count<=count+1'b1;
 end
 assign led0=count[23];
endmodule
