# English-path EES-338 full system: clk_wiz_0 + CpuSystem + system_env + sort_uart.mem.
# Do not rewrite UART. Do not synthesize env_tb.
set root {C:/Users/34556/Desktop/bgroup/b_group}
set cpu {C:/Users/34556/Desktop/bgroup/github_lab/cpu}

create_project ees338_cpu_system [file join $root system_build] -part xc7a35tcsg324-1 -force
add_files [file join $root ip clk_wiz_0 clk_wiz_0.xci]
add_files [file join $root rtl uart_mmio.v]
add_files [file join $root rtl system_env.v]
add_files [file join $cpu system src cpu_system.v]
add_files [glob [file join $cpu pipeline src *.v]]
add_files [file join $root rtl board_cpu_system.v]
add_files [file join $root programs sort_uart.mem]
add_files -fileset constrs_1 [file join $root constraints ees338_uart.xdc]
set_property top board_cpu_system [current_fileset]
generate_target all [get_ips clk_wiz_0]
update_compile_order -fileset sources_1

puts "SYS_PROJECT=[current_project]"
puts "SYS_DIR=[get_property DIRECTORY [current_project]]"
puts "SYS_PART=[get_property PART [current_project]]"
puts "SYS_TOP=[get_property top [current_fileset]]"
foreach f [get_files *.v] { puts "SYS_SRC=$f" }

launch_runs impl_1 -to_step write_bitstream -jobs 1
wait_on_run impl_1

set synth_status [get_property STATUS [get_runs synth_1]]
set impl_status [get_property STATUS [get_runs impl_1]]
set impl_progress [get_property PROGRESS [get_runs impl_1]]
puts "SYS_SYNTH_STATUS=$synth_status"
puts "SYS_IMPL_STATUS=$impl_status"
puts "SYS_IMPL_PROGRESS=$impl_progress"

set bitfile [file join $root system_build ees338_cpu_system.runs impl_1 board_cpu_system.bit]
if {![file exists $bitfile]} {
  error "Missing bitstream: $bitfile"
}
puts "SYS_BITFILE=$bitfile"

open_hw_manager
connect_hw_server
set targets [get_hw_targets]
puts "SYS_HW_TARGETS=$targets"
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
puts "SYS_DEVICE=$device PART=[get_property PART $device]"
set_property PROGRAM.FILE $bitfile $device
program_hw_devices $device
refresh_hw_device $device
puts "SYS_PROGRAMMED_DEVICE=$device"
close_hw_target
disconnect_hw_server
close_hw_manager
close_project
puts "SYS_BITSTREAM_DONE"
