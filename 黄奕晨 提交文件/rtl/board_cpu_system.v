`timescale 1ns/1ps
// EES-338 full-system wrap: 100 MHz -> 10 MHz, then Liu CpuSystem + Huang system_env.
// Does not change UART RTL or CPU internals. ROM is Feng's sort_uart.mem.
module board_cpu_system(
 input clk_100m,
 input resetn,
 input uart_rx,
 output uart_tx,
 output led0
);
 wire clk_10m;
 wire locked;
 clk_wiz_0 u_clk(
  .clk_in1(clk_100m),
  .resetn(resetn),
  .clk_out1(clk_10m),
  .locked(locked)
 );
 wire rst_n=resetn & locked;
 wire retire_valid;
 wire [31:0] retire_pc;
 wire fault_valid;
 wire [31:0] fault_pc;
 wire [31:0] fault_addr;
 wire [1:0] fault_reason;
 wire overflow_flag;
 wire [31:0] branch_count;
 wire [31:0] mispredict_count;

 CpuSystem #(
  .ROM_WORDS(1024),
  .ROM_FILE("C:/Users/34556/Desktop/bgroup/b_group/programs/sort_uart.mem"),
  .BIT_CYCLES(87),
  .PREDICT_EN(1)
 ) u_sys(
  .clk(clk_10m),
  .resetn(rst_n),
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

 // Heartbeat on 10 MHz. Solid ON means the CPU latched a memory fault.
 reg [23:0] led_count=0;
 always @(posedge clk_10m) begin
  if(!rst_n) led_count<=0;
  else led_count<=led_count+1'b1;
 end
 assign led0=fault_valid?1'b1:led_count[23];
endmodule
