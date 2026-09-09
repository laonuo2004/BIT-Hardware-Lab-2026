`timescale 1ns/1ps
// CPU-side clock is already 10 MHz. Board clock/reset wrapper is separate.
module system_env #(parameter ROM_WORDS=1024,parameter ROM_FILE="",parameter BIT_CYCLES=87)(
 input clk,input resetn,input [31:0] imem_addr,output [31:0] imem_rdata,
 input dmem_valid,input dmem_write,input [31:0] dmem_addr,input [31:0] dmem_wdata,
 output reg [31:0] dmem_rdata,input overflow_flag,input uart_rx,output uart_tx
);
 reg [31:0] rom[0:ROM_WORDS-1];
 reg [31:0] ram[0:255];
 integer i;
 initial begin
  for(i=0;i<ROM_WORDS;i=i+1) rom[i]=32'h00000013;
  if(ROM_FILE!="") $readmemh(ROM_FILE,rom);
 end
 wire aligned=dmem_addr[1:0]==0;
 wire ram_sel=aligned && dmem_addr<32'h400;
 wire uart_sel=(dmem_addr==32'h40000000 || dmem_addr==32'h40000004 || dmem_addr==32'h40000008);
 wire [31:0] uart_data;
 assign imem_rdata=(imem_addr[1:0]==0 && imem_addr/4<ROM_WORDS)?rom[imem_addr/4]:32'h00000013;
 uart_mmio #(.BIT_CYCLES(BIT_CYCLES)) uart(
  .clk(clk),.resetn(resetn),.valid(resetn && dmem_valid && uart_sel),.write(dmem_write),
  .addr(dmem_addr[3:0]),.wdata(dmem_wdata),.rdata(uart_data),.rx(uart_rx),.tx(uart_tx));
 always @(posedge clk)
  if(resetn && dmem_valid && dmem_write && ram_sel) ram[dmem_addr[9:2]]<=dmem_wdata;
 always @* begin
  dmem_rdata=0;
  if(ram_sel) dmem_rdata=ram[dmem_addr[9:2]];
  else if(uart_sel) dmem_rdata=uart_data;
  else if(dmem_addr==32'h4000000c) dmem_rdata={31'b0,overflow_flag};
 end
endmodule
