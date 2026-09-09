`timescale 1ns/1ps

module PipelineCPU #(parameter PREDICT_EN=1)(
    input clk, input resetn,
    output [31:0] imem_addr, input [31:0] imem_rdata,
    output dmem_valid, output dmem_write,
    output [31:0] dmem_addr, output [31:0] dmem_wdata,
    input [31:0] dmem_rdata,
    output retire_valid, output [31:0] retire_pc,
    output retire_reg_write, output [4:0] retire_rd,
    output [31:0] retire_wdata,
    output reg fault_valid, output reg [31:0] fault_pc, fault_addr,
    output reg [1:0] fault_reason, output overflow_flag,
    output reg [31:0] branch_count, mispredict_count
);
    localparam WB_ALU=2'd0, WB_MEM=2'd1, WB_PC4=2'd2, WB_IMM=2'd3;
    localparam ALU_ADD=4'd0, ALU_SUB=4'd1, ALU_OR=4'd2, ALU_XOR=4'd3, ALU_AND=4'd4;
    localparam BR_NONE=3'd0, BR_BEQ=3'd1, BR_BNE=3'd2, BR_BLT=3'd3, BR_BGE=3'd4, BR_JAL=3'd5;
    localparam IMM_NONE=3'd0, IMM_I=3'd1, IMM_S=3'd2, IMM_B=3'd3, IMM_U=3'd4, IMM_J=3'd5;

    reg [31:0] idex_predicted_next_pc;
    reg exmem_cond_branch, exmem_mispredict, memwb_cond_branch, memwb_mispredict;
    reg overflow_sticky;
    reg idex_overflow_eligible, exmem_overflow, memwb_overflow;
    reg [31:0] pc;
    reg ifid_valid; reg [31:0] ifid_pc, ifid_instr;
    reg idex_valid; reg [31:0] idex_pc, idex_a, idex_b, idex_imm; reg [4:0] idex_rd;
    reg idex_reg_write, idex_mem_write, idex_alu_src; reg [1:0] idex_wb_sel;
    reg [3:0] idex_alu_op; reg [2:0] idex_branch_op;
    reg exmem_valid; reg [31:0] exmem_pc, exmem_alu, exmem_store, exmem_imm; reg [4:0] exmem_rd;
    reg exmem_reg_write, exmem_mem_write; reg [1:0] exmem_wb_sel;
    reg memwb_valid; reg [31:0] memwb_pc, memwb_data; reg [4:0] memwb_rd; reg memwb_reg_write;
    reg [31:0] regs[0:31]; integer i;

    wire [6:0] op=ifid_instr[6:0]; wire [2:0] f3=ifid_instr[14:12]; wire [6:0] f7=ifid_instr[31:25];
    wire [4:0] id_rs1=ifid_instr[19:15], id_rs2=ifid_instr[24:20];
    reg dec_reg_write, dec_mem_write, dec_alu_src, dec_rs1, dec_rs2, dec_illegal;
    reg [1:0] dec_wb_sel; reg [3:0] dec_alu_op; reg [2:0] dec_branch_op, dec_imm_type; reg [31:0] dec_imm;
    always @(*) begin
        dec_reg_write=0; dec_mem_write=0; dec_alu_src=0; dec_rs1=0; dec_rs2=0; dec_illegal=1;
        dec_wb_sel=WB_ALU; dec_alu_op=ALU_ADD; dec_branch_op=BR_NONE; dec_imm_type=IMM_NONE;
        case(op)
          7'b0110011: begin dec_rs1=1; dec_rs2=1; case({f7,f3})
            {7'b0000000,3'b000}: begin dec_reg_write=1;dec_alu_op=ALU_ADD;dec_illegal=0;end
            {7'b0100000,3'b000}: begin dec_reg_write=1;dec_alu_op=ALU_SUB;dec_illegal=0;end
            {7'b0000000,3'b100}: begin dec_reg_write=1;dec_alu_op=ALU_XOR;dec_illegal=0;end
            {7'b0000000,3'b110}: begin dec_reg_write=1;dec_alu_op=ALU_OR; dec_illegal=0;end
            {7'b0000000,3'b111}: begin dec_reg_write=1;dec_alu_op=ALU_AND;dec_illegal=0;end endcase end
          7'b0010011: begin dec_rs1=1; dec_alu_src=1; dec_imm_type=IMM_I; case(f3)
            3'b000: begin dec_reg_write=1;dec_alu_op=ALU_ADD;dec_illegal=0;end
            3'b110: begin dec_reg_write=1;dec_alu_op=ALU_OR; dec_illegal=0;end
            3'b111: begin dec_reg_write=1;dec_alu_op=ALU_AND;dec_illegal=0;end endcase end
          7'b0110111: begin dec_reg_write=1;dec_wb_sel=WB_IMM;dec_imm_type=IMM_U;dec_illegal=0;end
          7'b0000011: if(f3==3'b010) begin dec_rs1=1;dec_reg_write=1;dec_alu_src=1;dec_wb_sel=WB_MEM;dec_imm_type=IMM_I;dec_illegal=0;end
          7'b0100011: if(f3==3'b010) begin dec_rs1=1;dec_rs2=1;dec_mem_write=1;dec_alu_src=1;dec_imm_type=IMM_S;dec_illegal=0;end
          7'b1100011: begin dec_rs1=1;dec_rs2=1;dec_imm_type=IMM_B;case(f3)
            3'b000: begin dec_branch_op=BR_BEQ;dec_illegal=0;end 3'b001: begin dec_branch_op=BR_BNE;dec_illegal=0;end
            3'b100: begin dec_branch_op=BR_BLT;dec_illegal=0;end 3'b101: begin dec_branch_op=BR_BGE;dec_illegal=0;end endcase end
          7'b1101111: begin dec_reg_write=1;dec_wb_sel=WB_PC4;dec_branch_op=BR_JAL;dec_imm_type=IMM_J;dec_illegal=0;end
        endcase
        case(dec_imm_type)
          IMM_I: dec_imm={{20{ifid_instr[31]}},ifid_instr[31:20]};
          IMM_S: dec_imm={{20{ifid_instr[31]}},ifid_instr[31:25],ifid_instr[11:7]};
          IMM_B: dec_imm={{19{ifid_instr[31]}},ifid_instr[31],ifid_instr[7],ifid_instr[30:25],ifid_instr[11:8],1'b0};
          IMM_U: dec_imm={ifid_instr[31:12],12'b0};
          IMM_J: dec_imm={{11{ifid_instr[31]}},ifid_instr[31],ifid_instr[19:12],ifid_instr[20],ifid_instr[30:21],1'b0};
          default: dec_imm=0;
        endcase
    end
    wire dec_cond_branch=(dec_branch_op!=BR_NONE)&&(dec_branch_op!=BR_JAL);
    wire [31:0] id_predicted_next_pc;
    btfnt_predictor #(.PREDICT_EN(PREDICT_EN)) predictor(
        .pc(ifid_pc),.imm(dec_imm),.is_cond_branch(dec_cond_branch),
        .predicted_next_pc(id_predicted_next_pc));
    wire id_predict_redirect=dec_cond_branch&&(id_predicted_next_pc!=ifid_pc+32'd4);
    wire dec_overflow_eligible=!dec_illegal &&
        ((op==7'h33 && f3==0) || (op==7'h13 && f3==0));
    wire [31:0] id_a=(id_rs1==0)?0:regs[id_rs1], id_b=(id_rs2==0)?0:regs[id_rs2];
    wire hazard_rs1=dec_rs1 && id_rs1!=0 && ((idex_valid&&idex_reg_write&&idex_rd==id_rs1)||(exmem_valid&&exmem_reg_write&&exmem_rd==id_rs1)||(memwb_valid&&memwb_reg_write&&memwb_rd==id_rs1));
    wire hazard_rs2=dec_rs2 && id_rs2!=0 && ((idex_valid&&idex_reg_write&&idex_rd==id_rs2)||(exmem_valid&&exmem_reg_write&&exmem_rd==id_rs2)||(memwb_valid&&memwb_reg_write&&memwb_rd==id_rs2));
    wire stall=ifid_valid && !dec_illegal && (hazard_rs1||hazard_rs2);

    wire [31:0] ex_operand_b=idex_alu_src?idex_imm:idex_b;
    reg [31:0] ex_result; always @(*) case(idex_alu_op) ALU_SUB:ex_result=idex_a-ex_operand_b; ALU_OR:ex_result=idex_a|ex_operand_b; ALU_XOR:ex_result=idex_a^ex_operand_b; ALU_AND:ex_result=idex_a&ex_operand_b; default:ex_result=idex_a+ex_operand_b; endcase
    wire ex_overflow;
    overflow_detect overflow_unit(.a(idex_a),.b(ex_operand_b),.result(ex_result),
        .is_sub(idex_alu_op==ALU_SUB),.overflow(ex_overflow));
    wire wb_overflow_event=memwb_valid&&memwb_overflow;
    // WB is older than the MEM load reading the status on this same edge.
    assign overflow_flag=resetn&&(overflow_sticky||wb_overflow_event);
    wire signed [31:0] ex_sa=idex_a, ex_sb=idex_b;
    reg ex_take; always @(*) case(idex_branch_op) BR_BEQ:ex_take=(idex_a==idex_b);BR_BNE:ex_take=(idex_a!=idex_b);BR_BLT:ex_take=(ex_sa<ex_sb);BR_BGE:ex_take=(ex_sa>=ex_sb);BR_JAL:ex_take=1;default:ex_take=0;endcase
    wire ex_cond_branch=(idex_branch_op!=BR_NONE)&&(idex_branch_op!=BR_JAL);
    wire [31:0] ex_actual_next_pc=ex_take?idex_pc+idex_imm:idex_pc+32'd4;
    wire ex_mispredict=ex_cond_branch&&(ex_actual_next_pc!=idex_predicted_next_pc);
    wire redirect=idex_valid&&((idex_branch_op==BR_JAL)||ex_mispredict);
    wire [31:0] redirect_pc=ex_actual_next_pc;

    wire address_bad; wire [1:0] address_reason;
    address_guard guard(.addr(exmem_alu),.bad(address_bad),.reason(address_reason));
    wire raw_mem_access=exmem_valid&&(exmem_mem_write||(exmem_wb_sel==WB_MEM));
    wire mem_fault=raw_mem_access&&address_bad&&!fault_valid;
    assign imem_addr=pc;
    assign dmem_valid=resetn&&raw_mem_access&&!address_bad&&!fault_valid; assign dmem_write=dmem_valid&&exmem_mem_write;
    assign dmem_addr=exmem_alu; assign dmem_wdata=exmem_store;
    assign retire_valid=memwb_valid; assign retire_pc=memwb_pc; assign retire_reg_write=memwb_valid&&memwb_reg_write&&(memwb_rd!=0);
    assign retire_rd=memwb_rd; assign retire_wdata=memwb_data;

    // synthesis translate_off
    always @(posedge clk) if(resetn && !fault_valid && !mem_fault && !redirect && !stall && ifid_valid && dec_illegal)
        $fatal(1,"ILLEGAL_INSTRUCTION pc=%h instruction=%h",ifid_pc,ifid_instr);
    // synthesis translate_on

    always @(posedge clk or negedge resetn) begin
      if(!resetn) begin
        idex_predicted_next_pc<=0;exmem_cond_branch<=0;exmem_mispredict<=0;
        memwb_cond_branch<=0;memwb_mispredict<=0;branch_count<=0;mispredict_count<=0;
        overflow_sticky<=0;idex_overflow_eligible<=0;exmem_overflow<=0;memwb_overflow<=0;
        fault_valid<=0;fault_pc<=0;fault_addr<=0;fault_reason<=0;
        pc<=0; ifid_valid<=0; ifid_pc<=0; ifid_instr<=0;
        idex_valid<=0; idex_pc<=0; idex_a<=0; idex_b<=0; idex_imm<=0; idex_rd<=0;
        idex_reg_write<=0; idex_mem_write<=0; idex_alu_src<=0; idex_wb_sel<=0; idex_alu_op<=0; idex_branch_op<=0;
        exmem_valid<=0; exmem_pc<=0; exmem_alu<=0; exmem_store<=0; exmem_imm<=0; exmem_rd<=0;
        exmem_reg_write<=0; exmem_mem_write<=0; exmem_wb_sel<=0;
        memwb_valid<=0; memwb_pc<=0; memwb_data<=0; memwb_rd<=0; memwb_reg_write<=0;
        for(i=0;i<32;i=i+1) regs[i]<=0;
      end
      else begin
        if(memwb_valid&&memwb_cond_branch) begin
          branch_count<=branch_count+1;
          if(memwb_mispredict) mispredict_count<=mispredict_count+1;
        end
        memwb_cond_branch<=exmem_cond_branch;memwb_mispredict<=exmem_mispredict;
        exmem_cond_branch<=ex_cond_branch;exmem_mispredict<=ex_mispredict;
        if(wb_overflow_event) overflow_sticky<=1;
        memwb_overflow<=exmem_overflow;
        exmem_overflow<=idex_overflow_eligible&&ex_overflow;
        if(memwb_valid&&memwb_reg_write&&memwb_rd!=0) regs[memwb_rd]<=memwb_data;
        memwb_valid<=exmem_valid; memwb_pc<=exmem_pc; memwb_rd<=exmem_rd; memwb_reg_write<=exmem_reg_write;
        case(exmem_wb_sel) WB_MEM:memwb_data<=dmem_rdata;WB_PC4:memwb_data<=exmem_pc+4;WB_IMM:memwb_data<=exmem_imm;default:memwb_data<=exmem_alu;endcase
        exmem_valid<=idex_valid;exmem_pc<=idex_pc;exmem_alu<=ex_result;exmem_store<=idex_b;exmem_imm<=idex_imm;exmem_rd<=idex_rd;exmem_reg_write<=idex_reg_write;exmem_mem_write<=idex_mem_write;exmem_wb_sel<=idex_wb_sel;
        if(fault_valid || mem_fault) begin
          if(!fault_valid) begin
            fault_valid<=1;fault_pc<=exmem_pc;fault_addr<=exmem_alu;fault_reason<=address_reason;
          end
          memwb_valid<=0;exmem_valid<=0;idex_valid<=0;ifid_valid<=0;
        end
        else if(redirect) begin pc<=redirect_pc;ifid_valid<=0;idex_valid<=0;end
        else if(stall) begin idex_valid<=0;end
        else begin
          pc<=pc+4;ifid_valid<=1;ifid_pc<=pc;ifid_instr<=imem_rdata;
          if(ifid_valid&&!dec_illegal&&id_predict_redirect) begin
            pc<=id_predicted_next_pc;ifid_valid<=0;
          end
          idex_predicted_next_pc<=id_predicted_next_pc;
          idex_overflow_eligible<=dec_overflow_eligible;
          idex_valid<=ifid_valid&&!dec_illegal;idex_pc<=ifid_pc;idex_a<=id_a;idex_b<=id_b;idex_imm<=dec_imm;idex_rd<=ifid_instr[11:7];idex_reg_write<=dec_reg_write;idex_mem_write<=dec_mem_write;idex_alu_src<=dec_alu_src;idex_wb_sel<=dec_wb_sel;idex_alu_op<=dec_alu_op;idex_branch_op<=dec_branch_op;
        end
      end
    end
endmodule
