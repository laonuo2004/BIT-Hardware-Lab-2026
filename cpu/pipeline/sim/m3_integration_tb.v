`timescale 1ns/1ps
module m3_integration_tb;
`include "test_support.vh"
integer n;
task values;
begin
 fresh;imem[0]=32'h80000137;imem[1]=enc_i(-1,0,0,3,7'h13);imem[2]=enc_r(0,3,2,4,1);
end endtask
task await_fault;
begin
 start_cpu;n=0;while(!fv && n<100) begin @(negedge clk);n=n+1;end
 if(!fv) $fatal(1,"M3_FAULT_TIMEOUT");
 repeat(20) begin @(negedge clk);if(rv||dv) $fatal(1,"M3_HALT_SIDE_EFFECT");end
end endtask
initial begin
 values;
 imem[10]=enc_i(1,1,0,5,7'h13); // older overflow WB
 imem[11]=enc_i(1024,0,2,6,7'h03); // fault MEM
 imem[12]=enc_b(12,0,0,0); // younger branch EX must not count
 imem[13]=32'hffffffff; // younger illegal ID must not assert
 await_fault;
 if(!of || bc!==0 || mc!==0 || fpc!==44 || fa!==1024 || fr!==2 || writes!=0) $fatal(1,"M3_OLD_WB");
 check_reg(5,32'h80000000);check_reg(6,0);
 values;
 imem[10]=enc_i(1024,0,2,6,7'h03);
 imem[11]=enc_i(1,1,0,5,7'h13);
 imem[12]=32'hffffffff;
 await_fault;
 if(of || bc!==0 || mc!==0 || fpc!==40) $fatal(1,"M3_YOUNG_OVERFLOW");check_reg(5,0);
 values;
 imem[10]=enc_b(12,0,0,0);
 imem[11]=enc_s(1024,0,0); // wrong path invalid access
 imem[12]=enc_i(1,1,0,5,7'h13); // wrong path overflow
 imem[13]=enc_b(8,0,0,1); // not taken
 imem[14]=enc_i(9,0,0,6,7'h13);
 imem[15]=enc_j(8,0);
 imem[16]=32'hffffffff;
 imem[17]=enc_j(0,0);
 start_cpu;until_pc(68);
 if(of || fv || bc!==2 || mc!==1 || writes!=0) $fatal(1,"M3_FLUSH");check_reg(5,0);check_reg(6,9);
 $display("M3_INTEGRATION_PASS");$finish;
end
endmodule
