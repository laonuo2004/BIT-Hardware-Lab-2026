set root [file dirname [file normalize [info script]]]
create_project -in_memory -part xc7a35tcsg324-1
read_verilog [glob [file join $root rtl *.v]]
synth_design -top system_env -part xc7a35tcsg324-1 -mode out_of_context
report_utilization -file [file join $root utilization.txt]
write_checkpoint -force [file join $root system_env_synth.dcp]
puts "B_GROUP_SYNTH_PASS"
