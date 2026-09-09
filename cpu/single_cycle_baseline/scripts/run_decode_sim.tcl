set script_dir [file dirname [file normalize [info script]]]
set root_dir [file normalize [file join $script_dir ..]]
create_project -force decode_test [file join $root_dir build_decode] -part xc7a35tcsg324-1
add_files [file join $root_dir src Top.v]
add_files -fileset sim_1 [file join $root_dir sim decode_tb.v]
set_property top decode_tb [get_filesets sim_1]
launch_simulation
run all
close_sim
close_project
exit
