#!/usr/bin/env python3
# -*- coding: utf-8 -*-
from pathlib import Path

MENU = (
    "BIT CPU + UART DEMO\r\n"
    "1 - SORTED\r\n"
    "2 - REVERSE\r\n"
    "3 - DUPLICATES\r\n"
    "4 - RANDOM\r\n"
    "r - REPEAT\r\n"
    ">"
).encode("ascii")


def case_text(num, name, inn, out):
    return (
        f"\r\nCASE {num}: {name}\r\n"
        f"IN : {inn}\r\n"
        f"OUT: {out}\r\n"
        f"PASS\r\n>"
    ).encode("ascii")


C2 = case_text(2, "REVERSE", "5 4 3 2 1", "1 2 3 4 5")
C1 = case_text(1, "SORTED", "1 2 3 4 5", "1 2 3 4 5")
C3 = case_text(3, "DUPLICATES", "3 1 3 2 1", "1 1 2 3 3")
C4 = case_text(4, "RANDOM", "4 2 5 1 3", "1 2 3 4 5")
UNK = b"\r\nUNKNOWN COMMAND\r\n>"


def load_task(name, data):
    lines = [f"    task load_{name};", "        begin"]
    lines.append(f"            n = {len(data)};")
    for i, c in enumerate(data):
        if 32 <= c < 127 and c not in (34, 92):
            lit = f'"{chr(c)}"'
        else:
            lit = f"8'h{c:02x}"
        lines.append(f"            cur[{i}] = {lit};")
    lines.append("        end")
    lines.append("    endtask")
    return "\n".join(lines)


tb = f'''`timescale 1ns/1ps

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

{load_task("menu", MENU)}

{load_task("c2", C2)}

{load_task("c1", C1)}

{load_task("c3", C3)}

{load_task("c4", C4)}

{load_task("unk", UNK)}

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
'''

out = Path(__file__).with_name("sort_uart_tb.v")
out.write_text(tb, encoding="utf-8", newline="\n")
print("wrote", out, "menu", len(MENU), "c2", len(C2), "unk", len(UNK))
