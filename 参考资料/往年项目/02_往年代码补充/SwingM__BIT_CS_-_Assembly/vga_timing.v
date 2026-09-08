//640*480
module vga_timing( clk,reset_i,pixel_flag,
hsync,
vsync,
frame_o,
vga_rgb);

////////////////////////////////////////////////
// VGA
////////////////////////////////////////////////
input clk;
input reset_i;
output hsync; //VGA行同步信号
output vsync; //VGA场同步信号
output pixel_flag;
output frame_o;
output[7:0] vga_rgb;


reg [10:0] hcount; //VGA行扫描计数器
reg [9:0] vcount; //VGA场扫描计数器
reg [8:0] data; //VGA数据
reg vga_clk;

wire h_end;
wire v_end;

wire dat_act;

 

////////////////////////////////////////////////
// VGA
////////////////////////////////////////////////
always @(posedge clk)
begin
vga_clk = ~vga_clk;
end
// 竖向....
always @(posedge clk)
begin
if(h_end)
hcount <= 10'd0;
else
hcount <= hcount + 10'd1;
end

assign h_end = (hcount == 799);

// 横向....
always @(posedge clk)
begin
if(h_end)
begin
if(v_end)
vcount <= 10'd0;
else
vcount <= vcount + 10'd1;
end
end
assign v_end = (vcount == 524);


//使能信号
assign pixel_flag = ((hcount >= 144) && (hcount < 784))&& ((vcount >= 34) && (vcount < 514));

 

assign hsync = (hcount > 95);//水平同步
assign vsync = (vcount > 2);//垂直同步

 

reg frame_o_t;
always @(posedge clk)
begin
if( vcount < 3)
frame_o_t <= 1;
else
frame_o_t <= 0;
end

assign frame_o = frame_o_t;//垂直同步


wire[10:0] x_pos;
wire[10:0] y_pos;
assign x_pos = hcount - 144;//垂直同步
assign y_pos = vcount - 34;//垂直同步


reg[7:0] vga_rgb_t;

always @(posedge clk)
begin

if( x_pos<500 && y_pos > 80)
vga_rgb_t <= 8'b01101111;
else
vga_rgb_t <= 8'b00000000;
end


assign vga_rgb = vga_rgb_t;


endmodule