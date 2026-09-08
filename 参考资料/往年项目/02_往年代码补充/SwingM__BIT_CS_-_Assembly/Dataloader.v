`timescale 1ns / 1ps

`include "macro.vh"

module Dataloader(
    input wire [1:0]    in_we,       // write energitic
    input wire [31:0]   in_address,    // A
    input wire [31:0]   in_wd,
    output wire[31:0]   out_1
    );
    
/****************************************************
Input WE will turn on the function.

A is the Address calculated by the ALU component.

WD is read by the RD2_out from the Regfile as the 
writen data.

RD is the output and will be choose by the mux signal.

****************************************************/
assign out_1 = (in_we == 0) ? 0: in_wd;

endmodule