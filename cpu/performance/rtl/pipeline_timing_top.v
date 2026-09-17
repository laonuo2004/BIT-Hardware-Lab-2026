`timescale 1ns/1ps

// Timing-only wrapper that keeps instruction/data memories on chip and avoids
// exposing the CPU's wide memory interfaces as hundreds of package pins.
module PipelineTimingTop(
    input clk,
    input resetn,
    output [31:0] observe
);
    wire [31:0] imem_addr;
    wire [31:0] imem_rdata;
    wire dmem_valid;
    wire dmem_write;
    wire [31:0] dmem_addr;
    wire [31:0] dmem_wdata;
    wire [31:0] dmem_rdata;
    wire retire_valid;
    wire [31:0] retire_pc;
    wire retire_reg_write;
    wire [4:0] retire_rd;
    wire [31:0] retire_wdata;
    wire fault_valid;
    wire [31:0] fault_pc;
    wire [31:0] fault_addr;
    wire [1:0] fault_reason;
    wire overflow_flag;
    wire [31:0] branch_count;
    wire [31:0] mispredict_count;

    reg [31:0] imem [0:255];
    reg [31:0] dmem [0:255];
    initial begin
        $readmemh("text.mem", imem);
        $readmemh("data.mem", dmem);
    end

    assign imem_rdata = imem[imem_addr[9:2]];
    assign dmem_rdata = dmem[dmem_addr[9:2]];
    always @(posedge clk)
        if (resetn && dmem_valid && dmem_write)
            dmem[dmem_addr[9:2]] <= dmem_wdata;

    PipelineCPU dut(
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

    assign observe = retire_pc ^ retire_wdata ^ fault_pc ^ fault_addr ^
                     branch_count ^ mispredict_count ^ {25'b0, fault_reason,
                     retire_rd, retire_valid, retire_reg_write, fault_valid,
                     overflow_flag};
endmodule
