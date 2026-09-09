`timescale 1ns/1ps
module env_tb;
 reg clk=0; always #50 clk=~clk;
 reg resetn=0,valid=0,write=0,rx=1,overflow=0;
 reg [31:0] addr=0,wdata=0,ia=0;
 wire [31:0] data,instr; wire tx;
 system_env dut(clk,resetn,ia,instr,valid,write,addr,wdata,data,overflow,rx,tx);
 task wr(input [31:0] a,input [31:0] d);
 begin @(negedge clk);addr=a;wdata=d;valid=1;write=1;
 @(negedge clk);valid=0;write=0; end endtask
 task check(input [31:0] a,input [31:0] expected,input [31:0] mask);
 begin @(negedge clk);addr=a;#1;
 if((data&mask)!==(expected&mask)) $fatal(1,"read %h expected %h actual %h",a,expected,data);
 end endtask
 task consume;
 begin @(negedge clk);addr=32'h40000008;valid=1;write=0;
 @(negedge clk);valid=0;end endtask
 task send(input [7:0] b,input good_stop);
 integer j;begin
 @(negedge clk);rx=0;repeat(87) @(negedge clk);
 for(j=0;j<8;j=j+1) begin rx=b[j];repeat(87) @(negedge clk);end
 rx=good_stop;repeat(87) @(negedge clk);rx=1;repeat(100) @(negedge clk);
 end endtask
 task receive(input [7:0] expected);
 integer j;reg [7:0] b;begin
 @(negedge tx);#4350;if(tx!==0) $fatal(1,"start bit");
 for(j=0;j<8;j=j+1) begin #8700;b[j]=tx;end
 #8700;if(tx!==1 || b!==expected) $fatal(1,"TX expected %h got %h",expected,b);
 end endtask
 task tx_test(input [7:0] b);
 begin fork wr(32'h40000000,b);receive(b);join
 repeat(100) @(negedge clk);end endtask
 initial begin
  repeat(5) @(negedge clk);resetn=1;
  check(32'h40000004,0,32'hffffffff);
  if(instr!==32'h13) $fatal(1,"ROM default");
  wr(0,32'h12345678);wr(32'h3fc,32'habcdef12);
  check(0,32'h12345678,32'hffffffff);check(32'h3fc,32'habcdef12,32'hffffffff);
  wr(32'h400,1);wr(1,2);wr(32'h40000400,3);
  check(0,32'h12345678,32'hffffffff);
  overflow=1;check(32'h4000000c,1,32'hffffffff);
  tx_test(8'h55);tx_test(0);tx_test(8'hff);
  fork begin wr(32'h40000000,8'h41);wr(32'h40000000,8'h42);end receive(8'h41);join
  repeat(100) @(negedge clk);check(32'h40000004,16,17);
  wr(32'h40000004,16);check(32'h40000004,0,16);
  send(8'h55,1);check(32'h40000008,8'h55,255);consume();
  send(0,1);check(32'h40000008,0,255);consume();
  send(8'hff,1);check(32'h40000008,255,255);consume();
  send("r",1);send("s",1);check(32'h40000004,6,6);
  check(32'h40000008,"r",255);consume();check(32'h40000008,0,255);
  wr(32'h40000004,4);send(8'h55,0);check(32'h40000004,8,14);
  wr(32'h40000004,8);send("r",1);check(32'h40000008,"r",255);
  // Consumption and arrival on the same edge must retain the NEW byte.
  fork
   send("n",1);
   begin
    wait(dut.uart.rx_state==3 && dut.uart.rx_count==1);
    @(negedge clk); // counter reaches zero at the following rising edge
    @(negedge clk);addr=32'h40000008;valid=1;write=0;
    @(negedge clk);valid=0;
   end
  join
  check(32'h40000008,"n",255);check(32'h40000004,2,6);
  resetn=0;repeat(3) @(negedge clk);resetn=1;
  check(32'h40000004,0,31);if(tx!==1) $fatal(1,"reset TX");
  $display("B_GROUP_ENV_PASS");$finish;
 end
 initial begin #30000000;$fatal(1,"timeout");end
endmodule
