`timescale 1ns/1ps
module overflow_detect(input [31:0] a,b,result, input is_sub, output overflow);
    assign overflow = is_sub ? ((a[31]^b[31]) & (result[31]^a[31]))
                             : (~(a[31]^b[31]) & (result[31]^a[31]));
endmodule
