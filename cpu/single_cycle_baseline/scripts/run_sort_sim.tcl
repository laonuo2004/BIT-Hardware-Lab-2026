set script_dir [file dirname [file normalize [info script]]]
set root_dir [file normalize [file join $script_dir ..]]
set build_dir [file join $root_dir build]

create_project -force single_cycle_baseline $build_dir -part xc7a35tcsg324-1
add_files [file join $root_dir src Top.v]
add_files -fileset sim_1 [file join $root_dir sim cpu_sort_tb.v]
add_files -fileset sim_1 [file join $root_dir programs text.mem]
add_files -fileset sim_1 [file join $root_dir programs data.mem]
set_property top cpu_sort_tb [get_filesets sim_1]
set_property file_type {Memory Initialization Files} [get_files *.mem]
launch_simulation
run all
close_sim
close_project
exit
