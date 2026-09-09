set root [file dirname [file normalize [info script]]]
create_project b_group [file join $root build] -part xc7a35tcsg324-1 -force
add_files [glob [file join $root rtl *.v]]
set_property top system_env [current_fileset]
add_files -fileset sim_1 [file join $root sim env_tb.v]
set_property top env_tb [get_filesets sim_1]
set_property xsim.simulate.runtime all [get_filesets sim_1]
launch_simulation
close_sim
close_project
