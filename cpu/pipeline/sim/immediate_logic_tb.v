`timescale 1ns/1ps
module immediate_logic_tb;
reg clk=0, resetn=0; reg [31:0] imem[0:63]; integer i, errors=0;
wire [31:0] ia,da,dw,rpc,rwd; wire dv,dwe,rv,rwe; wire [4:0] rd;
PipelineCPU dut(.clk(clk),.resetn(resetn),.imem_addr(ia),.imem_rdata(imem[ia[7:2]]),.dmem_valid(dv),.dmem_write(dwe),.dmem_addr(da),.dmem_wdata(dw),.dmem_rdata(32'd0),.retire_valid(rv),.retire_pc(rpc),.retire_reg_write(rwe),.retire_rd(rd),.retire_wdata(rwd));
always #5 clk=~clk;
always @(posedge clk) if(resetn && rv) $display("RETIRE pc=%h rd=%0d we=%b value=%h",rpc,rd,rwe,rwd);
initial begin
 for(i=0;i<64;i=i+1) imem[i]=32'h00000013;
 imem[0]=32'h01200093; // addi x1,x0,18
 imem[1]=32'h00f0e113; // ori x2,x1,15 => 31
 imem[2]=32'h00f0f193; // andi x3,x1,15 => 2
 imem[3]=32'h00000013; // legal NOP
 imem[4]=32'h00700213; // addi x4,x0,7
 imem[5]=32'h0000006f;
 #12 resetn=1;
 #400;
 if(dut.regs[2]!==32'd31) begin $display("REVIEW_FAIL ori expected=31 actual=%0d",dut.regs[2]); errors=errors+1; end
 if(dut.regs[3]!==32'd2) begin $display("REVIEW_FAIL andi expected=2 actual=%0d",dut.regs[3]); errors=errors+1; end

 if(errors) $fatal(1,"IMMEDIATE_LOGIC_FAILED errors=%0d",errors);
 $display("IMMEDIATE_LOGIC_PASS");$finish;
end
endmodule
