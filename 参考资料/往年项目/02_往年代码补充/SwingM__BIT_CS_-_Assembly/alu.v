`timescale 1ns / 1ps

`include "macro.vh"

module alu(
  
    input  wire [3:0]  alu_op,
    input  wire [31:0] alu_in1,
    input  wire [31:0] alu_in2,
   
    output wire [31:0] alu_out,
    output wire        alu_zero
    );
    
    reg err;
    reg zero;
    
    wire [31:0] in1   = alu_in1;
    wire [31:0] in2   = alu_in2;
    wire [31:0] in2_u = {16'b0, alu_in2[15:0]};
    wire [4:0]  sa    = alu_in1[10:6];
    
    wire [31:0] o_or  = in1 | in2_u;
    wire [31:0] o_lui = {alu_in2[15:0], 16'b0};
    // Random instruction is nor ↓
    wire [31:0] o_nor = ~(o_or);

    
    wire [32:0] in1_e = {alu_in1[31], alu_in1};
    wire [32:0] in2_e = {alu_in2[31], alu_in2};
    
    wire [32:0] o_add = in1_e + in2_e;
    wire [32:0] o_addiu = in1_3 + in2_e;    // when the op is addiu, then the in2_e wiil be the immediate number
    wire [32:0] o_sub = in1_e - in2_e;

    assign alu_out = (alu_op == `ALU_ADD) ? o_add[31:0] :
                     (alu_op == `ALU_SUB) ? o_sub[31:0] :
                     (alu_op == `ALU_OR ) ? o_or  :
                     (alu_op == `ALU_LUI) ? o_lui : 
                     (alu_op == `ALU_ADDIU) ? o_addiu:
                     (alu_op == `ALU_NOR) ? o_nor : 32'b0;
                     // seld defined instruction, also need to modigy the macro file
                     
                     
       
    assign alu_zero = (alu_out == 32'b0) ? 1 : 0;

endmodule
