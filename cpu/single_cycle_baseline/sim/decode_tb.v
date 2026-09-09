`timescale 1ns/1ps
module decode_tb;
  reg [31:0] instr;
  wire reg_write, mem_write, alu_src, uses_rs1, uses_rs2, illegal_instr;
  wire [1:0] wb_sel; wire [3:0] alu_op; wire [2:0] branch_op, imm_type;
  integer errors;
  ControlUnit dut(instr,reg_write,mem_write,alu_src,wb_sel,alu_op,branch_op,imm_type,uses_rs1,uses_rs2,illegal_instr);
  task legal; input [31:0] code; input r1,r2,rw,mw; begin
    instr=code; #1;
    if (illegal_instr || uses_rs1!==r1 || uses_rs2!==r2 || reg_write!==rw || mem_write!==mw) begin
      $display("FAIL code=%h",code); errors=errors+1;
    end
  end endtask
  initial begin errors=0;
    legal(32'h002081b3,1,1,1,0); legal(32'h402081b3,1,1,1,0);
    legal(32'h0020c1b3,1,1,1,0); legal(32'h0020f1b3,1,1,1,0);
    legal(32'h0020e1b3,1,1,1,0); legal(32'hfff08193,1,0,1,0);
    legal(32'h00f0e193,1,0,1,0); legal(32'h00f0f193,1,0,1,0);
    legal(32'h123451b7,0,0,1,0); legal(32'h0040a183,1,0,1,0);
    legal(32'h0020a223,1,1,0,1); legal(32'h00208463,1,1,0,0);
    legal(32'h00209463,1,1,0,0); legal(32'h0020c463,1,1,0,0);
    legal(32'h0020d463,1,1,0,0); legal(32'h008000ef,0,0,1,0);
    instr=32'h00001013; #1;
    if (!illegal_instr || reg_write || mem_write || branch_op!=0) begin $display("FAIL illegal"); errors=errors+1; end
    instr=32'h00f0f193; #1; if (alu_op!=4) begin $display("FAIL andi ALU"); errors=errors+1; end
    if(errors==0) $display("DECODE_PASS"); else $fatal(1,"DECODE_FAIL errors=%0d",errors);
    $finish;
  end
endmodule
