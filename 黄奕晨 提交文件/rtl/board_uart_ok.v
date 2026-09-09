`timescale 1ns/1ps
// EES-338 UART_OK demo. Reuses uart_mmio; does not change UART RTL.
module board_uart_ok(input clk_100m,input resetn,input uart_rx,output uart_tx,output led0);
 wire clk_10m;
 wire locked;
 clk_wiz_0 u_clk(
  .clk_in1(clk_100m),
  .resetn(resetn),
  .clk_out1(clk_10m),
  .locked(locked)
 );
 wire rst_n=resetn & locked;
 reg [23:0] led_count=0;
 always @(posedge clk_10m) begin
  if(!rst_n) led_count<=0;
  else led_count<=led_count+1'b1;
 end
 assign led0=led_count[23];

 reg valid,write;
 reg [3:0] addr;
 reg [31:0] wdata;
 wire [31:0] rdata;
 uart_mmio #(.BIT_CYCLES(87)) u_uart(
  .clk(clk_10m),.resetn(rst_n),.valid(valid),.write(write),.addr(addr),
  .wdata(wdata),.rdata(rdata),.rx(uart_rx),.tx(uart_tx)
 );
 wire busy=rdata[0];

 reg [1:0] st;
 reg [3:0] idx;
 reg [23:0] gap;
 localparam ST_GAP=0,ST_ISSUE=1,ST_ARM=2,ST_DRAIN=3;
 function [7:0] msg_byte;
  input [3:0] i;
  begin
   case(i)
    0: msg_byte="U";
    1: msg_byte="A";
    2: msg_byte="R";
    3: msg_byte="T";
    4: msg_byte="_";
    5: msg_byte="O";
    6: msg_byte="K";
    7: msg_byte=8'h0D;
    default: msg_byte=8'h0A;
   endcase
  end
 endfunction

 always @(posedge clk_10m) begin
  valid<=0;
  write<=0;
  addr<=4;
  wdata<=0;
  if(!rst_n) begin
   st<=ST_GAP;
   idx<=0;
   gap<=0;
  end else begin
   case(st)
    ST_GAP: begin
     if(gap==24'd10_000_000) begin
      gap<=0;
      idx<=0;
      st<=ST_ISSUE;
     end else gap<=gap+1'b1;
    end
    ST_ISSUE: begin
     if(!busy) begin
      addr<=0;
      valid<=1;
      write<=1;
      wdata<={24'b0,msg_byte(idx)};
      st<=ST_ARM;
     end
    end
    ST_ARM: begin
     addr<=4;
     if(busy) st<=ST_DRAIN;
    end
    ST_DRAIN: begin
     addr<=4;
     if(!busy) begin
      if(idx==8) st<=ST_GAP;
      else begin
       idx<=idx+1'b1;
       st<=ST_ISSUE;
      end
     end
    end
   endcase
  end
 end
endmodule
