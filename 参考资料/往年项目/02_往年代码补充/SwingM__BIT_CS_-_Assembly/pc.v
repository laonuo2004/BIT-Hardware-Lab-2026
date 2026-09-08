`timescale 1ns / 1ps

module pc(
    input           clk,
    input           rst,
    
    input           pc_jmp,
    input           pc_br,      // branch
    input   [15:0]  pc_off,     // offset
    input   [25:0]  pc_tgt,     // target
    
    output  [31:0]  pc_val      // value
    );
    
    reg [31:0] pc_reg;
    
    wire [31:0] pc_ds;  // delay slot
    assign pc_ds = pc_reg + 32'h4;      // normally, next one equals to previous one plus 1
        
    always @(posedge clk or negedge rst) begin      // up clk or down rst wave
        if (!rst) pc_reg <= 32'hbfc00000;           // ?? the function here remains unknown
        else if (pc_jmp) pc_reg <= {pc_ds[31:28], pc_tgt[25:0], 2'b00};
        // ↑ jmp INST(), delay_Slot front 4bit + target 26bit + 00
        // jmp is already done
        else if (pc_br) pc_reg <= pc_ds + (pc_off << 2);    
        // delay_slot + offset left shift 2 position(no sign)
        // BEQ is already done
        else pc_reg <= pc_ds;
        // default: delay_slot(AKA plus 4)
    end
    
    assign pc_val = pc_reg;
    
endmodule
