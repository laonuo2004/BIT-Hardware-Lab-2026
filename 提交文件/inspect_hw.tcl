open_hw_manager
connect_hw_server
foreach target [get_hw_targets] {
 current_hw_target $target
 open_hw_target
 puts "DETECTED_TARGET=$target"
 foreach device [get_hw_devices] { puts "DETECTED_DEVICE=$device PART=[get_property PART $device]" }
 close_hw_target
}
disconnect_hw_server
close_hw_manager
