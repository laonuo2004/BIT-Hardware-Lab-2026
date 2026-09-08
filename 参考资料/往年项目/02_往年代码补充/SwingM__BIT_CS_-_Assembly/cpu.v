`timescale 1ns / 1ps

module mycpu (
    input         rstn,
    input         clk,

    output [31:0] inst_rom_addr,    // rom address, the base???
    input  [31:0] inst_rom_rdata,   // read rom data

    output [31:0] data_ram_addr,    // write address
    output [31:0] data_ram_wdata,   // write data
    output        data_ram_wen,     // write energy signal
    input  [31:0] data_ram_rdata    // read data
    );

    wire        pc_jmp;     // in: cu
    wire        pc_br;      // in: cu
    wire [15:0] pc_off;     // in: imem
    wire [25:0] pc_tgt;     // in: pc, imem
    wire [31:0] pc_val;     // out: imem
    pc _pc(
        .clk(clk),
        .rst(rstn),
        .pc_jmp(pc_jmp),
        .pc_br(pc_br),
        .pc_off(pc_off),
        .pc_tgt(pc_tgt),
        .pc_val(pc_val)
    );
    
    wire        reg_we;     // in: cu
    wire [4:0]  reg_ra1;    // in: imem
    wire [4:0]  reg_ra2;    // in: imem
    wire [4:0]  reg_wa;     // in: imem
    wire [31:0] reg_wd;     // in: imem
    wire [31:0] reg_rd1;    // out: alu
    wire [31:0] reg_rd2;    // out: alu
    regfile _regfile(
        .clk(clk),
        .rst(rstn),
        .reg_we(reg_we),
        .reg_ra1(reg_ra1),
        .reg_ra2(reg_ra2),
        .reg_wa(reg_wa),
        .reg_wd(reg_wd),
        .reg_rd1(reg_rd1),
        .reg_rd2(reg_rd2)
    );
    
    wire [3:0]  alu_op;     // in: cu
    
    wire [31:0] alu_in1;    // in: imem, reg
    wire [31:0] alu_in2;    // in: imem, reg
    wire [31:0] alu_out;    // out: dmem, reg
    wire        alu_zero;   // out: pc
    alu _alu(
        .alu_op(alu_op),
        .alu_in1(alu_in1),
        .alu_in2(alu_in2),
        .alu_out(alu_out),
        .alu_zero(alu_zero)
    );
    
    wire [31:0] instr;      // out: 
    assign inst_rom_addr = pc_val;
    assign instr = inst_rom_rdata;
    
    
    //assign data_ram_addr = alu_out;
    //assign data_ram_wdata = reg_rd2;
    //assign data_ram_wen = d_we;
    //assign d_rdata = data_ram_rdata;
    /******************************

    PUT THE DATALOADER HERE!

    *******************************/
    wire        d_we;       // in: dmem
    wire [31:0] d_rdata;    // out: reg
    wire [31:0] in_addr;  // input address wire
    wire [31:0] in_data;  // input WD
    Dataloader _Dataloader(
        .in_we(d_we),
        .in_address(in_addr),
        .in_wd(in_data),
        .out_1(d_rdata)
    );
    /******************************

    PUT THE DATALOADER HERE!

    *******************************/
    wire [5:0]  opcode;     // in: imem
    wire [5:0]  func;       // in: imem
    wire        cu_c1;      // out: alu
    wire        cu_c2;      // out: reg
    wire        cu_c3;      // out: alu
    wire        cu_c4;      // out: reg
    wire        cu_br;      // out: pc
    control _cu(
        .opcode(opcode),
        .func(func),
        .cu_c1(cu_c1),
        .cu_c2(cu_c2),
        .cu_c3(cu_c3),
        .cu_c4(cu_c4),
        .cu_cA(alu_op),
        .cu_jmp(pc_jmp),
        .cu_br(cu_br),
        .d_we(d_we),
        .reg_we(reg_we)
    );
    

    /*********************************************************************************

    Mux and data selection

    *********************************************************************************/

    wire [31:0] imm_e;      // immediate 32 bit extended signed
    assign opcode   = instr[31:26];
    assign func     = instr[5:0];
    assign imm_e    = {{16{instr[15]}}, instr[15:0]};
    
    assign pc_tgt   = instr[25:0];
    assign pc_off   = instr[15:0];
    assign pc_br    = (cu_br == 1'b1) && (reg_rd1 == reg_rd2);
    
    assign reg_ra1  = instr[25:21];
    assign reg_ra2  = instr[20:16];
    assign reg_wa   = (cu_c2 == 1) ? instr[15:11] : instr[20:16];
    assign reg_wd   = (cu_c4 == 1) ? d_rdata : alu_out;     // data saver mux
    
    assign alu_in1  = (cu_c3 == 1) ? imm_e : reg_rd1;
    assign alu_in2  = (cu_c1 == 1) ? imm_e : reg_rd2;
    
    assign in_addr = alu_out;
    assign in_data = reg_rd2;



endmodule
