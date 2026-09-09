`timescale 1ns/1ps

module send_string_tb;
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
    reg [7:0] expected [0:8];
    reg [7:0] received;
    integer byte_index;
    integer bit_index;

    CpuSystem #(
        .ROM_WORDS(64),
        .ROM_FILE("send_string.mem"),
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
        expected[0] = "U";
        expected[1] = "A";
        expected[2] = "R";
        expected[3] = "T";
        expected[4] = "_";
        expected[5] = "O";
        expected[6] = "K";
        expected[7] = 8'h0d;
        expected[8] = 8'h0a;
        repeat (4) @(posedge clk);
        resetn <= 1;
    end

    initial begin : timeout
        repeat (20000) @(posedge clk);
        $fatal(1, "SEND_STRING_TIMEOUT");
    end

    initial begin : receive_uart
        for (byte_index = 0; byte_index < 9; byte_index = byte_index + 1) begin
            @(negedge uart_tx);
            repeat (BIT_CYCLES/2) @(posedge clk);
            if (uart_tx !== 0) $fatal(1, "UART_START_BIT byte=%0d", byte_index);
            for (bit_index = 0; bit_index < 8; bit_index = bit_index + 1) begin
                repeat (BIT_CYCLES) @(posedge clk);
                received[bit_index] = uart_tx;
            end
            repeat (BIT_CYCLES) @(posedge clk);
            if (uart_tx !== 1) $fatal(1, "UART_STOP_BIT byte=%0d", byte_index);
            if (received !== expected[byte_index])
                $fatal(1, "UART_DATA byte=%0d expected=%h actual=%h",
                    byte_index, expected[byte_index], received);
        end
        if (fault_valid || overflow_flag || dut.env.uart.tx_error)
            $fatal(1, "CPU_OR_UART_STATUS_UNEXPECTED");
        $display("CPU_SYSTEM_STRING_PASS text=UART_OK_CRLF");
        disable timeout;
        $finish;
    end
endmodule
