`timescale 1ns/1ps
// ============================================================
// uart_mmio_tb.v — 冯丽嘉 M4 UART 测试台
//
// 用模拟 CPU 总线请求（valid/write/addr/wdata/rdata）测试
// system_env 里 UART 的完整寄存器与收发行为，不接真实 CPU。
//
// 场景：
//   S1 RAM 读写 + 溢出状态只读位
//   S2 TX 基本发送 0x55/0x00/0xFF（一次总线写只发一次）
//   S3 RX 基本接收 0x55/0x00/0xFF/'r'（STATUS bit1 + 读取消费）
//   S4 忙时再次写入（tx_error，只发第一个字节）
//   S5 错误停止位（frame_error，帧丢弃）
//   S6 未消费收到新字节（overrun，保留旧字节）
//   S7 同沿消费旧字节并收到新字节（保留新字节）
//   S8 错误位写 1 清除
//   S9 复位（STATUS 清零、TX 回高）
//   S10 未映射地址写不破坏 RAM
//   S11 假起始位恢复（短暂低电平被忽略）
//   S12 发送中途复位（TX 回高、状态清零、复位后正常发送）
//   S13 只读/未对齐地址写无副作用
//   S14 反复复位与重复命令
// ============================================================
module uart_mmio_tb;
    localparam BIT_CYCLES = 87;          // 10 MHz / 115200 baud
    reg clk = 0; always #50 clk = ~clk;  // 10 MHz
    reg resetn = 0;
    reg valid = 0, write = 0, uart_rx = 1;
    reg [31:0] addr = 0, wdata = 0, imem_addr = 0;
    wire [31:0] rdata, imem_rdata;
    wire uart_tx;
    reg overflow_flag = 0;

    system_env dut(
        .clk(clk), .resetn(resetn),
        .imem_addr(imem_addr), .imem_rdata(imem_rdata),
        .dmem_valid(valid), .dmem_write(write),
        .dmem_addr(addr), .dmem_wdata(wdata), .dmem_rdata(rdata),
        .overflow_flag(overflow_flag), .uart_rx(uart_rx), .uart_tx(uart_tx)
    );

    // 场景编号（供报错信息使用）与 RX 读取暂存
    integer scn = 0;
    reg [31:0] rx_val;

    // ---------------- 总线任务 ----------------
    task bus_wr(input [31:0] a, input [31:0] d);
        begin
            @(negedge clk); addr = a; wdata = d; valid = 1; write = 1;
            @(negedge clk); valid = 0; write = 0;
        end
    endtask

    task bus_check(input [31:0] a, input [31:0] exp, input [31:0] mask);
        begin
            @(negedge clk); addr = a; valid = 1; write = 0; #1;
            if ((rdata & mask) !== (exp & mask))
                $fatal(1, "S%0d READ %h expected %h actual %h", scn, a, exp, rdata);
            @(negedge clk); valid = 0;
        end
    endtask

    // 读 RX 地址（会消费该字节），返回读到的值
    task bus_read_rx(output [31:0] d);
        begin
            @(negedge clk); addr = 32'h40000008; valid = 1; write = 0; #1;
            d = rdata;
            @(negedge clk); valid = 0;
        end
    endtask

    // ---------------- 串口任务 ----------------
    // 模拟电脑向 UART 发送一个字节（起始位/8 数据位/停止位，每 BIT_CYCLES 一拍）
    task uart_send(input [7:0] b, input good_stop);
        integer j;
        begin
            @(negedge clk); uart_rx = 0;
            repeat (BIT_CYCLES) @(negedge clk);
            for (j = 0; j < 8; j = j + 1) begin
                uart_rx = b[j];
                repeat (BIT_CYCLES) @(negedge clk);
            end
            uart_rx = good_stop;
            repeat (BIT_CYCLES) @(negedge clk);
            uart_rx = 1;
            repeat (100) @(negedge clk);
        end
    endtask

    // 采样 TX 引脚还原一个字节，并与期望值核对
    task uart_recv_check(input [7:0] exp);
        integer j;
        reg [7:0] b;
        begin
            @(negedge uart_tx);
            #4350;                              // 到起始位中心 (BIT_CYCLES/2 * 100ns)
            if (uart_tx !== 0) $fatal(1, "S%0d TX START BIT", scn);
            for (j = 0; j < 8; j = j + 1) begin
                #8700;                          // BIT_CYCLES * 100ns
                b[j] = uart_tx;
            end
            #8700;
            if (uart_tx !== 1) $fatal(1, "S%0d TX STOP BIT", scn);
            if (b !== exp) $fatal(1, "S%0d TX expected %h actual %h", scn, exp, b);
        end
    endtask

    // 一次总线写 TX 地址 + 同时采样串口输出（验证一次写只发一次）
    task tx_once(input [7:0] b);
        begin
            fork
                bus_wr(32'h40000000, b);
                uart_recv_check(b);
            join
            // 帧结束后总线应回到空闲高电平，且之后一段时间内不再出现起始位
            @(negedge clk);
            if (uart_tx !== 1) $fatal(1, "S%0d TX 帧后未回高", scn);
            #20000;
            if (uart_tx !== 1) $fatal(1, "S%0d TX 出现多余字节", scn);
            repeat (100) @(negedge clk);
        end
    endtask

    // ---------------- 场景编号（用于报错信息） ----------------
    task scn_set(input integer n); begin scn = n; end endtask

    initial begin
        repeat (5) @(negedge clk); resetn = 1;
        repeat (2) @(negedge clk);

        // S1 RAM 读写 + 溢出状态只读位
        scn_set(1);
        bus_wr(0, 32'h12345678);
        bus_wr(32'h3fc, 32'hdeadbeef);
        bus_check(0, 32'h12345678, 32'hffffffff);
        bus_check(32'h3fc, 32'hdeadbeef, 32'hffffffff);
        overflow_flag = 1;
        bus_check(32'h4000000c, 1, 32'hffffffff);
        overflow_flag = 0;
        $display("S1_PASS ram_and_overflow_read");

        // S2 TX 基本发送
        scn_set(2);
        tx_once(8'h55);
        tx_once(8'h00);
        tx_once(8'hff);
        $display("S2_PASS tx_55_00_ff");

        // S3 RX 基本接收
        scn_set(3);
        uart_send(8'h55, 1); bus_check(32'h40000004, 2, 2);
        bus_read_rx(rx_val); if (rx_val[7:0] !== 8'h55) $fatal(1, "S3 RX 55 got %h", rx_val);
        bus_check(32'h40000004, 0, 2);
        uart_send(8'h00, 1); bus_read_rx(rx_val); if (rx_val[7:0] !== 8'h00) $fatal(1, "S3 RX 00");
        uart_send(8'hff, 1); bus_read_rx(rx_val); if (rx_val[7:0] !== 8'hff) $fatal(1, "S3 RX ff");
        uart_send("r", 1);   bus_check(32'h40000004, 2, 2);   // 先查状态：RX 有效
        bus_read_rx(rx_val); if (rx_val[7:0] !== "r") $fatal(1, "S3 RX r got %h", rx_val);
        bus_check(32'h40000004, 0, 6);                        // 消费后 bit1 清、无错误位
        $display("S3_PASS rx_55_00_ff_r");

        // S4 忙时再次写入：只发第一个字节，STATUS bit4 置位
        scn_set(4);
        fork
            begin bus_wr(32'h40000000, 8'h41); bus_wr(32'h40000000, 8'h42); end
            uart_recv_check(8'h41);
        join
        repeat (100) @(negedge clk);
        bus_check(32'h40000004, 16, 17);       // bit4=1，且 bit0 已不忙
        bus_wr(32'h40000004, 16);              // 写 1 清 bit4
        bus_check(32'h40000004, 0, 16);
        $display("S4_PASS busy_write_error_and_clear");

        // S5 错误停止位：帧丢弃，bit3 置位
        scn_set(5);
        uart_send(8'h55, 0);
        bus_check(32'h40000004, 8, 14);        // bit3=1
        bus_check(32'h40000008, 0, 255);       // 无有效数据
        bus_wr(32'h40000004, 8);               // 清 bit3
        bus_check(32'h40000004, 0, 14);
        $display("S5_PASS bad_stop_discard_and_clear");

        // S6 未消费收到新字节：overrun，保留旧字节
        scn_set(6);
        uart_send("r", 1);
        uart_send("s", 1);
        bus_check(32'h40000004, 6, 6);         // bit1=1 bit2=1
        bus_read_rx(rx_val);                   // 消费：应得到旧字节 'r'
        if (rx_val[7:0] !== "r") $fatal(1, "S6 保留旧字节失败 got %h", rx_val);
        bus_check(32'h40000008, 0, 255);       // 新字节被丢弃，无残留
        bus_wr(32'h40000004, 4);               // 清 bit2
        bus_check(32'h40000004, 0, 6);
        $display("S6_PASS overrun_keeps_old_byte");

        // S7 同沿消费旧字节并收到新字节：保留新字节
        scn_set(7);
        fork
            uart_send("n", 1);
            begin
                // 等到帧即将收完（rx_state==3 且计数值为 1），下一拍就是采样沿
                wait (dut.uart.rx_state == 3 && dut.uart.rx_count == 1);
                @(negedge clk);                // 计数到 0 的拍
                @(negedge clk);                // 该拍发起读取
                addr = 32'h40000008; valid = 1; write = 0;
                @(negedge clk); valid = 0;
            end
        join
        bus_check(32'h40000004, 2, 6);         // 先查状态：有效、无 overrun
        bus_read_rx(rx_val);                   // 消费：应得到同沿收到的新字节
        if (rx_val[7:0] !== "n") $fatal(1, "S7 新字节未保存 got %h", rx_val);
        bus_check(32'h40000004, 0, 6);         // 消费后无残留错误
        $display("S7_PASS same_edge_consume_and_receive");

        // S8 错误位批量写 1 清除
        scn_set(8);
        uart_send(8'h00, 0);                   // 制造帧错误
        bus_check(32'h40000004, 8, 8);
        bus_wr(32'h40000004, 8);
        bus_check(32'h40000004, 0, 8);         // 已清
        $display("S8_PASS error_bit_clear");

        // S9 复位：STATUS 清零、TX 回高
        scn_set(9);
        resetn = 0;
        repeat (3) @(negedge clk);
        resetn = 1;
        bus_check(32'h40000004, 0, 31);
        if (uart_tx !== 1) $fatal(1, "S9 TX NOT IDLE AFTER RESET");
        bus_check(32'h40000000, 0, 255);       // 读 TX 返回 0
        $display("S9_PASS reset");

        // S10 未映射地址写不破坏 RAM
        scn_set(10);
        bus_wr(0, 32'h0000abcd);
        bus_wr(32'h40000400, 32'hffffffff);    // 不属于 RAM 也不属于 UART
        bus_check(0, 32'h0000abcd, 32'hffffffff);
        $display("S10_PASS unmapped_write_no_side_effect");

        // S11 假起始位：短暂低电平应被忽略，不影响后续真实字节
        scn_set(11);
        @(negedge clk); uart_rx = 0;
        repeat (10) @(negedge clk);
        uart_rx = 1;
        repeat (60) @(negedge clk);
        bus_check(32'h40000004, 0, 2);         // 假起始位不产生 RX 数据
        uart_send(8'h55, 1);                   // 真实字节不受影响
        bus_check(32'h40000004, 2, 2);
        bus_read_rx(rx_val);
        if (rx_val[7:0] !== 8'h55) $fatal(1, "S11 假起始位后接收错误 got %h", rx_val);
        bus_check(32'h40000004, 0, 2);
        $display("S11_PASS false_start_recovery");

        // S12 发送中途复位：TX 立即回高、状态清零、复位后仍能正常发送
        scn_set(12);
        fork
            bus_wr(32'h40000000, 8'h5a);
            begin
                @(negedge uart_tx);            // 起始位出现，帧已开始
                repeat (20) @(negedge clk);    // 传了一半时复位
                resetn = 0;
                repeat (3) @(negedge clk);
                resetn = 1;
            end
        join
        repeat (50) @(negedge clk);
        if (uart_tx !== 1) $fatal(1, "S12 复位后 TX 未回高");
        bus_check(32'h40000004, 0, 31);        // 状态全部清零
        tx_once(8'h33);                        // 复位后仍能正常发送
        $display("S12_PASS reset_mid_transmission");

        // S13 只读地址与未对齐地址写无副作用
        scn_set(13);
        bus_wr(32'h4000000c, 32'hffffffff);    // 溢出只读地址写被忽略
        overflow_flag = 1;                     // 仍可正常读取
        bus_check(32'h4000000c, 1, 1);
        overflow_flag = 0;
        bus_check(32'h4000000c, 0, 1);
        bus_wr(2, 32'hffffffff);               // 未对齐写被忽略
        bus_wr(32'h3f8, 32'h0badcafe);         // 相邻 RAM 字不受影响
        bus_check(32'h3f8, 32'h0badcafe, 32'hffffffff);
        bus_check(0, 32'h0000abcd, 32'hffffffff);
        $display("S13_PASS readonly_and_misaligned_write");

        // S14 反复复位与重复命令
        scn_set(14);
        repeat (3) begin
            resetn = 0;
            repeat (3) @(negedge clk);
            resetn = 1;
            repeat (2) @(negedge clk);
            tx_once(8'h41);
        end
        $display("S14_PASS repeated_reset_and_command");

        $display("UART_MMIO_TB_PASS all=14");
        $finish;
    end

    initial begin
        #30000000;                             // 30 ms 看门狗
        $fatal(1, "UART_MMIO_TB_TIMEOUT");
    end
endmodule
