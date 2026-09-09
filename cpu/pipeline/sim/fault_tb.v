`timescale 1ns/1ps
module fault_tb;
`include "test_support.vh"
integer n, before_retired;reg [31:0] saved_pc;
task bad_access;input [31:0] address;input is_write;input [1:0] why;
begin
 fresh;
 imem[0]={address[31:12],5'd1,7'h37};
 imem[1]=enc_i(address[11:0],1,0,1,7'h13);
 imem[5]=enc_i(7,0,0,5,7'h13); // older WB must finish
 imem[6]=is_write?enc_s(0,0,1):enc_i(0,1,2,6,7'h03);
 imem[7]=enc_j(12,0); // simultaneous EX redirect must lose
 imem[8]=enc_s(0,5,0);
 imem[10]=enc_s(4,5,0);
 start_cpu;
 n=0;while(!fv && n<80) begin @(posedge clk);#1;n=n+1;end
 if(!fv || fpc!==24 || fa!==address || fr!==why) $fatal(1,"FAULT_RECORD pc=%h addr=%h reason=%d",fpc,fa,fr);
 check_reg(5,7);check_reg(6,0);
 before_retired=retired;saved_pc=ia;
 repeat(20) begin @(posedge clk);#1;
  if(dv || rv || ia!==saved_pc || fpc!==24 || fa!==address || fr!==why) $fatal(1,"FAULT_NOT_STABLE");
 end
 if(writes!=0 || retired!=before_retired) $fatal(1,"FAULT_SIDE_EFFECT");
end endtask
always @(posedge clk) if(resetn && rv && rpc>=24) $fatal(1,"FAULT_YOUNGER_RETIRE pc=%h",rpc);
initial begin
 bad_access(2,1,1);bad_access('h400,0,2);bad_access('h40000010,1,2);bad_access('h40000011,0,1);
 fresh;imem[0]=enc_i(11,0,0,5,7'h13);imem[1]=enc_j(0,0);start_cpu;until_pc(4);
 if(fv || fpc || fa || fr) $fatal(1,"FAULT_RESET");check_reg(5,11);
 $display("FAULT_PASS");$finish;
end
endmodule
