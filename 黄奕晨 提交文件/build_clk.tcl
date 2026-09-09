# English-path EES-338 100 MHz -> 10 MHz clock wrapper.
# Do not synthesize env_tb or system_env. Do not touch UART.
set root {C:/Users/34556/Desktop/bgroup/b_group}
set ipdir [file join $root ip]
file mkdir $ipdir

create_project ees338_clk [file join $root clk_build] -part xc7a35tcsg324-1 -force

create_ip -name clk_wiz -vendor xilinx.com -library ip -version 6.0 -module_name clk_wiz_0 -dir $ipdir
set_property -dict [list \
  CONFIG.PRIM_IN_FREQ {100.000} \
  CONFIG.PRIM_SOURCE {Single_ended_clock_capable_pin} \
  CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {10.000} \
  CONFIG.CLKOUT1_USED {true} \
  CONFIG.USE_LOCKED {true} \
  CONFIG.USE_RESET {true} \
  CONFIG.RESET_TYPE {ACTIVE_LOW} \
] [get_ips clk_wiz_0]
generate_target all [get_ips clk_wiz_0]

add_files [file join $root rtl board_clk.v]
add_files -fileset constrs_1 [file join $root constraints ees338_smoke.xdc]
set_property top board_clk [current_fileset]
update_compile_order -fileset sources_1

puts "CLK_PROJECT=[current_project]"
puts "CLK_DIR=[get_property DIRECTORY [current_project]]"
puts "CLK_PART=[get_property PART [current_project]]"
puts "CLK_TOP=[get_property top [current_fileset]]"
foreach f [get_files *.v] { puts "CLK_SRC=$f" }

launch_runs impl_1 -to_step write_bitstream -jobs 1
wait_on_run impl_1

set synth_status [get_property STATUS [get_runs synth_1]]
set impl_status [get_property STATUS [get_runs impl_1]]
set impl_progress [get_property PROGRESS [get_runs impl_1]]
puts "CLK_SYNTH_STATUS=$synth_status"
puts "CLK_IMPL_STATUS=$impl_status"
puts "CLK_IMPL_PROGRESS=$impl_progress"

set bitfile [file join $root clk_build ees338_clk.runs impl_1 board_clk.bit]
if {![file exists $bitfile]} {
  error "Missing bitstream: $bitfile"
}
puts "CLK_BITFILE=$bitfile"

open_hw_manager
connect_hw_server
set targets [get_hw_targets]
puts "CLK_HW_TARGETS=$targets"
if {[llength $targets] == 0} {
  error "No JTAG targets. Check board power and USB."
}
set target [lindex [get_hw_targets *1234-tulA] 0]
if {$target eq ""} {
  set target [lindex $targets 0]
}
current_hw_target $target
open_hw_target
set device [lindex [get_hw_devices xc7a35t_0] 0]
if {$device eq ""} {
  error "No xc7a35t_0 on $target"
}
current_hw_device $device
puts "CLK_DEVICE=$device PART=[get_property PART $device]"
set_property PROGRAM.FILE $bitfile $device
program_hw_devices $device
refresh_hw_device $device
puts "CLK_PROGRAMMED_DEVICE=$device"
close_hw_target
disconnect_hw_server
close_hw_manager
close_project
puts "CLK_DONE"
