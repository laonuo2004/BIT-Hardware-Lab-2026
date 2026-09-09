`timescale 1ns / 1ps

module ProgramCounter(
    input clk,
    input rst,
    input [31:0] next_pc,
    output reg [31:0] pc
);
    initial begin
        pc = 32'd0;
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            pc <= 32'd0;
        end else begin
            pc <= next_pc;
        end
    end
endmodule

module InstructionMemory(
    input [31:0] addr,
    output [31:0] instr
);
    reg [31:0] mem [0:255];

    initial begin
        $readmemh("text.mem", mem);
    end

    assign instr = mem[addr[9:2]];
endmodule

module RegisterFile(
    input clk,
    input rst,
    input we,
    input [4:0] raddr1,
    input [4:0] raddr2,
    input [4:0] waddr,
    input [31:0] wdata,
    output [31:0] rdata1,
    output [31:0] rdata2
);
    reg [31:0] regs [0:31];
    integer i;

    initial begin
        for (i = 0; i < 32; i = i + 1) begin
            regs[i] = 32'd0;
        end
    end

    assign rdata1 = (raddr1 == 5'd0) ? 32'd0 : regs[raddr1];
    assign rdata2 = (raddr2 == 5'd0) ? 32'd0 : regs[raddr2];

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            for (i = 0; i < 32; i = i + 1) begin
                regs[i] <= 32'd0;
            end
        end else if (we && waddr != 5'd0) begin
            regs[waddr] <= wdata;
        end
    end
endmodule

module ImmediateGenerator(
    input [31:0] instr,
    input [2:0] imm_type,
    output reg [31:0] imm
);
    localparam IMM_NONE = 3'd0;
    localparam IMM_I    = 3'd1;
    localparam IMM_S    = 3'd2;
    localparam IMM_B    = 3'd3;
    localparam IMM_U    = 3'd4;
    localparam IMM_J    = 3'd5;

    always @(*) begin
        case (imm_type)
            IMM_I: imm = {{20{instr[31]}}, instr[31:20]};
            IMM_S: imm = {{20{instr[31]}}, instr[31:25], instr[11:7]};
            IMM_B: imm = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
            IMM_U: imm = {instr[31:12], 12'b0};
            IMM_J: imm = {{11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0};
            default: imm = 32'd0;
        endcase
    end
endmodule

module ControlUnit(
    input [31:0] instr,
    output reg reg_write,
    output reg mem_write,
    output reg alu_src,
    output reg [1:0] wb_sel,
    output reg [3:0] alu_op,
    output reg [2:0] branch_op,
    output reg [2:0] imm_type,
    output reg uses_rs1,
    output reg uses_rs2,
    output reg illegal_instr
);
    localparam WB_ALU = 2'd0;
    localparam WB_MEM = 2'd1;
    localparam WB_PC4 = 2'd2;
    localparam WB_IMM = 2'd3;

    localparam ALU_ADD = 4'd0;
    localparam ALU_SUB = 4'd1;
    localparam ALU_OR  = 4'd2;
    localparam ALU_XOR = 4'd3;
    localparam ALU_AND = 4'd4;

    localparam BR_NONE = 3'd0;
    localparam BR_BEQ  = 3'd1;
    localparam BR_BNE  = 3'd2;
    localparam BR_BLT  = 3'd3;
    localparam BR_BGE  = 3'd4;
    localparam BR_JAL  = 3'd5;

    localparam IMM_NONE = 3'd0;
    localparam IMM_I    = 3'd1;
    localparam IMM_S    = 3'd2;
    localparam IMM_B    = 3'd3;
    localparam IMM_U    = 3'd4;
    localparam IMM_J    = 3'd5;

    wire [6:0] opcode = instr[6:0];
    wire [2:0] funct3 = instr[14:12];
    wire [6:0] funct7 = instr[31:25];

    always @(*) begin
        reg_write = 1'b0;
        mem_write = 1'b0;
        alu_src = 1'b0;
        wb_sel = WB_ALU;
        alu_op = ALU_ADD;
        branch_op = BR_NONE;
        imm_type = IMM_NONE;
        uses_rs1 = 1'b0;
        uses_rs2 = 1'b0;
        illegal_instr = 1'b1;

        case (opcode)
            7'b0110011: begin
                case ({funct7, funct3})
                    {7'b0000000, 3'b000}: begin reg_write = 1'b1; alu_op = ALU_ADD; illegal_instr = 1'b0; end
                    {7'b0100000, 3'b000}: begin reg_write = 1'b1; alu_op = ALU_SUB; illegal_instr = 1'b0; end
                    {7'b0000000, 3'b100}: begin reg_write = 1'b1; alu_op = ALU_XOR; illegal_instr = 1'b0; end
                    {7'b0000000, 3'b110}: begin reg_write = 1'b1; alu_op = ALU_OR;  illegal_instr = 1'b0; end
                    {7'b0000000, 3'b111}: begin reg_write = 1'b1; alu_op = ALU_AND; illegal_instr = 1'b0; end
                endcase
                uses_rs1 = !illegal_instr;
                uses_rs2 = !illegal_instr;
            end

            7'b0010011: begin
                case (funct3)
                    3'b000: begin reg_write = 1'b1; alu_op = ALU_ADD; illegal_instr = 1'b0; end
                    3'b110: begin reg_write = 1'b1; alu_op = ALU_OR;  illegal_instr = 1'b0; end
                    3'b111: begin reg_write = 1'b1; alu_op = ALU_AND; illegal_instr = 1'b0; end
                endcase
                alu_src = !illegal_instr;
                imm_type = illegal_instr ? IMM_NONE : IMM_I;
                uses_rs1 = !illegal_instr;
            end

            7'b0110111: begin
                reg_write = 1'b1;
                wb_sel = WB_IMM;
                imm_type = IMM_U;
                illegal_instr = 1'b0;
            end

            7'b0000011: begin
                if (funct3 == 3'b010) begin
                    reg_write = 1'b1; alu_src = 1'b1; wb_sel = WB_MEM;
                    imm_type = IMM_I; alu_op = ALU_ADD; uses_rs1 = 1'b1; illegal_instr = 1'b0;
                end
            end

            7'b0100011: begin
                if (funct3 == 3'b010) begin
                    mem_write = 1'b1; alu_src = 1'b1; imm_type = IMM_S;
                    alu_op = ALU_ADD; uses_rs1 = 1'b1; uses_rs2 = 1'b1; illegal_instr = 1'b0;
                end
            end

            7'b1100011: begin
                imm_type = IMM_B;
                case (funct3)
                    3'b000: begin branch_op = BR_BEQ; illegal_instr = 1'b0; end
                    3'b001: begin branch_op = BR_BNE; illegal_instr = 1'b0; end
                    3'b100: begin branch_op = BR_BLT; illegal_instr = 1'b0; end
                    3'b101: begin branch_op = BR_BGE; illegal_instr = 1'b0; end
                endcase
                uses_rs1 = !illegal_instr;
                uses_rs2 = !illegal_instr;
            end

            7'b1101111: begin
                reg_write = 1'b1;
                wb_sel = WB_PC4;
                branch_op = BR_JAL;
                imm_type = IMM_J;
                illegal_instr = 1'b0;
            end
        endcase
    end
endmodule

module ALU(
    input [31:0] a,
    input [31:0] b,
    input [3:0] alu_op,
    output reg [31:0] y
);
    localparam ALU_ADD = 4'd0;
    localparam ALU_SUB = 4'd1;
    localparam ALU_OR  = 4'd2;
    localparam ALU_XOR = 4'd3;
    localparam ALU_AND = 4'd4;

    always @(*) begin
        case (alu_op)
            ALU_SUB: y = a - b;
            ALU_OR:  y = a | b;
            ALU_XOR: y = a ^ b;
            ALU_AND: y = a & b;
            default: y = a + b;
        endcase
    end
endmodule

module DataMemory(
    input clk,
    input we,
    input [31:0] addr,
    input [31:0] wdata,
    output [31:0] rdata
);
    reg [31:0] mem [0:255];

    initial begin
        $readmemh("data.mem", mem);
    end

    assign rdata = mem[addr[9:2]];

    always @(posedge clk) begin
        if (we) begin
            mem[addr[9:2]] <= wdata;
        end
    end
endmodule

module BranchUnit(
    input [31:0] pc,
    input [31:0] imm,
    input [31:0] rs1_data,
    input [31:0] rs2_data,
    input [2:0] branch_op,
    output [31:0] next_pc,
    output reg take_branch
);
    localparam BR_NONE = 3'd0;
    localparam BR_BEQ  = 3'd1;
    localparam BR_BNE  = 3'd2;
    localparam BR_BLT  = 3'd3;
    localparam BR_BGE  = 3'd4;
    localparam BR_JAL  = 3'd5;

    wire signed [31:0] s_rs1 = rs1_data;
    wire signed [31:0] s_rs2 = rs2_data;

    always @(*) begin
        case (branch_op)
            BR_BEQ: take_branch = (rs1_data == rs2_data);
            BR_BNE: take_branch = (rs1_data != rs2_data);
            BR_BLT: take_branch = (s_rs1 < s_rs2);
            BR_BGE: take_branch = (s_rs1 >= s_rs2);
            BR_JAL: take_branch = 1'b1;
            default: take_branch = 1'b0;
        endcase
    end

    assign next_pc = take_branch ? (pc + imm) : (pc + 32'd4);
endmodule

module Top(
    input clk,
    input rst
);
    wire [31:0] pc;
    wire [31:0] next_pc;
    wire [31:0] instr;
    wire [4:0] rd = instr[11:7];
    wire [4:0] rs1 = instr[19:15];
    wire [4:0] rs2 = instr[24:20];
    wire reg_write;
    wire mem_write;
    wire alu_src;
    wire [1:0] wb_sel;
    wire [3:0] alu_op;
    wire [2:0] branch_op;
    wire [2:0] imm_type;
    wire uses_rs1;
    wire uses_rs2;
    wire illegal_instr;
    wire [31:0] imm;
    wire [31:0] rs1_data;
    wire [31:0] rs2_data;
    wire [31:0] alu_b;
    wire [31:0] alu_y;
    wire [31:0] mem_rdata;
    wire [31:0] wb_data;
    wire take_branch;

    ProgramCounter pc_reg(
        .clk(clk),
        .rst(rst),
        .next_pc(next_pc),
        .pc(pc)
    );

    InstructionMemory instruction_memory(
        .addr(pc),
        .instr(instr)
    );

    ControlUnit control_unit(
        .instr(instr),
        .reg_write(reg_write),
        .mem_write(mem_write),
        .alu_src(alu_src),
        .wb_sel(wb_sel),
        .alu_op(alu_op),
        .branch_op(branch_op),
        .imm_type(imm_type),
        .uses_rs1(uses_rs1),
        .uses_rs2(uses_rs2),
        .illegal_instr(illegal_instr)
    );

    ImmediateGenerator immediate_generator(
        .instr(instr),
        .imm_type(imm_type),
        .imm(imm)
    );

    RegisterFile register_file(
        .clk(clk),
        .rst(rst),
        .we(reg_write),
        .raddr1(rs1),
        .raddr2(rs2),
        .waddr(rd),
        .wdata(wb_data),
        .rdata1(rs1_data),
        .rdata2(rs2_data)
    );

    assign alu_b = alu_src ? imm : rs2_data;

    ALU alu(
        .a(rs1_data),
        .b(alu_b),
        .alu_op(alu_op),
        .y(alu_y)
    );

    DataMemory data_memory(
        .clk(clk),
        .we(mem_write),
        .addr(alu_y),
        .wdata(rs2_data),
        .rdata(mem_rdata)
    );

    BranchUnit branch_unit(
        .pc(pc),
        .imm(imm),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data),
        .branch_op(branch_op),
        .next_pc(next_pc),
        .take_branch(take_branch)
    );

    assign wb_data = (wb_sel == 2'd1) ? mem_rdata :
                     (wb_sel == 2'd2) ? (pc + 32'd4) :
                     (wb_sel == 2'd3) ? imm :
                     alu_y;
endmodule
