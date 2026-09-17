`timescale 1ns/1ps

module perf_single_tb;
  parameter integer TEST_ID = 0;
  parameter [31:0] END_PC = 32'd80;

  reg clk = 0;
  reg rst = 0;
  integer cycles = 0;
  integer retired = 0;
  integer branches = 0;
  integer counting = 0;
  integer passed = 0;

  Top dut(.clk(clk), .rst(rst));
  wire [31:0] pc = dut.pc;
  wire [31:0] instr = dut.instr;

  // Main comparison clock: 10 MHz, 100 ns per cycle.
  always #50 clk = ~clk;

  initial begin
    #120 rst = 1;
  end

  task check_result;
    begin
      passed = 0;
      case (TEST_ID)
        0: passed = (dut.register_file.regs[1] === 32'd1 &&
                     dut.register_file.regs[20] === 32'd20);
        1: passed = (dut.register_file.regs[1] === 32'd20);
        2: passed = (dut.data_memory.mem[0] === 32'd1 &&
                     dut.data_memory.mem[1] === 32'd2 &&
                     dut.data_memory.mem[2] === 32'd3 &&
                     dut.data_memory.mem[3] === 32'd4 &&
                     dut.data_memory.mem[4] === 32'd5);
      endcase
      if (!passed) $fatal(1, "F3_SINGLE_RESULT_FAIL test=%0d", TEST_ID);
    end
  endtask

  always @(posedge clk) begin
    if (!rst) begin
      cycles = 0;
      retired = 0;
      branches = 0;
      counting = 0;
    end else begin
      if (!counting && pc == 32'd0) counting = 1;
      if (counting) begin
        cycles = cycles + 1;
        retired = retired + 1;
        if (instr[6:0] == 7'b1100011) branches = branches + 1;
        if (pc == END_PC) begin
          #1;
          check_result;
          case (TEST_ID)
            0: $display("F3_RESULT version=single program=independent cycles=%0d retired=%0d stalls=0 branches=%0d mispredicts=-1 time_ns=%0d", cycles, retired, branches, cycles*100);
            1: $display("F3_RESULT version=single program=dependency cycles=%0d retired=%0d stalls=0 branches=%0d mispredicts=-1 time_ns=%0d", cycles, retired, branches, cycles*100);
            2: $display("F3_RESULT version=single program=sort cycles=%0d retired=%0d stalls=0 branches=%0d mispredicts=-1 time_ns=%0d", cycles, retired, branches, cycles*100);
          endcase
          $display("F3_PASS");
          $finish;
        end
      end
    end
  end

  initial begin
    #200000;
    $fatal(1, "F3_SINGLE_TIMEOUT test=%0d", TEST_ID);
  end
endmodule
