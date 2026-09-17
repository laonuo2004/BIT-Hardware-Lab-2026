set script_dir [file dirname [file normalize [info script]]]
set repo_dir [file normalize [file join $script_dir .. .. ..]]
set bitfile [file join $repo_dir cpu performance results frequency_check pipeline_50mhz_full_system.bit]
if {![file exists $bitfile]} {
    error "Missing 50 MHz bitstream: $bitfile"
}

open_hw_manager
connect_hw_server
set targets [get_hw_targets]
if {[llength $targets] == 0} {
    error "No JTAG targets found"
}
set target [lindex [get_hw_targets *1234-tulA] 0]
if {$target eq ""} {
    set target [lindex $targets 0]
}
current_hw_target $target
open_hw_target
set device [lindex [get_hw_devices xc7a35t_0] 0]
if {$device eq ""} {
    error "No xc7a35t device found"
}
current_hw_device $device
set_property PROGRAM.FILE $bitfile $device
program_hw_devices $device
refresh_hw_device $device
puts "PIPELINE_50MHZ_PROGRAMMED target=$target device=$device bitstream=$bitfile"
close_hw_target
disconnect_hw_server
close_hw_manager
exit
