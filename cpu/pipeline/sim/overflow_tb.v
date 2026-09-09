`timescale 1ns/1ps
module overflow_tb;
`include "test_support.vh"
task setup_values;
begin
 fresh;
 imem[0]=32'h80000137; // lui x2,80000
 imem[1]=enc_i(-1,0,0,3,7'h13);
 imem[2]=enc_r(0,3,2,4,1); // x1=7fffffff without overflow
 imem[3]=enc_i(1,0,0,4,7'h13);
end endtask
task arithmetic;input [31:0] instruction,expected;input flag;
begin
 setup_values;imem[12]=instruction;imem[13]=enc_j(0,0);
 start_cpu;until_pc(52);check_reg(5,expected);
 if(of!==flag) $fatal(1,"OVERFLOW expected=%b got=%b",flag,of);
 repeat(5) @(negedge clk);if(of!==flag) $fatal(1,"OVERFLOW_STICKY");
end endtask
integer n;
initial begin
 arithmetic(enc_r(0,4,1,0,5),32'h80000000,1);
 arithmetic(enc_r(32,4,2,0,5),32'h7fffffff,1);
 arithmetic(enc_r(0,3,2,0,5),32'h7fffffff,1);
 arithmetic(enc_i(1,1,0,5,7'h13),32'h80000000,1);
 arithmetic(enc_i(-1,2,0,5,7'h13),32'h7fffffff,1);
 arithmetic(enc_r(0,4,4,0,5),2,0);
 setup_values;imem[12]=enc_r(0,4,1,0,0);imem[13]=enc_j(0,0);
 start_cpu;until_pc(52);if(!of) $fatal(1,"X0_OVERFLOW");check_reg(0,0);
 setup_values;imem[11]=enc_j(12,0);imem[12]=enc_r(0,4,1,0,5);imem[14]=enc_j(0,0);
 start_cpu;until_pc(56);if(of) $fatal(1,"WRONG_PATH_OVERFLOW");
 setup_values;imem[12]=enc_s(1,0,1); // address add overflows but is not arithmetic
 start_cpu;n=0;while(!fv && n<100)begin @(negedge clk);n=n+1;end
 if(!fv || of) $fatal(1,"ADDRESS_OVERFLOW_EXCLUDED");
 setup_values;imem[12]=enc_i(1024,0,2,5,7'h03);imem[13]=enc_r(0,4,1,0,6);
 start_cpu;n=0;while(!fv && n<100)begin @(negedge clk);n=n+1;end
 if(!fv || of) $fatal(1,"YOUNGER_OVERFLOW_KILLED");
 setup_values;imem[12]=enc_r(0,4,1,0,5);imem[13]=enc_i(1024,0,2,6,7'h03);
 start_cpu;n=0;while(!fv && n<100)begin @(negedge clk);n=n+1;end
 if(!fv || !of) $fatal(1,"OLDER_OVERFLOW_PRESERVED");check_reg(5,32'h80000000);
 fresh;#1;if(of) $fatal(1,"OVERFLOW_RESET");
 $display("OVERFLOW_PASS");$finish;
end
endmodule
