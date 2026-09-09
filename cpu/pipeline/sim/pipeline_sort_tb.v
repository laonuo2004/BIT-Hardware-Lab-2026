`timescale 1ns/1ps
module pipeline_sort_tb;
 reg clk=0,resetn=0; reg [31:0] imem[0:255],dmem[0:255]; integer i,cycles=0,retired=0;
 wire [31:0] ia,da,dw; wire [31:0] ir=imem[ia[9:2]],dr=dmem[da[9:2]]; wire dv,dwe,rv,rwe; wire [31:0] rpc,rwd; wire [4:0] rrd;
 PipelineCPU dut(clk,resetn,ia,ir,dv,dwe,da,dw,dr,rv,rpc,rwe,rrd,rwd);
 always #5 clk=~clk;
 always @(posedge clk) begin if(resetn) begin cycles<=cycles+1;if(dwe)dmem[da[9:2]]<=dw;if(rv)retired<=retired+1;end end
 initial begin for(i=0;i<256;i=i+1)begin imem[i]=0;dmem[i]=0;end $readmemh("text.mem",imem);$readmemh("data.mem",dmem);#12 resetn=1;
   wait(dmem[0]==1&&dmem[1]==2&&dmem[2]==3&&dmem[3]==4&&dmem[4]==5); #20;
   $display("PIPE_SORT_DATA=%0d,%0d,%0d,%0d,%0d cycles=%0d retired=%0d",dmem[0],dmem[1],dmem[2],dmem[3],dmem[4],cycles,retired);
   $display("PIPE_SORT_PASS");$finish;end
 initial begin #20000;$display("PIPE_SORT_TIMEOUT");$finish;end
endmodule
