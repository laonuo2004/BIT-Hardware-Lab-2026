set root [file dirname [file normalize [info script]]]
set bitfile [file join $root smoke_build ees338_smoke.runs impl_1 board_smoke.bit]
if {![file exists $bitfile]} { error "Missing bitstream: $bitfile" }
open_hw_manager
connect_hw_server
set target [lindex [get_hw_targets *1234-tulA] 0]
current_hw_target $target
open_hw_target
set device [lindex [get_hw_devices xc7a35t_0] 0]
current_hw_device $device
set_property PROGRAM.FILE $bitfile $device
program_hw_devices $device
refresh_hw_device $device
puts "SMOKE_PROGRAMMED_DEVICE=$device STATUS=[get_property PROGRAM.HW_CFGMEM $device]"
close_hw_target
disconnect_hw_server
close_hw_manager
