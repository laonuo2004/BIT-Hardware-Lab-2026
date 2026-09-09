`timescale 1ns/1ps

// M6 第三步：冯丽嘉的应用汇编（排序 + UART 输出 + 收 'r' 重跑）系统集成测试。
// 预期串口输出两遍 "SORT: 1 2 3 4 5\r\n"：复位后一遍，收到 'r' 后一遍。
module sort_uart_tb;
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
    reg [7:0] expected [0:16];
    reg [7:0] received;
    integer byte_index;
    integer bit_index;

    CpuSystem #(
        .ROM_WORDS(128),
        .ROM_FILE("sort_uart.mem"),
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
        expected[0]  = "S";  // 0x53
        expected[1]  = "O";  // 0x4F
        expected[2]  = "R";  // 0x52
        expected[3]  = "T";  // 0x54
        expected[4]  = ":";  // 0x3A
        expected[5]  = " ";  // 0x20
        expected[6]  = "1";  // 0x31
        expected[7]  = " ";  // 0x20
        expected[8]  = "2";  // 0x32
        expected[9]  = " ";  // 0x20
        expected[10] = "3";  // 0x33
        expected[11] = " ";  // 0x20
        expected[12] = "4";  // 0x34
        expected[13] = " ";  // 0x20
        expected[14] = "5";  // 0x35
        expected[15] = 8'h0d; // CR
        expected[16] = 8'h0a; // LF
        repeat (4) @(posedge clk);
        resetn <= 1;
    end

    initial begin : timeout
        repeat (40000) @(posedge clk);
        $fatal(1, "SORT_UART_TIMEOUT");
    end

    // 串口接收一个字节并核对，失败立即报错
    task receive_check(input integer byte_no);
        integer b;
        begin
            @(negedge uart_tx);
            repeat (BIT_CYCLES/2) @(posedge clk);
            if (uart_tx !== 0) $fatal(1, "UART_START_BIT byte=%0d", byte_no);
            for (b = 0; b < 8; b = b + 1) begin
                repeat (BIT_CYCLES) @(posedge clk);
                received[b] = uart_tx;
            end
            repeat (BIT_CYCLES) @(posedge clk);
            if (uart_tx !== 1) $fatal(1, "UART_STOP_BIT byte=%0d", byte_no);
            if (received !== expected[byte_no])
                $fatal(1, "UART_DATA byte=%0d expected=%h actual=%h",
                    byte_no, expected[byte_no], received);
        end
    endtask

    // 模拟电脑向 UART 发送一个字节（时序对齐 uart_mmio 的采样）
    task send_char(input [7:0] b);
        integer j;
        begin
            @(negedge clk); uart_rx = 0; repeat (BIT_CYCLES) @(negedge clk);
            for (j = 0; j < 8; j = j + 1) begin
                uart_rx = b[j];
                repeat (BIT_CYCLES) @(negedge clk);
            end
            uart_rx = 1; repeat (BIT_CYCLES) @(negedge clk);
            uart_rx = 1; repeat (100) @(negedge clk);
        end
    endtask

    // 完整跑一遍：接收 17 字节并逐一核对
    task run_round(input integer round_no);
        integer k;
        begin
            for (k = 0; k < 17; k = k + 1) receive_check(k);
            $display("SORT_UART_ROUND%0d_OK", round_no);
        end
    endtask

    initial begin
        run_round(1);          // 复位后的第一遍
        send_char("r");        // 收到 'r' 应重新初始化并再输出一遍
        run_round(2);
        if (fault_valid || overflow_flag || dut.env.uart.tx_error
            || dut.env.uart.overrun || dut.env.uart.frame_error)
            $fatal(1, "CPU_OR_UART_STATUS_UNEXPECTED fault=%b of=%b txerr=%b",
                fault_valid, overflow_flag, dut.env.uart.tx_error);
        $display("SORT_UART_SYSTEM_PASS text=SORT_1_2_3_4_5_CRLF rounds=2");
        disable timeout;
        $finish;
    end
endmodule
