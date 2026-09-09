# English-path EES-338 LED smoke: reset runs, bitstream, program.
# Do not synthesize env_tb or system_env. Do not touch UART.
set root {C:/Users/34556/Desktop/bgroup/b_group}
set xpr [file join $root smoke_build ees338_smoke.xpr]
if {![file exists $xpr]} {
  error "Missing project: $xpr"
}

open_project $xpr
puts "SMOKE_PROJECT=[current_project]"
puts "SMOKE_DIR=[get_property DIRECTORY [current_project]]"
puts "SMOKE_PART=[get_property PART [current_project]]"
puts "SMOKE_TOP=[get_property top [current_fileset]]"

foreach f [get_files *.v] {
  puts "SMOKE_SRC=$f"
}
foreach f [get_files *.xdc] {
  puts "SMOKE_XDC=$f"
}

if {[get_property PART [current_project]] ne "xc7a35tcsg324-1"} {
  error "Unexpected part"
}
if {[get_property top [current_fileset]] ne "board_smoke"} {
  error "Top must be board_smoke"
}
foreach f [get_files *.v] {
  if {[string match "*小学期项目*" $f] || [string match "V:/*" $f] || [string match "V:\\*" $f]} {
    error "Source still on Chinese/V: path: $f"
  }
  if {![string match "*board_smoke.v" $f]} {
    error "Unexpected HDL in smoke project: $f"
  }
}

reset_run synth_1
launch_runs impl_1 -to_step write_bitstream -jobs 1
wait_on_run impl_1

set synth_status [get_property STATUS [get_runs synth_1]]
set impl_status [get_property STATUS [get_runs impl_1]]
set impl_progress [get_property PROGRESS [get_runs impl_1]]
puts "SMOKE_SYNTH_STATUS=$synth_status"
puts "SMOKE_IMPL_STATUS=$impl_status"
puts "SMOKE_IMPL_PROGRESS=$impl_progress"

set bitfile [file join $root smoke_build ees338_smoke.runs impl_1 board_smoke.bit]
if {![file exists $bitfile]} {
  error "Missing bitstream: $bitfile"
}
puts "SMOKE_BITFILE=$bitfile"

open_hw_manager
connect_hw_server
set targets [get_hw_targets]
puts "SMOKE_HW_TARGETS=$targets"
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
puts "SMOKE_DEVICE=$device PART=[get_property PART $device]"
set_property PROGRAM.FILE $bitfile $device
program_hw_devices $device
refresh_hw_device $device
puts "SMOKE_PROGRAMMED_DEVICE=$device"
close_hw_target
disconnect_hw_server
close_hw_manager
close_project
puts "SMOKE_DONE"
