`timescale 1ns/1ps

module perf_pipeline_tb;
  parameter integer PREDICT_EN = 1;
  parameter integer TEST_ID = 0;
  parameter [31:0] END_PC = 32'd80;

  reg clk = 0;
  reg resetn = 0;
  reg [31:0] imem [0:255];
  reg [31:0] dmem [0:255];
  integer i;
  integer cycles = 0;
  integer retired = 0;
  integer stalls = 0;
  integer counting = 0;
  integer passed = 0;

  wire [31:0] ia, da, dw;
  wire [31:0] ir = imem[ia[9:2]];
  wire [31:0] dr = dmem[da[9:2]];
  wire dv, dwe, rv, rwe;
  wire [31:0] rpc, rwd;
  wire [4:0] rd;
  wire fv, of;
  wire [31:0] fpc, fa, bc, mc;
  wire [1:0] fr;

  PipelineCPU #(.PREDICT_EN(PREDICT_EN)) dut(
    .clk(clk), .resetn(resetn),
    .imem_addr(ia), .imem_rdata(ir),
    .dmem_valid(dv), .dmem_write(dwe), .dmem_addr(da),
    .dmem_wdata(dw), .dmem_rdata(dr),
    .retire_valid(rv), .retire_pc(rpc), .retire_reg_write(rwe),
    .retire_rd(rd), .retire_wdata(rwd),
    .fault_valid(fv), .fault_pc(fpc), .fault_addr(fa), .fault_reason(fr),
    .overflow_flag(of), .branch_count(bc), .mispredict_count(mc)
  );

  // Main comparison clock: 10 MHz, 100 ns per cycle.
  always #50 clk = ~clk;

  initial begin
    for (i=0; i<256; i=i+1) begin
      imem[i] = 32'h00000013;
      dmem[i] = 32'd0;
    end
    $readmemh("text.mem", imem);
    $readmemh("data.mem", dmem);
    #120 resetn = 1;
  end

  task check_result;
    begin
      passed = 0;
      case (TEST_ID)
        0: passed = (dut.regs[1] === 32'd1 && dut.regs[20] === 32'd20);
        1: passed = (dut.regs[1] === 32'd20);
        2: passed = (dmem[0] === 32'd1 && dmem[1] === 32'd2 &&
                     dmem[2] === 32'd3 && dmem[3] === 32'd4 &&
                     dmem[4] === 32'd5);
      endcase
      if (!passed) $fatal(1, "F3_PIPE_RESULT_FAIL predict=%0d test=%0d", PREDICT_EN, TEST_ID);
      if (fv) $fatal(1, "F3_PIPE_FAULT reason=%0d pc=%h addr=%h", fr, fpc, fa);
    end
  endtask

  always @(posedge clk) begin
    if (resetn && dwe) dmem[da[9:2]] <= dw;
    if (!resetn) begin
      cycles = 0;
      retired = 0;
      stalls = 0;
      counting = 0;
    end else begin
      if (!counting && ia == 32'd0) counting = 1;
      if (counting) begin
        cycles = cycles + 1;
        if (dut.stall) stalls = stalls + 1;
        if (rv) begin
          retired = retired + 1;
          if (rpc == END_PC) begin
            #1;
            check_result;
            if (PREDICT_EN) begin
              case (TEST_ID)
                0: $display("F3_RESULT version=pipeline_on program=independent cycles=%0d retired=%0d stalls=%0d branches=%0d mispredicts=%0d time_ns=%0d", cycles, retired, stalls, bc, mc, cycles*100);
                1: $display("F3_RESULT version=pipeline_on program=dependency cycles=%0d retired=%0d stalls=%0d branches=%0d mispredicts=%0d time_ns=%0d", cycles, retired, stalls, bc, mc, cycles*100);
                2: $display("F3_RESULT version=pipeline_on program=sort cycles=%0d retired=%0d stalls=%0d branches=%0d mispredicts=%0d time_ns=%0d", cycles, retired, stalls, bc, mc, cycles*100);
              endcase
            end else begin
              case (TEST_ID)
                0: $display("F3_RESULT version=pipeline_off program=independent cycles=%0d retired=%0d stalls=%0d branches=%0d mispredicts=%0d time_ns=%0d", cycles, retired, stalls, bc, mc, cycles*100);
                1: $display("F3_RESULT version=pipeline_off program=dependency cycles=%0d retired=%0d stalls=%0d branches=%0d mispredicts=%0d time_ns=%0d", cycles, retired, stalls, bc, mc, cycles*100);
                2: $display("F3_RESULT version=pipeline_off program=sort cycles=%0d retired=%0d stalls=%0d branches=%0d mispredicts=%0d time_ns=%0d", cycles, retired, stalls, bc, mc, cycles*100);
              endcase
            end
            $display("F3_PASS");
            $finish;
          end
        end
      end
    end
  end

  initial begin
    #200000;
    $fatal(1, "F3_PIPE_TIMEOUT predict=%0d test=%0d", PREDICT_EN, TEST_ID);
  end
endmodule
