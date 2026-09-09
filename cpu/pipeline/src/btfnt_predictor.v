`timescale 1ns/1ps
module btfnt_predictor #(parameter PREDICT_EN=1)(
    input [31:0] pc,imm, input is_cond_branch, output [31:0] predicted_next_pc
);
    assign predicted_next_pc=(PREDICT_EN && is_cond_branch && imm[31])
                             ? pc+imm : pc+32'd4;
endmodule
