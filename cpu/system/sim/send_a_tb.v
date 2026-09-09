`timescale 1ns/1ps

module send_a_tb;
    localparam BIT_CYCLES = 8;
    reg clk = 0;
    reg resetn = 0;
    reg uart_rx = 1;
    wire uart_tx;
    wire retire_valid;
    wire [31:0] retire_pc;
    wire fault_valid;
    wire [31:0] fault_pc;
    wire [31:0] fault_addr;
    wire [1:0] fault_reason;
    wire overflow_flag;
    wire [31:0] branch_count;
    wire [31:0] mispredict_count;
    reg [7:0] received;
    integer bit_index;

    CpuSystem #(
        .ROM_WORDS(16),
        .ROM_FILE("send_a.mem"),
        .BIT_CYCLES(BIT_CYCLES)
    ) dut(
        .clk(clk),
        .resetn(resetn),
        .uart_rx(uart_rx),
        .uart_tx(uart_tx),
        .retire_valid(retire_valid),
        .retire_pc(retire_pc),
        .fault_valid(fault_valid),
        .fault_pc(fault_pc),
        .fault_addr(fault_addr),
        .fault_reason(fault_reason),
        .overflow_flag(overflow_flag),
        .branch_count(branch_count),
        .mispredict_count(mispredict_count)
    );

    always #5 clk = ~clk;

    initial begin
        repeat (4) @(posedge clk);
        resetn <= 1;
    end

    initial begin : timeout
        repeat (2000) @(posedge clk);
        $fatal(1, "SEND_A_TIMEOUT");
    end

    initial begin : receive_uart
        @(negedge uart_tx);
        repeat (BIT_CYCLES/2) @(posedge clk);
        if (uart_tx !== 0) $fatal(1, "UART_START_BIT");
        for (bit_index = 0; bit_index < 8; bit_index = bit_index + 1) begin
            repeat (BIT_CYCLES) @(posedge clk);
            received[bit_index] = uart_tx;
        end
        repeat (BIT_CYCLES) @(posedge clk);
        if (uart_tx !== 1) $fatal(1, "UART_STOP_BIT");
        if (received !== 8'h41) $fatal(1, "UART_DATA expected=41 actual=%h", received);
        if (fault_valid || overflow_flag) $fatal(1, "CPU_STATUS_UNEXPECTED");
        $display("CPU_SYSTEM_SEND_A_PASS data=%h", received);
        disable timeout;
        $finish;
    end
endmodule
