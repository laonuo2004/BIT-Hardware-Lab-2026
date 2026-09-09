`timescale 1ns/1ps
module prediction_tb;
`include "test_support.vh"
initial begin
 fresh;
 imem[0]=enc_i(3,0,0,1,7'h13);
 imem[1]=enc_i(-1,1,0,1,7'h13);
 imem[2]=enc_b(-4,0,1,1);
 imem[3]=enc_j(0,0);
 start_cpu;until_pc(12);check_reg(1,0);
 if(bc!==3 || mc!==(PREDICT_EN?32'd1:32'd2) || retired!=8)
  $fatal(1,"LOOP_COUNTS branches=%0d misses=%0d retired=%0d",bc,mc,retired);
 $display("LOOP predict=%0d branches=%0d misses=%0d cycles=%0d",PREDICT_EN,bc,mc,cycles);
 fresh;
 imem[0]=enc_b(8,0,0,0);
 imem[1]=enc_s(4,0,0);
 imem[2]=enc_b(8,0,0,1);
 imem[3]=enc_i(12,0,0,5,7'h13);
 imem[4]=enc_j(8,6);
 imem[5]=32'hffffffff; // jal flush suppresses illegal assertion
 imem[6]=enc_s(0,5,0);
 imem[7]=enc_j(0,0);
 start_cpu;until_pc(28);check_reg(5,12);check_reg(6,20);
 if(bc!==2 || mc!==1 || writes!=1 || dmem[0]!==12) $fatal(1,"FORWARD_OR_JAL");
 fresh;dmem[0]=3;
 imem[0]=enc_i(0,0,2,1,7'h03);
 imem[1]=enc_b(8,1,0,4);
 imem[2]=enc_s(4,1,0);
 imem[3]=enc_j(0,0);
 start_cpu;until_pc(12);
 if(bc!==1 || mc!==1 || writes!=0) $fatal(1,"LOAD_BRANCH");
 fresh;
 imem[0]=enc_j(20,0);
 imem[4]=enc_s(1024,0,0); // predicted target must be killed
 imem[5]=enc_i(1,0,0,1,7'h13);
 imem[8]=enc_b(-16,0,1,0); // backward not taken
 imem[9]=enc_j(0,0);
 start_cpu;until_pc(36);
 if(fv || writes!=0 || bc!==1 || mc!==(PREDICT_EN?32'd1:32'd0)) $fatal(1,"BACKWARD_NOT_TAKEN");
 $display("PREDICTION_PASS");$finish;
end
endmodule
