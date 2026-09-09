set_property PACKAGE_PIN T5 [get_ports clk_100m]
set_property IOSTANDARD LVCMOS33 [get_ports clk_100m]
create_clock -name sys_clk_100m -period 10.000 [get_ports clk_100m]

set_property PACKAGE_PIN P15 [get_ports resetn]
set_property IOSTANDARD LVCMOS33 [get_ports resetn]

set_property PACKAGE_PIN K2 [get_ports led0]
set_property IOSTANDARD LVCMOS33 [get_ports led0]
