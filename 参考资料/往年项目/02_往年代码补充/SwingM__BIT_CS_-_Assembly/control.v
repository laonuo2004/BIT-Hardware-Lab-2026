`timescale 1ns / 1ps

`include "macro.vh"

module control(
    input   [5:0]   opcode,
    input   [5:0]   func,
    
    output          cu_c1,  // using  c1 ? imm      : rt        as  alu_in2
    output          cu_c2,  // using  c2 ? rd       : rt        as  alu_out
    output          cu_c3,  // using  c3 ? imm      : rs        as  alu_in1
    output          cu_c4,  // using  c4 ? alu_out  : d_rdata   as  reg_wd
    output  [3:0]   cu_cA,  // alu cmd
    output          cu_jmp,
    output          cu_br,
    output          d_we,   // data saver energitic signal 
    output          reg_we
    );

    wire [3:0] inst_id = get_inst_id(opcode, func);
    function [3:0] get_inst_id(input [5:0] opcode, input [5:0] func);
    begin
        case (opcode)
            `INST_LUI   : get_inst_id = `ID_LUI;
            `INST_ORI   : get_inst_id = `ID_ORI;
            `INST_SW    : get_inst_id = `ID_SW;
            `INST_LW    : get_inst_id = `ID_LW;
            `INST_BEQ   : get_inst_id = `ID_BEQ;
            `INST_J     : get_inst_id = `ID_J;
            `INST_NOR   : get_inst_id = `ID_NOR;  // my own instruction
            `INST_FUNC  : begin
                case (func)
                    `FUNC_ADD   : get_inst_id = `ID_ADD;
                    default     : get_inst_id = `ID_NULL;
                endcase
            end
            default     : get_inst_id = `ID_NULL;
        endcase
    end
    endfunction
      
    reg [7:0] mask_c1 = 8'b00110011;
    assign cu_c1  = mask_c1[inst_id];
    
    reg [7:0] mask_c2 = 8'b01000000;
    assign cu_c2  = mask_c2[inst_id];
    
    assign cu_c3  = 1'b0;
    
    assign cu_c4  = (inst_id == `ID_LW ) ? 1 : 0;
          
    assign cu_cA  = get_alu_op(inst_id);
    function [3:0] get_alu_op(input [3:0] inst_id);
    begin
        case (inst_id)
            `ID_SW, `ID_LW, `ID_ADD : get_alu_op = `ALU_ADD;
            // Because Lw&Sw need add operation, they all gose to ALU to be added //
            `ID_LUI                 : get_alu_op = `ALU_LUI;
            `ID_BEQ                 : get_alu_op = `ALU_SUB;
            `ID_ORI                 : get_alu_op = `ALU_OR;
            `ID_NOR                 : get_alu_op = `ALU_NOR;  // my own instruction
            default                 : get_alu_op = `ALU_NULL;
        endcase
    end
    endfunction
                   
    assign cu_br  = (inst_id == `ID_BEQ) ? 1 : 0;
    
    assign cu_jmp = (inst_id == `ID_J  ) ? 1 : 0;
                   
    assign d_we   = (inst_id == `ID_SW ) ? 1 : 0;
    
    reg [7:0] mask_regwe = 8'b01110010;
    assign reg_we = mask_regwe[inst_id];
    
endmodule
