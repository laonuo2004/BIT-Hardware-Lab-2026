`timescale 1ns/1ps
module f1_extended_tb;
`include "test_support.vh"

task expect_mem;
 input integer index;
 input [31:0] expected;
 begin
  if(dmem[index]!==expected)
   $fatal(1,"F1_MEM index=%0d expected=%h got=%h",index,expected,dmem[index]);
 end
endtask

initial begin
 // 两个源寄存器相关，以及连续写同一目的寄存器。
 fresh;
 imem[0]=enc_i(5,0,0,1,7'h13);       // addi x1,x0,5
 imem[1]=enc_i(7,0,0,2,7'h13);       // addi x2,x0,7
 imem[2]=enc_r(0,2,1,0,3);           // add  x3,x1,x2
 imem[3]=enc_i(1,3,0,3,7'h13);       // addi x3,x3,1
 imem[4]=enc_i(1,3,0,3,7'h13);       // addi x3,x3,1
 imem[5]=enc_s(0,3,0);               // sw   x3,0(x0)
 imem[6]=enc_j(0,0);
 start_cpu;until_pc(24);
 expect_mem(0,14);check_reg(3,14);
 if(writes!=1 || fv) $fatal(1,"F1_CHAIN writes=%0d fault=%b",writes,fv);
 $display("F1_CHAIN_PASS");

 // 存储地址、存储数据和加载结果连续相关。
 fresh;
 imem[0]=enc_i(16,0,0,1,7'h13);      // addi x1,x0,16
 imem[1]=enc_i(42,0,0,2,7'h13);      // addi x2,x0,42
 imem[2]=enc_s(0,2,1);               // sw   x2,0(x1)
 imem[3]=enc_i(0,1,2,3,7'h03);       // lw   x3,0(x1)
 imem[4]=enc_s(4,3,1);               // sw   x3,4(x1)
 imem[5]=enc_j(0,0);
 start_cpu;until_pc(20);
 expect_mem(4,42);expect_mem(5,42);check_reg(3,42);
 if(writes!=2 || fv) $fatal(1,"F1_STORE_DEP writes=%0d fault=%b",writes,fv);
 $display("F1_STORE_DEP_PASS");

 // 分支操作数相关，并检查错误路径存储被冲刷。
 fresh;
 imem[0]=enc_i(9,0,0,1,7'h13);
 imem[1]=enc_i(9,0,0,2,7'h13);
 imem[2]=enc_r(32,2,1,0,3);          // sub  x3,x1,x2
 imem[3]=enc_b(8,0,3,0);             // beq  x3,x0,+8
 imem[4]=enc_s(0,1,0);               // wrong path
 imem[5]=enc_i(77,0,0,4,7'h13);
 imem[6]=enc_s(4,4,0);
 imem[7]=enc_j(0,0);
 start_cpu;until_pc(28);
 expect_mem(0,0);expect_mem(1,77);check_reg(4,77);
 if(writes!=1 || fv) $fatal(1,"F1_BRANCH_DEP writes=%0d fault=%b",writes,fv);
 $display("F1_BRANCH_DEP_PASS");

 // 1 KiB RAM 最后一个对齐字地址 0x3FC。
 fresh;
 imem[0]=enc_i(1020,0,0,1,7'h13);
 imem[1]=enc_i(77,0,0,2,7'h13);
 imem[2]=enc_s(0,2,1);
 imem[3]=enc_i(0,1,2,3,7'h03);
 imem[4]=enc_j(0,0);
 start_cpu;until_pc(16);
 expect_mem(255,77);check_reg(3,77);
 if(writes!=1 || fv) $fatal(1,"F1_RAM_BOUNDARY writes=%0d fault=%b",writes,fv);
 $display("F1_RAM_BOUNDARY_PASS");

 $display("F1_EXTENDED_PASS");
 $finish;
end
endmodule
