set root [file dirname [file normalize [info script]]]
create_project ees338_smoke [file join $root smoke_build] -part xc7a35tcsg324-1 -force
add_files [file join $root rtl board_smoke.v]
add_files -fileset constrs_1 [file join $root constraints ees338_smoke.xdc]
set_property top board_smoke [current_fileset]
launch_runs impl_1 -to_step write_bitstream -jobs 2
wait_on_run impl_1
open_run impl_1
report_timing_summary -file [file join $root smoke_timing.txt]
report_drc -file [file join $root smoke_drc.txt]
set bitfile [get_property PROGRESS [get_runs impl_1]]
puts "SMOKE_IMPL_STATUS=$bitfile"
close_project
