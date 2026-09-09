set sd [file dirname [file normalize [info script]]]
set root [file normalize [file join $sd ..]]
read_verilog [glob [file join $root src *.v]]
file mkdir [file join $root build synthesis]
synth_design -top PipelineCPU -part xc7a35tcsg324-1
create_clock -name cpu_clk -period 100.000 [get_ports clk]
report_utilization -file [file join $root build synthesis utilization.txt]
report_timing_summary -file [file join $root build synthesis timing_summary.txt]
# CPU-only synthesis is not board implementation/timing signoff.
exit
