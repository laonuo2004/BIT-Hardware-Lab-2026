`timescale 1ns/1ps
module status_mmio_tb;
`define REAL_ENV
`include "test_support.vh"
`undef REAL_ENV
reg saw_adjacent=0;
always @(posedge clk) if(resetn && dv && !dwe && dut.exmem_pc==40) begin
 if(!rv || rpc!=36) $fatal(1,"STATUS_TEST_NOT_ADJACENT");
 saw_adjacent=1;
end
initial begin
 fresh;
 imem[0]=32'h40000537; // lui x10,40000
 imem[1]=32'h80000137;
 imem[2]=enc_i(-1,0,0,3,7'h13);
 imem[3]=enc_r(0,3,2,4,1);
 imem[9]=enc_i(1,1,0,5,7'h13); // overflow
 imem[10]=enc_i(12,10,2,6,7'h03); // no data dependence on x5
 imem[11]=enc_s(12,0,10); // readonly
 imem[12]=enc_i(12,10,2,7,7'h03);
 imem[13]=enc_j(0,0);
 start_cpu;until_pc(52);
 check_reg(5,32'h80000000);check_reg(6,1);check_reg(7,1);
 if(!saw_adjacent || fv || !of || tx!==1) $fatal(1,"STATUS_MMIO_STATE");
 $display("STATUS_MMIO_PASS");$finish;
end
endmodule
