module vga_sdram(input wire clk,
input wire reset_n,

output wire[31:0] master_address, //数据地址
output wire master_read, //主端口读请求
output wire master_byteenable,
input wire master_waitrequest, //迫使主端口等待
input wire master_readdatavalid, //指示已经提供有效数据
input wire[7:0] master_readdata, //读入数据值

input wire[31:0] vga_base_addr, //VGA基地址
input wire vga_go, //VGA 启动标记
input wire frame_start_flag, //帧开始标记
input wire[11:0] fifo_count
);

 

reg [19:0] input_data_count;
reg vga_read;

assign master_read = vga_read;
assign master_byteenable = 1'd1; //位使能
assign master_address = vga_base_addr + input_data_count;

//统计FIFO已经读了多少数据
always @ (posedge clk or negedge reset_n)
begin
if (!reset_n)
begin
//vga_read <= 1'b0; //SDRAM 停止读
end

// 一帧数据开始时，清除FIFO
else if (!master_waitrequest ) //地址计数 : // 1. 数据有效
begin

if (frame_start_flag)
begin
vga_read <= 1'b0;
end
else if( (fifo_count < 500) && (input_data_count < 307200) )
begin
vga_read <= 1'b1; // 向FIFO读数据
end
else if(fifo_count > 2000)
begin
vga_read <= 1'b0; // 向FIFO读数据
end


end
end


always @ (posedge clk or negedge reset_n)
begin
if (!reset_n)
begin
//input_data_count <= 0;
end

// 一帧数据开始时，清除FIFO
else if (!master_waitrequest ) //地址计数 : // 1. 数据有效
begin

if (frame_start_flag)
begin
input_data_count <= 0;
end
else if( input_data_count < 307200)
begin
if(vga_read == 1'b1)
input_data_count <= input_data_count + 1;
end

end
end

 

endmodule