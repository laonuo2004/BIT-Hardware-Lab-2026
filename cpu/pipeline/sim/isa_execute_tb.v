`timescale 1ns/1ps
module isa_execute_tb;
`include "test_support.vh"
initial begin
 fresh;
 imem[0]=enc_i(18,0,0,1,7'h13);
 imem[1]=enc_i(15,1,6,2,7'h13);
 imem[2]=enc_i(15,1,7,3,7'h13);
 imem[3]=enc_i(-1,0,6,4,7'h13);
 imem[4]=enc_r(0,3,2,0,5); // add 31+2
 imem[5]=enc_r(32,3,2,0,6); // sub 31-2
 imem[6]=enc_r(0,3,2,4,7); // xor
 imem[7]=enc_r(0,3,1,6,8); // or
 imem[8]=enc_r(0,2,1,7,9); // and
 imem[9]=32'h12345537; // lui x10,12345
 imem[10]=enc_s(0,5,0);
 imem[11]=enc_i(0,0,2,11,7'h03);
 imem[12]=enc_b(8,5,11,0); // beq taken, load -> branch
 imem[13]=enc_s(4,1,0);
 imem[14]=enc_b(8,3,2,1); // bne taken
 imem[15]=enc_s(4,1,0);
 imem[16]=enc_b(8,1,4,4); // blt -1,18
 imem[17]=enc_s(4,1,0);
 imem[18]=enc_b(8,4,1,5); // bge 18,-1
 imem[19]=enc_s(4,1,0);
 imem[20]=enc_j(8,12);
 imem[21]=enc_s(4,1,0);
 imem[22]=enc_i(7,0,0,0,7'h13);
 imem[23]=enc_b(8,1,4,5); // bge -1,18 not taken
 imem[24]=enc_i(9,0,0,13,7'h13);
 imem[25]=enc_j(0,0);
 start_cpu;until_pc(100);
 check_reg(0,0);check_reg(1,18);check_reg(2,31);check_reg(3,2);
 check_reg(4,32'hffffffff);check_reg(5,33);check_reg(6,29);check_reg(7,29);
 check_reg(8,18);check_reg(9,18);check_reg(10,32'h12345000);check_reg(11,33);
 check_reg(12,84);check_reg(13,9);
 if(writes!=1 || dmem[0]!==33 || dmem[1]!==0 || retired!=21) $fatal(1,"ISA_SIDE_EFFECT writes=%0d retired=%0d",writes,retired);
 $display("ISA_EXECUTE_PASS");$finish;
end
endmodule
