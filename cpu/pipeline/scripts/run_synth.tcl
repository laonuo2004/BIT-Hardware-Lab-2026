set sd [file dirname [file normalize [info script]]]
set root [file normalize [file join $sd ..]]
set output_dir [file join $root build synthesis]
file mkdir $output_dir

# Vivado 2019.2 on Windows can crash after synthesis when its process working
# directory contains non-ASCII characters. Stage only the RTL in an ASCII temp
# directory; reports are still written back into the repository build folder.
set original_dir [pwd]
set stage_dir [file normalize [file join $::env(TEMP) bit_hw_cpu_synth]]
file delete -force $stage_dir
file mkdir $stage_dir
foreach source [glob [file join $root src *.v]] {
    file copy -force $source [file join $stage_dir [file tail $source]]
}
cd $stage_dir
read_verilog [glob [file join $stage_dir *.v]]
synth_design -top PipelineCPU -part xc7a35tcsg324-1
create_clock -name cpu_clk -period 100.000 [get_ports clk]
report_utilization -file [file join $output_dir utilization.txt]
report_timing_summary -file [file join $output_dir timing_summary.txt]
cd $original_dir
file delete -force $stage_dir
# CPU-only synthesis is not board implementation/timing signoff.
exit
