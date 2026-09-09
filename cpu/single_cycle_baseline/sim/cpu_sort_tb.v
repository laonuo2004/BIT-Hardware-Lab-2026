`timescale 1ns / 1ps

module cpu_sort_tb;
    reg clk;
    reg rst;

    wire [31:0] pc = uut.pc;
    wire [31:0] next_pc = uut.next_pc;
    wire [31:0] instr = uut.instr;
    wire reg_write = uut.reg_write;
    wire mem_write = uut.mem_write;
    wire [31:0] alu_y = uut.alu_y;
    wire [31:0] mem0 = uut.data_memory.mem[0];
    wire [31:0] mem1 = uut.data_memory.mem[1];
    wire [31:0] mem2 = uut.data_memory.mem[2];
    wire [31:0] mem3 = uut.data_memory.mem[3];
    wire [31:0] mem4 = uut.data_memory.mem[4];

    Top uut(
        .clk(clk),
        .rst(rst)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        rst = 1'b0;
        #12 rst = 1'b1;
    end

    initial begin
        $dumpfile("cpu_sort_tb.vcd");
        $dumpvars(0, cpu_sort_tb);

        #1200;
        $display("sorted_data=%0d,%0d,%0d,%0d,%0d",
                 uut.data_memory.mem[0],
                 uut.data_memory.mem[1],
                 uut.data_memory.mem[2],
                 uut.data_memory.mem[3],
                 uut.data_memory.mem[4]);
        if (uut.data_memory.mem[0] == 32'd1 &&
            uut.data_memory.mem[1] == 32'd2 &&
            uut.data_memory.mem[2] == 32'd3 &&
            uut.data_memory.mem[3] == 32'd4 &&
            uut.data_memory.mem[4] == 32'd5) begin
            $display("SORT_PASS");
        end else begin
            $display("SORT_FAIL");
        end
        $finish;
    end
endmodule
