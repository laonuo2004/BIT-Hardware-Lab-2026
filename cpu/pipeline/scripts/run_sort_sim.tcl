set sd [file dirname [file normalize [info script]]]; set root [file normalize [file join $sd ..]]
create_project -force pipeline_sort [file join $root build] -part xc7a35tcsg324-1
add_files [glob [file join $root src *.v]]
add_files -fileset sim_1 [file join $root sim pipeline_sort_tb.v]
add_files -fileset sim_1 [file join $root programs text.mem]
add_files -fileset sim_1 [file join $root programs data.mem]
set_property file_type {Memory Initialization Files} [get_files *.mem]
set_property top pipeline_sort_tb [get_filesets sim_1]
set_property xsim.simulate.runtime 0ns [get_filesets sim_1]
launch_simulation
run all
close_sim
close_project
exit
