// Shared instruction encoders and bus fixture; expected results live in each test.
parameter PREDICT_EN=1;
reg clk=0, resetn=0;
reg [31:0] imem[0:255], dmem[0:255];
wire [31:0] ia, da, dw, rpc, rwd;
wire dv, dwe, rv, rwe; wire [4:0] rd;
wire [31:0] bc,mc;
wire of;
wire fv;wire [31:0] fpc,fa;wire [1:0] fr;
wire [31:0] fixture_rdata;
`ifdef REAL_ENV
wire tx;
system_env env(.clk(clk),.resetn(resetn),.imem_addr(ia),.imem_rdata(),
 .dmem_valid(dv),.dmem_write(dwe),.dmem_addr(da),.dmem_wdata(dw),
 .dmem_rdata(fixture_rdata),.overflow_flag(of),.uart_rx(1'b1),.uart_tx(tx));
`else
assign fixture_rdata=dmem[da[9:2]];
`endif
integer writes=0, retired=0, cycles=0, k;
PipelineCPU #(.PREDICT_EN(PREDICT_EN)) dut(.clk(clk),.resetn(resetn),.imem_addr(ia),.imem_rdata(imem[ia[9:2]]),
 .dmem_valid(dv),.dmem_write(dwe),.dmem_addr(da),.dmem_wdata(dw),.dmem_rdata(fixture_rdata),
 .retire_valid(rv),.retire_pc(rpc),.retire_reg_write(rwe),.retire_rd(rd),.retire_wdata(rwd),.fault_valid(fv),.fault_pc(fpc),.fault_addr(fa),.fault_reason(fr),.overflow_flag(of),.branch_count(bc),.mispredict_count(mc));
always #5 clk=~clk;
always @(posedge clk) if(resetn) begin
 cycles=cycles+1;
 if(rv) retired=retired+1;
 if(dwe) begin dmem[da[9:2]]<=dw; writes=writes+1; end
 if(rwe && rd==0) $fatal(1,"X0_WRITE_PORT");
end
function [31:0] enc_i;
 input integer imm,rs1,funct3,rdest,opcode;
 begin enc_i=((imm&4095)<<20)|(rs1<<15)|(funct3<<12)|(rdest<<7)|opcode; end
endfunction
function [31:0] enc_r;
 input integer f7,rs2,rs1,f3,rdest;
 begin enc_r=(f7<<25)|(rs2<<20)|(rs1<<15)|(f3<<12)|(rdest<<7)|7'h33; end
endfunction
function [31:0] enc_s;
 input integer imm,rs2,rs1;
 begin enc_s=(((imm>>5)&127)<<25)|(rs2<<20)|(rs1<<15)|(2<<12)|((imm&31)<<7)|7'h23; end
endfunction
function [31:0] enc_b;
 input integer imm,rs2,rs1,f3;
 begin enc_b=(((imm>>12)&1)<<31)|(((imm>>5)&63)<<25)|(rs2<<20)|(rs1<<15)|(f3<<12)|(((imm>>1)&15)<<8)|(((imm>>11)&1)<<7)|7'h63; end
endfunction
function [31:0] enc_j;
 input integer imm,rdest;
 begin enc_j=(((imm>>20)&1)<<31)|(((imm>>1)&1023)<<21)|(((imm>>11)&1)<<20)|(((imm>>12)&255)<<12)|(rdest<<7)|7'h6f; end
endfunction
task fresh;
 begin
  resetn=0; #2;
  for(k=0;k<256;k=k+1) begin imem[k]=32'h00000013;dmem[k]=0;end
  repeat(2) @(negedge clk);
  writes=0;retired=0;cycles=0;
 end
endtask
task start_cpu; begin @(negedge clk);resetn=1;end endtask
task until_pc; input [31:0] last_pc;
 integer n; reg seen;
 begin
  n=0;seen=0;
  while(!seen && n<3000) begin
   @(posedge clk); seen=rv && rpc==last_pc; #1; n=n+1;
  end
  if(!seen) $fatal(1,"TIMEOUT waiting pc=%h",last_pc);
 end
endtask
task check_reg; input integer idx;input [31:0] expected;
 begin if(dut.regs[idx]!==expected) $fatal(1,"REG x%0d expected=%h got=%h",idx,expected,dut.regs[idx]);end
endtask
initial begin #200000;$fatal(1,"GLOBAL_TIMEOUT");end

// Sample before the edge and verify after nonblocking updates settle.
reg [31:0] held_pc,held_instr;reg check_hold;
always @(posedge clk) begin
 check_hold=resetn && dut.stall && !dut.redirect && !dut.mem_fault && !fv;
 held_pc=ia;held_instr=dut.ifid_instr;
 #1;
 if(check_hold && (ia!==held_pc || dut.ifid_instr!==held_instr || dut.idex_valid!==0))
  $fatal(1,"STALL_PROTOCOL");
end
