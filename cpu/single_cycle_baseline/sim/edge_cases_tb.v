`timescale 1ns/1ps
module edge_cases_tb;
  reg clk=0,rst=0,we=0; reg [4:0] ra1=0,ra2=0,wa=0; reg [31:0] wd=0;
  wire [31:0] rd1,rd2; reg [31:0] ins; reg [2:0] it; wire [31:0] imm;
  reg [31:0] pc=0,a,b; reg [2:0] bop; wire [31:0] npc; wire take;
  reg [3:0] aop; wire [31:0] y; integer errors=0;
  always #5 clk=~clk;
  RegisterFile rf(clk,rst,we,ra1,ra2,wa,wd,rd1,rd2);
  ImmediateGenerator ig(ins,it,imm);
  BranchUnit bu(pc,imm,a,b,bop,npc,take);
  ALU alu(a,b,aop,y);
  initial begin
    #2 rst=1; we=1; wa=0; wd=32'hffffffff; #10; we=0; ra1=0; #1;
    if(rd1!==0) begin $display("FAIL x0"); errors=errors+1; end
    ins=32'hfff08193; it=1; #1;
    if(imm!==32'hffffffff) begin $display("FAIL signext"); errors=errors+1; end
    a=32'hffffffff; b=1; bop=3; #1;
    if(!take) begin $display("FAIL signed_blt"); errors=errors+1; end
    a=32'hf0f0; b=32'h0ff0; aop=4; #1;
    if(y!==32'h00f0) begin $display("FAIL and"); errors=errors+1; end
    if(errors==0) $display("EDGE_CASES_PASS"); else $display("EDGE_CASES_FAIL errors=%0d",errors);
    $finish;
  end
  initial begin
    #100;
    $finish;
  end
endmodule
