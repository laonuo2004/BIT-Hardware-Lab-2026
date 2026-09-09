`timescale 1ns/1ps
module illegal_tb;
`include "test_support.vh"
initial begin
 fresh;
 if($test$plusargs("ILLEGAL")) begin
  imem[0]=32'hffffffff;
  start_cpu;repeat(20) @(negedge clk);
  $fatal(1,"MISSING_ILLEGAL_TRAP");
 end else begin
  imem[0]=enc_j(8,0);imem[1]=32'hffffffff;imem[2]=enc_j(0,0);
  start_cpu;until_pc(8);$display("ILLEGAL_FLUSH_PASS");$finish;
 end
end
endmodule
