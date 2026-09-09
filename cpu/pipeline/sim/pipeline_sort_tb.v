`timescale 1ns/1ps
module pipeline_sort_tb;
 parameter PREDICT_EN=1;
 reg clk=0,resetn=0; reg [31:0] imem[0:255],dmem[0:255]; integer i,cycles=0,retired=0;
 wire [31:0] ia,da,dw; wire [31:0] ir=imem[ia[9:2]],dr=dmem[da[9:2]]; wire dv,dwe,rv,rwe; wire [31:0] rpc,rwd; wire [4:0] rrd;
 PipelineCPU #(.PREDICT_EN(PREDICT_EN)) dut(.clk(clk),.resetn(resetn),.imem_addr(ia),.imem_rdata(ir),.dmem_valid(dv),.dmem_write(dwe),.dmem_addr(da),.dmem_wdata(dw),.dmem_rdata(dr),.retire_valid(rv),.retire_pc(rpc),.retire_reg_write(rwe),.retire_rd(rrd),.retire_wdata(rwd));
 always #5 clk=~clk;
 always @(posedge clk) begin if(resetn) begin cycles<=cycles+1;if(dwe)dmem[da[9:2]]<=dw;if(rv)retired<=retired+1;end end
 initial begin for(i=0;i<256;i=i+1)begin imem[i]=32'h00000013;dmem[i]=0;end $readmemh("text.mem",imem);$readmemh("data.mem",dmem);#12 resetn=1;
   wait(rv && rpc==32'h40); @(posedge clk); #1;
   if(dmem[0]!==1||dmem[1]!==2||dmem[2]!==3||dmem[3]!==4||dmem[4]!==5)
     $fatal(1,"PIPE_SORT_FAIL");
   $display("PIPE_SORT_DATA=%0d,%0d,%0d,%0d,%0d cycles=%0d retired=%0d",dmem[0],dmem[1],dmem[2],dmem[3],dmem[4],cycles,retired);
   $display("PIPE_SORT_PASS");$finish;end
 initial begin #20000;$fatal(1,"PIPE_SORT_TIMEOUT");$finish;end
endmodule
