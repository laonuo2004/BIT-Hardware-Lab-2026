`timescale 1ns/1ps
module sort_variants_tb;
 parameter PREDICT_EN=1;
 reg clk=0,resetn=0;
 reg [31:0] imem[0:255],dmem[0:255];
 integer i,cycles=0,retired=0,writes=0;
 wire [31:0] ia,da,dw,rpc,rwd;
 wire dv,dwe,rv,rwe,of,fv;
 wire [4:0] rd;
 wire [31:0] fpc,fa,bc,mc;
 wire [1:0] fr;
 wire [31:0] ir=imem[ia[9:2]],dr=dmem[da[9:2]];

 PipelineCPU #(.PREDICT_EN(PREDICT_EN)) dut(
  .clk(clk),.resetn(resetn),.imem_addr(ia),.imem_rdata(ir),
  .dmem_valid(dv),.dmem_write(dwe),.dmem_addr(da),.dmem_wdata(dw),.dmem_rdata(dr),
  .retire_valid(rv),.retire_pc(rpc),.retire_reg_write(rwe),.retire_rd(rd),.retire_wdata(rwd),
  .fault_valid(fv),.fault_pc(fpc),.fault_addr(fa),.fault_reason(fr),
  .overflow_flag(of),.branch_count(bc),.mispredict_count(mc));

 always #5 clk=~clk;
 always @(posedge clk) if(resetn) begin
  cycles=cycles+1;
  if(rv) retired=retired+1;
  if(dwe) begin dmem[da[9:2]]<=dw;writes=writes+1;end
 end

 task run_case;
  input integer case_id;
  input [31:0] a,b,c,d,e;
  input [31:0] x0,x1,x2,x3,x4;
  integer n;reg seen;
  begin
   resetn=0;
   repeat(2) @(negedge clk);
   for(i=0;i<256;i=i+1)dmem[i]=0;
   dmem[0]=a;dmem[1]=b;dmem[2]=c;dmem[3]=d;dmem[4]=e;
   cycles=0;retired=0;writes=0;
   @(negedge clk);resetn=1;
   n=0;seen=0;
   while(!seen && n<5000) begin
    @(posedge clk);#1;seen=rv && rpc==32'h40;n=n+1;
   end
   if(!seen)$fatal(1,"F1_SORT_TIMEOUT case=%0d",case_id);
   if(fv)$fatal(1,"F1_SORT_FAULT case=%0d pc=%h addr=%h reason=%0d",case_id,fpc,fa,fr);
   if(dmem[0]!==x0 || dmem[1]!==x1 || dmem[2]!==x2 || dmem[3]!==x3 || dmem[4]!==x4)
    $fatal(1,"F1_SORT_FAIL case=%0d got=%h,%h,%h,%h,%h",case_id,dmem[0],dmem[1],dmem[2],dmem[3],dmem[4]);
   $display("F1_SORT_CASE_PASS case=%0d data=%0d,%0d,%0d,%0d,%0d cycles=%0d retired=%0d",
    case_id,$signed(dmem[0]),$signed(dmem[1]),$signed(dmem[2]),$signed(dmem[3]),$signed(dmem[4]),cycles,retired);
  end
 endtask

 initial begin
  for(i=0;i<256;i=i+1)imem[i]=32'h00000013;
  $readmemh("text.mem",imem);
  run_case(0,1,2,3,4,5,1,2,3,4,5);
  run_case(1,5,4,3,2,1,1,2,3,4,5);
  run_case(2,3,1,3,2,1,1,1,2,3,3);
  run_case(3,32'hffffffff,3,32'hfffffffb,2,0,32'hfffffffb,32'hffffffff,0,2,3);
  $display("F1_SORT_VARIANTS_PASS");
  $finish;
 end
 initial begin #1000000;$fatal(1,"F1_SORT_GLOBAL_TIMEOUT");end
endmodule
