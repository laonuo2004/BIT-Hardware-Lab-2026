`timescale 1ns/1ps

// Interactive sort menu: boot menu, commands 1/2/3/4/r, unknown, ignore CR/LF.
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
    reg [7:0] cur [0:127];
    integer n;
    integer i;
    reg [7:0] received;

    CpuSystem #(
        .ROM_WORDS(1024),
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
        repeat (4) @(posedge clk);
        resetn <= 1;
    end

    initial begin : timeout
        repeat (2000000) @(posedge clk);
        $fatal(1, "SORT_UART_TIMEOUT");
    end

    task receive_check_byte(input [7:0] expb);
        integer b;
        begin
            @(negedge uart_tx);
            repeat (BIT_CYCLES/2) @(posedge clk);
            if (uart_tx !== 0) $fatal(1, "UART_START_BIT exp=%h", expb);
            for (b = 0; b < 8; b = b + 1) begin
                repeat (BIT_CYCLES) @(posedge clk);
                received[b] = uart_tx;
            end
            repeat (BIT_CYCLES) @(posedge clk);
            if (uart_tx !== 1) $fatal(1, "UART_STOP_BIT exp=%h", expb);
            if (received !== expb)
                $fatal(1, "UART_DATA expected=%h actual=%h", expb, received);
        end
    endtask

    task recv_cur;
        begin
            for (i = 0; i < n; i = i + 1)
                receive_check_byte(cur[i]);
        end
    endtask

    task send_char(input [7:0] b);
        integer j;
        begin
            @(negedge clk); uart_rx = 0; repeat (BIT_CYCLES) @(negedge clk);
            for (j = 0; j < 8; j = j + 1) begin
                uart_rx = b[j];
                repeat (BIT_CYCLES) @(negedge clk);
            end
            uart_rx = 1; repeat (BIT_CYCLES) @(negedge clk);
        end
    endtask

    task send_and_recv(input [7:0] b);
        begin
            fork
                send_char(b);
                recv_cur;
            join
        end
    endtask

    task load_menu;
        begin
            n = 87;
            cur[0] = "B";
            cur[1] = "I";
            cur[2] = "T";
            cur[3] = " ";
            cur[4] = "C";
            cur[5] = "P";
            cur[6] = "U";
            cur[7] = " ";
            cur[8] = "+";
            cur[9] = " ";
            cur[10] = "U";
            cur[11] = "A";
            cur[12] = "R";
            cur[13] = "T";
            cur[14] = " ";
            cur[15] = "D";
            cur[16] = "E";
            cur[17] = "M";
            cur[18] = "O";
            cur[19] = 8'h0d;
            cur[20] = 8'h0a;
            cur[21] = "1";
            cur[22] = " ";
            cur[23] = "-";
            cur[24] = " ";
            cur[25] = "S";
            cur[26] = "O";
            cur[27] = "R";
            cur[28] = "T";
            cur[29] = "E";
            cur[30] = "D";
            cur[31] = 8'h0d;
            cur[32] = 8'h0a;
            cur[33] = "2";
            cur[34] = " ";
            cur[35] = "-";
            cur[36] = " ";
            cur[37] = "R";
            cur[38] = "E";
            cur[39] = "V";
            cur[40] = "E";
            cur[41] = "R";
            cur[42] = "S";
            cur[43] = "E";
            cur[44] = 8'h0d;
            cur[45] = 8'h0a;
            cur[46] = "3";
            cur[47] = " ";
            cur[48] = "-";
            cur[49] = " ";
            cur[50] = "D";
            cur[51] = "U";
            cur[52] = "P";
            cur[53] = "L";
            cur[54] = "I";
            cur[55] = "C";
            cur[56] = "A";
            cur[57] = "T";
            cur[58] = "E";
            cur[59] = "S";
            cur[60] = 8'h0d;
            cur[61] = 8'h0a;
            cur[62] = "4";
            cur[63] = " ";
            cur[64] = "-";
            cur[65] = " ";
            cur[66] = "R";
            cur[67] = "A";
            cur[68] = "N";
            cur[69] = "D";
            cur[70] = "O";
            cur[71] = "M";
            cur[72] = 8'h0d;
            cur[73] = 8'h0a;
            cur[74] = "r";
            cur[75] = " ";
            cur[76] = "-";
            cur[77] = " ";
            cur[78] = "R";
            cur[79] = "E";
            cur[80] = "P";
            cur[81] = "E";
            cur[82] = "A";
            cur[83] = "T";
            cur[84] = 8'h0d;
            cur[85] = 8'h0a;
            cur[86] = ">";
        end
    endtask

    task load_c2;
        begin
            n = 58;
            cur[0] = 8'h0d;
            cur[1] = 8'h0a;
            cur[2] = "C";
            cur[3] = "A";
            cur[4] = "S";
            cur[5] = "E";
            cur[6] = " ";
            cur[7] = "2";
            cur[8] = ":";
            cur[9] = " ";
            cur[10] = "R";
            cur[11] = "E";
            cur[12] = "V";
            cur[13] = "E";
            cur[14] = "R";
            cur[15] = "S";
            cur[16] = "E";
            cur[17] = 8'h0d;
            cur[18] = 8'h0a;
            cur[19] = "I";
            cur[20] = "N";
            cur[21] = " ";
            cur[22] = ":";
            cur[23] = " ";
            cur[24] = "5";
            cur[25] = " ";
            cur[26] = "4";
            cur[27] = " ";
            cur[28] = "3";
            cur[29] = " ";
            cur[30] = "2";
            cur[31] = " ";
            cur[32] = "1";
            cur[33] = 8'h0d;
            cur[34] = 8'h0a;
            cur[35] = "O";
            cur[36] = "U";
            cur[37] = "T";
            cur[38] = ":";
            cur[39] = " ";
            cur[40] = "1";
            cur[41] = " ";
            cur[42] = "2";
            cur[43] = " ";
            cur[44] = "3";
            cur[45] = " ";
            cur[46] = "4";
            cur[47] = " ";
            cur[48] = "5";
            cur[49] = 8'h0d;
            cur[50] = 8'h0a;
            cur[51] = "P";
            cur[52] = "A";
            cur[53] = "S";
            cur[54] = "S";
            cur[55] = 8'h0d;
            cur[56] = 8'h0a;
            cur[57] = ">";
        end
    endtask

    task load_c1;
        begin
            n = 57;
            cur[0] = 8'h0d;
            cur[1] = 8'h0a;
            cur[2] = "C";
            cur[3] = "A";
            cur[4] = "S";
            cur[5] = "E";
            cur[6] = " ";
            cur[7] = "1";
            cur[8] = ":";
            cur[9] = " ";
            cur[10] = "S";
            cur[11] = "O";
            cur[12] = "R";
            cur[13] = "T";
            cur[14] = "E";
            cur[15] = "D";
            cur[16] = 8'h0d;
            cur[17] = 8'h0a;
            cur[18] = "I";
            cur[19] = "N";
            cur[20] = " ";
            cur[21] = ":";
            cur[22] = " ";
            cur[23] = "1";
            cur[24] = " ";
            cur[25] = "2";
            cur[26] = " ";
            cur[27] = "3";
            cur[28] = " ";
            cur[29] = "4";
            cur[30] = " ";
            cur[31] = "5";
            cur[32] = 8'h0d;
            cur[33] = 8'h0a;
            cur[34] = "O";
            cur[35] = "U";
            cur[36] = "T";
            cur[37] = ":";
            cur[38] = " ";
            cur[39] = "1";
            cur[40] = " ";
            cur[41] = "2";
            cur[42] = " ";
            cur[43] = "3";
            cur[44] = " ";
            cur[45] = "4";
            cur[46] = " ";
            cur[47] = "5";
            cur[48] = 8'h0d;
            cur[49] = 8'h0a;
            cur[50] = "P";
            cur[51] = "A";
            cur[52] = "S";
            cur[53] = "S";
            cur[54] = 8'h0d;
            cur[55] = 8'h0a;
            cur[56] = ">";
        end
    endtask

    task load_c3;
        begin
            n = 61;
            cur[0] = 8'h0d;
            cur[1] = 8'h0a;
            cur[2] = "C";
            cur[3] = "A";
            cur[4] = "S";
            cur[5] = "E";
            cur[6] = " ";
            cur[7] = "3";
            cur[8] = ":";
            cur[9] = " ";
            cur[10] = "D";
            cur[11] = "U";
            cur[12] = "P";
            cur[13] = "L";
            cur[14] = "I";
            cur[15] = "C";
            cur[16] = "A";
            cur[17] = "T";
            cur[18] = "E";
            cur[19] = "S";
            cur[20] = 8'h0d;
            cur[21] = 8'h0a;
            cur[22] = "I";
            cur[23] = "N";
            cur[24] = " ";
            cur[25] = ":";
            cur[26] = " ";
            cur[27] = "3";
            cur[28] = " ";
            cur[29] = "1";
            cur[30] = " ";
            cur[31] = "3";
            cur[32] = " ";
            cur[33] = "2";
            cur[34] = " ";
            cur[35] = "1";
            cur[36] = 8'h0d;
            cur[37] = 8'h0a;
            cur[38] = "O";
            cur[39] = "U";
            cur[40] = "T";
            cur[41] = ":";
            cur[42] = " ";
            cur[43] = "1";
            cur[44] = " ";
            cur[45] = "1";
            cur[46] = " ";
            cur[47] = "2";
            cur[48] = " ";
            cur[49] = "3";
            cur[50] = " ";
            cur[51] = "3";
            cur[52] = 8'h0d;
            cur[53] = 8'h0a;
            cur[54] = "P";
            cur[55] = "A";
            cur[56] = "S";
            cur[57] = "S";
            cur[58] = 8'h0d;
            cur[59] = 8'h0a;
            cur[60] = ">";
        end
    endtask

    task load_c4;
        begin
            n = 57;
            cur[0] = 8'h0d;
            cur[1] = 8'h0a;
            cur[2] = "C";
            cur[3] = "A";
            cur[4] = "S";
            cur[5] = "E";
            cur[6] = " ";
            cur[7] = "4";
            cur[8] = ":";
            cur[9] = " ";
            cur[10] = "R";
            cur[11] = "A";
            cur[12] = "N";
            cur[13] = "D";
            cur[14] = "O";
            cur[15] = "M";
            cur[16] = 8'h0d;
            cur[17] = 8'h0a;
            cur[18] = "I";
            cur[19] = "N";
            cur[20] = " ";
            cur[21] = ":";
            cur[22] = " ";
            cur[23] = "4";
            cur[24] = " ";
            cur[25] = "2";
            cur[26] = " ";
            cur[27] = "5";
            cur[28] = " ";
            cur[29] = "1";
            cur[30] = " ";
            cur[31] = "3";
            cur[32] = 8'h0d;
            cur[33] = 8'h0a;
            cur[34] = "O";
            cur[35] = "U";
            cur[36] = "T";
            cur[37] = ":";
            cur[38] = " ";
            cur[39] = "1";
            cur[40] = " ";
            cur[41] = "2";
            cur[42] = " ";
            cur[43] = "3";
            cur[44] = " ";
            cur[45] = "4";
            cur[46] = " ";
            cur[47] = "5";
            cur[48] = 8'h0d;
            cur[49] = 8'h0a;
            cur[50] = "P";
            cur[51] = "A";
            cur[52] = "S";
            cur[53] = "S";
            cur[54] = 8'h0d;
            cur[55] = 8'h0a;
            cur[56] = ">";
        end
    endtask

    task load_unk;
        begin
            n = 20;
            cur[0] = 8'h0d;
            cur[1] = 8'h0a;
            cur[2] = "U";
            cur[3] = "N";
            cur[4] = "K";
            cur[5] = "N";
            cur[6] = "O";
            cur[7] = "W";
            cur[8] = "N";
            cur[9] = " ";
            cur[10] = "C";
            cur[11] = "O";
            cur[12] = "M";
            cur[13] = "M";
            cur[14] = "A";
            cur[15] = "N";
            cur[16] = "D";
            cur[17] = 8'h0d;
            cur[18] = 8'h0a;
            cur[19] = ">";
        end
    endtask

    initial begin
        load_menu;
        recv_cur;
        $display("SORT_UART_MENU_OK");

        load_c2;
        send_and_recv("2");
        $display("SORT_UART_CMD2_OK");

        load_c2;
        send_and_recv("r");
        $display("SORT_UART_CMDR_OK");

        load_c1;
        send_and_recv("1");
        $display("SORT_UART_CMD1_OK");

        load_c3;
        send_and_recv("3");
        $display("SORT_UART_CMD3_OK");

        load_c4;
        send_and_recv("4");
        $display("SORT_UART_CMD4_OK");

        send_char(8'h0d);
        send_char(8'h0a);
        load_unk;
        send_and_recv("x");
        $display("SORT_UART_UNK_OK");

        if (fault_valid || overflow_flag || dut.env.uart.tx_error
            || dut.env.uart.overrun || dut.env.uart.frame_error)
            $fatal(1, "CPU_OR_UART_STATUS_UNEXPECTED fault=%b of=%b txerr=%b",
                fault_valid, overflow_flag, dut.env.uart.tx_error);
        $display("SORT_UART_SYSTEM_PASS text=MENU_CASES_1_2_3_4_R_UNK commands=7");
        disable timeout;
        $finish;
    end
endmodule
