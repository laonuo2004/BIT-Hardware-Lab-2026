set sd [file dirname [file normalize [info script]]]
set root [file normalize [file join $sd ..]]
read_verilog [file join $root src pipeline_cpu.v]
file mkdir [file join $root results]
synth_design -top PipelineCPU -part xc7a35tcsg324-1
report_utilization -file [file join $root results utilization.txt]
report_timing_summary -file [file join $root results timing_summary.txt]
exit
