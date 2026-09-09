`timescale 1ns/1ps
module uart_mmio #(parameter BIT_CYCLES=87)(
 input clk,input resetn,input valid,input write,input [3:0] addr,
 input [31:0] wdata,output reg [31:0] rdata,input rx,output reg tx
);
 reg [9:0] tx_frame;
 reg [3:0] tx_bit;
 integer tx_count;
 reg busy;
 reg rx_meta,rx_sync;
 reg [1:0] rx_state;
 integer rx_count;
 reg [2:0] rx_bit;
 reg [7:0] rx_shift,rx_data;
 reg rx_valid,overrun,frame_error,tx_error;
 wire consume=valid && !write && addr==8;
 wire clear_status=valid && write && addr==4;
 always @* begin
  rdata=0;
  case(addr)
   4: rdata={27'b0,tx_error,frame_error,overrun,rx_valid,busy};
   8: rdata=rx_valid?{24'b0,rx_data}:0;
  endcase
 end
 always @(posedge clk) begin
  if(!resetn) begin
   tx<=1; busy<=0; tx_frame<=10'h3ff; tx_bit<=0; tx_count<=0;
   rx_meta<=1; rx_sync<=1; rx_state<=0; rx_count<=0; rx_bit<=0;
   rx_shift<=0; rx_data<=0; rx_valid<=0; overrun<=0; frame_error<=0; tx_error<=0;
  end else begin
   rx_meta<=rx; rx_sync<=rx_meta;
   if(clear_status) begin
    if(wdata[2]) overrun<=0;
    if(wdata[3]) frame_error<=0;
    if(wdata[4]) tx_error<=0;
   end
   if(consume) rx_valid<=0;
   if(valid && write && addr==0) begin
    if(busy) tx_error<=1;
    else begin
     tx_frame<={1'b1,wdata[7:0],1'b0}; tx<=0;
     busy<=1; tx_bit<=0; tx_count<=BIT_CYCLES-1;
    end
   end
   if(busy) begin
    if(tx_count==0) begin
     if(tx_bit==9) begin busy<=0; tx<=1; end
     else begin tx_bit<=tx_bit+1; tx<=tx_frame[tx_bit+1]; tx_count<=BIT_CYCLES-1; end
    end else tx_count<=tx_count-1;
   end
   case(rx_state)
    0: if(!rx_sync) begin rx_state<=1; rx_count<=BIT_CYCLES/2-1; end
    1: if(rx_count!=0) rx_count<=rx_count-1;
       else if(rx_sync) rx_state<=0;
       else begin rx_state<=2; rx_count<=BIT_CYCLES-1; rx_bit<=0; end
    2: if(rx_count!=0) rx_count<=rx_count-1;
       else begin
        rx_shift[rx_bit]<=rx_sync; rx_count<=BIT_CYCLES-1;
        if(rx_bit==7) rx_state<=3; else rx_bit<=rx_bit+1;
       end
    3: if(rx_count!=0) rx_count<=rx_count-1;
       else begin
        rx_state<=0;
        if(!rx_sync) frame_error<=1;
        else if(rx_valid && !consume) overrun<=1;
        else begin rx_data<=rx_shift; rx_valid<=1; end
       end
   endcase
  end
 end
endmodule
