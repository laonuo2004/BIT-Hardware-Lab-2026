set script_dir [file dirname [file normalize [info script]]]
set root_dir [file normalize [file join $script_dir ..]]
create_project -force edge_test [file join $root_dir build_edge] -part xc7a35tcsg324-1
add_files [file join $root_dir src Top.v]
add_files -fileset sim_1 [file join $root_dir sim edge_cases_tb.v]
set_property top edge_cases_tb [get_filesets sim_1]
launch_simulation
run all
close_sim
close_project
exit
