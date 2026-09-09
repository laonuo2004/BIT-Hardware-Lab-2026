set sd [file dirname [file normalize [info script]]]; set root [file normalize [file join $sd ..]]
create_project -force hazard_test [file join $root build_hazard] -part xc7a35tcsg324-1
add_files [glob [file join $root src *.v]]
add_files -fileset sim_1 [file join $root sim hazard_tb.v]
set_property top hazard_tb [get_filesets sim_1]
set_property xsim.simulate.runtime 0ns [get_filesets sim_1]
launch_simulation
run all
close_sim
close_project
exit
