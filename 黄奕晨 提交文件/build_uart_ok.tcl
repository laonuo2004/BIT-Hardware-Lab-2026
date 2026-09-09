# English-path EES-338 UART_OK demo. Reuse uart_mmio and clk_wiz_0. Do not rewrite UART.
set root {C:/Users/34556/Desktop/bgroup/b_group}
create_project ees338_uart_ok [file join $root uart_ok_build] -part xc7a35tcsg324-1 -force
add_files [file join $root ip clk_wiz_0 clk_wiz_0.xci]
add_files [file join $root rtl uart_mmio.v]
add_files [file join $root rtl board_uart_ok.v]
add_files -fileset constrs_1 [file join $root constraints ees338_uart.xdc]
set_property top board_uart_ok [current_fileset]
generate_target all [get_ips clk_wiz_0]
update_compile_order -fileset sources_1

puts "UART_PROJECT=[current_project]"
puts "UART_DIR=[get_property DIRECTORY [current_project]]"
puts "UART_PART=[get_property PART [current_project]]"
puts "UART_TOP=[get_property top [current_fileset]]"
foreach f [get_files *.v] { puts "UART_SRC=$f" }

launch_runs impl_1 -to_step write_bitstream -jobs 1
wait_on_run impl_1

set synth_status [get_property STATUS [get_runs synth_1]]
set impl_status [get_property STATUS [get_runs impl_1]]
set impl_progress [get_property PROGRESS [get_runs impl_1]]
puts "UART_SYNTH_STATUS=$synth_status"
puts "UART_IMPL_STATUS=$impl_status"
puts "UART_IMPL_PROGRESS=$impl_progress"

set bitfile [file join $root uart_ok_build ees338_uart_ok.runs impl_1 board_uart_ok.bit]
if {![file exists $bitfile]} {
  error "Missing bitstream: $bitfile"
}
puts "UART_BITFILE=$bitfile"

open_hw_manager
connect_hw_server
set targets [get_hw_targets]
puts "UART_HW_TARGETS=$targets"
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
puts "UART_DEVICE=$device PART=[get_property PART $device]"
set_property PROGRAM.FILE $bitfile $device
program_hw_devices $device
refresh_hw_device $device
puts "UART_PROGRAMMED_DEVICE=$device"
close_hw_target
disconnect_hw_server
close_hw_manager
close_project
puts "UART_OK_BITSTREAM_DONE"
