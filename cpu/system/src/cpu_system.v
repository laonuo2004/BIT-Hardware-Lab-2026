`timescale 1ns/1ps

module CpuSystem #(
    parameter ROM_WORDS = 1024,
    parameter ROM_FILE = "",
    parameter BIT_CYCLES = 87,
    parameter PREDICT_EN = 1
)(
    input clk,
    input resetn,
    input uart_rx,
    output uart_tx,
    output retire_valid,
    output [31:0] retire_pc,
    output fault_valid,
    output [31:0] fault_pc,
    output [31:0] fault_addr,
    output [1:0] fault_reason,
    output overflow_flag,
    output [31:0] branch_count,
    output [31:0] mispredict_count
);
    wire [31:0] imem_addr;
    wire [31:0] imem_rdata;
    wire dmem_valid;
    wire dmem_write;
    wire [31:0] dmem_addr;
    wire [31:0] dmem_wdata;
    wire [31:0] dmem_rdata;
    wire retire_reg_write;
    wire [4:0] retire_rd;
    wire [31:0] retire_wdata;

    PipelineCPU #(.PREDICT_EN(PREDICT_EN)) cpu(
        .clk(clk),
        .resetn(resetn),
        .imem_addr(imem_addr),
        .imem_rdata(imem_rdata),
        .dmem_valid(dmem_valid),
        .dmem_write(dmem_write),
        .dmem_addr(dmem_addr),
        .dmem_wdata(dmem_wdata),
        .dmem_rdata(dmem_rdata),
        .retire_valid(retire_valid),
        .retire_pc(retire_pc),
        .retire_reg_write(retire_reg_write),
        .retire_rd(retire_rd),
        .retire_wdata(retire_wdata),
        .fault_valid(fault_valid),
        .fault_pc(fault_pc),
        .fault_addr(fault_addr),
        .fault_reason(fault_reason),
        .overflow_flag(overflow_flag),
        .branch_count(branch_count),
        .mispredict_count(mispredict_count)
    );

    system_env #(
        .ROM_WORDS(ROM_WORDS),
        .ROM_FILE(ROM_FILE),
        .BIT_CYCLES(BIT_CYCLES)
    ) env(
        .clk(clk),
        .resetn(resetn),
        .imem_addr(imem_addr),
        .imem_rdata(imem_rdata),
        .dmem_valid(dmem_valid),
        .dmem_write(dmem_write),
        .dmem_addr(dmem_addr),
        .dmem_wdata(dmem_wdata),
        .dmem_rdata(dmem_rdata),
        .overflow_flag(overflow_flag),
        .uart_rx(uart_rx),
        .uart_tx(uart_tx)
    );
endmodule
