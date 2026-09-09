`timescale 1ns/1ps
module hazard_tb;
 reg clk=0,resetn=0,done=0; reg [31:0] imem[0:63],dmem[0:63]; integer i,writes=0;
 wire [31:0] ia,da,dw; wire [31:0] ir=imem[ia[7:2]],dr=dmem[da[7:2]]; wire dv,dwe,rv,rwe; wire [31:0] rpc,rwd; wire [4:0] rrd;
 PipelineCPU dut(clk,resetn,ia,ir,dv,dwe,da,dw,dr,rv,rpc,rwe,rrd,rwd);
 always #5 clk=~clk;
 always @(posedge clk) if(resetn&&dwe) begin dmem[da[7:2]]<=dw;writes<=writes+1;end
 initial begin
  for(i=0;i<64;i=i+1)begin imem[i]=0;dmem[i]=0;end
  imem[0]=32'h00500093; // addi x1,x0,5
  imem[1]=32'h00108133; // add  x2,x1,x1
  imem[2]=32'h00202023; // sw   x2,0(x0)
  imem[3]=32'h00002183; // lw   x3,0(x0)
  imem[4]=32'h00118233; // add  x4,x3,x1
  imem[5]=32'h00420463; // beq  x4,x4,+8
  imem[6]=32'h00102223; // wrong path: sw x1,4(x0)
  imem[7]=32'h00402423; // sw x4,8(x0)
  imem[8]=32'h0080006f; // jal x0,+8
  imem[9]=32'h00102623; // wrong path: sw x1,12(x0)
  imem[10]=32'h00202823;// sw x2,16(x0)
  #12 resetn=1; wait(dmem[4]==10); #30;
  if(dmem[0]==10&&dmem[1]==0&&dmem[2]==15&&dmem[3]==0&&dmem[4]==10&&writes==3)
    $display("HAZARD_PASS writes=%0d",writes);
  else $display("HAZARD_FAIL m=%0d,%0d,%0d,%0d,%0d writes=%0d",dmem[0],dmem[1],dmem[2],dmem[3],dmem[4],writes);
  done=1;$finish;
 end
 initial begin #5000;if(!done)$display("HAZARD_TIMEOUT");$finish;end
endmodule
