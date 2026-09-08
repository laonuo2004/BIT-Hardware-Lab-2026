module VGA(
input wire clk,
input wire reset,

// 控制寄存器读写
input wire slave_chipselect,
input wire[1:0] slave_address, //
input wire slave_write, //写请求
input wire[31:0] slave_writedata, //写数据
input wire slave_read, //读请求
output wire[31:0] slave_readdata, //读数据
input wire[3:0] slave_byteenable, //数据有效标志


// 读写SDRAM数据
output wire[31:0] master_address, //数据地址
output wire master_read, //主端口读请求
output wire master_byteenable,
input wire master_waitrequest, //迫使主端口等待
input wire master_readdatavalid, //指示已经提供有效数据
input wire[7:0] master_readdata, //读入数据值

// VGA 时序
input wire vga_clk,
output wire vga_line_sync,
output wire vga_field_sync,
output wire [2:0] vga_r,
output wire [2:0] vga_g,
output wire [1:0] vga_b
);


wire vga_pixel_flag;

wire [7:0] fifo_data;
wire [7:0] tmp_data0;
reg [7:0] tmp_data1;

wire vga_frame_o;

 


/////////////////////////////////////////////////////////////////////////////////
////////// VGA输出 /////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////

assign vga_b = vga_pixel_flag ? fifo_data[1:0]:8'b00000000;
assign vga_g = vga_pixel_flag ? fifo_data[4:2]:8'b00000000;
assign vga_r = vga_pixel_flag ? fifo_data[7:5]:8'b00000000;


/////////////////////////////////////////////////////////////////////////////////
////////// VGA 时序 /////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////
vga_timing vga_l1(
.clk(vga_clk),
.reset_i(reset),
.pixel_flag(vga_pixel_flag),
.hsync(vga_line_sync),
.vsync(vga_field_sync),
.frame_o(vga_frame_o),
.vga_rgb(tmp_data0)
);

 


/////////////////////////////////////////////////////////////////////////////////
////////// VGA 寄存器操作 /////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////

//register 操作寄存器
wire vga_go; //VGA 启动标志
wire [31:0] vga_base_address; //vga 数据基地址

vga_register vga_slave(
.clk(clk),
.reset_n(reset),

// 控制寄存器读写
.slave_chipselect(slave_chipselect),
.slave_address(slave_address), //
.slave_write(slave_write), //写请求
.slave_writedata(slave_writedata), //写数据
.slave_read(slave_read), //读请求
.slave_readdata(slave_readdata), //读数据
.slave_byteenable(slave_byteenable), //数据有效标志

.vga_base_address(vga_base_address),
.vga_go(vga_go)
);

 


/////////////////////////////////////////////////////////////////////////////////
////////// VGA SDRAM 读取像素 /////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////

 

 

 

 


wire [11:0] fifo_count;

vga_sdram vga_sdram_11(
.clk(clk),
.reset_n(reset),

.master_address(master_address), //数据地址
.master_read(master_read), //主端口读请求
.master_byteenable(master_byteenable),
.master_waitrequest(master_waitrequest), //迫使主端口等待
.master_readdatavalid(master_readdatavalid),//指示已经提供有效数据
.master_readdata(master_readdata), //读入数据值

.vga_base_addr(vga_base_address), //VGA基地址
.vga_go(vga_go), //VGA 启动标记
.frame_start_flag(vga_frame_o), //帧开始标记
.fifo_count(fifo_count)
);

 

 

 

/////////////////////////////////////////////////////////////////////////////////
////////// VGA FIFO 做数据缓冲 以匹配不同速度的外设//////////////////////////
/////////////////////////////////////////////////////////////////////////////////

 

vga_fifo fifo_l2(
.aclr(vga_frame_o),
.data(master_readdata),
// .data(8'b00001000),
.rdclk(~vga_clk),
.rdreq(vga_pixel_flag),
.wrclk(clk),
.wrreq(master_readdatavalid),
.q(fifo_data),
.wrusedw(fifo_count)
);

 

 

endmodule