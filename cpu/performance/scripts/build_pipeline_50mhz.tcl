# Build a separate 50 MHz full-system bitstream without touching the stable
# 10 MHz board project. UART remains at 115200 baud via BIT_CYCLES=434.

set script_dir [file dirname [file normalize [info script]]]
set repo_dir [file normalize [file join $script_dir .. .. ..]]
set result_dir [file join $repo_dir cpu performance results frequency_check]
file mkdir $result_dir

set stage_root [file normalize [file join $::env(TEMP) bit_hw_pipeline_50mhz]]
file delete -force $stage_root
file mkdir [file join $stage_root src]
file mkdir [file join $stage_root constraints]
file mkdir [file join $stage_root ip]

foreach source [glob [file join $repo_dir cpu pipeline src *.v]] {
    file copy -force $source [file join $stage_root src [file tail $source]]
}
file copy -force [file join $repo_dir cpu system src cpu_system.v] [file join $stage_root src cpu_system.v]

set board_root ""
foreach candidate [glob -nocomplain -types d [file join $repo_dir *]] {
    if {[file exists [file join $candidate rtl board_cpu_system.v]] &&
        [file exists [file join $candidate rtl uart_mmio.v]]} {
        set board_root $candidate
        break
    }
}
if {$board_root eq ""} {
    error "Board integration sources not found"
}
foreach source_name {uart_mmio.v system_env.v board_cpu_system.v} {
    file copy -force [file join $board_root rtl $source_name] [file join $stage_root src $source_name]
}
file copy -force [file join $board_root programs sort_uart.mem] [file join $stage_root src sort_uart.mem]
file copy -force [file join $board_root constraints ees338_uart.xdc] [file join $stage_root constraints ees338_uart.xdc]

# Keep the board wrapper behavior unchanged except for the clock-dependent UART
# divisor. round(50,000,000 / 115,200) = 434.
set board_file [file join $stage_root src board_cpu_system.v]
set handle [open $board_file r]
set board_text [read $handle]
close $handle
set board_text [string map [list ".BIT_CYCLES(87)" ".BIT_CYCLES(434)" "100 MHz -> 10 MHz" "100 MHz -> 50 MHz"] $board_text]
set handle [open $board_file w]
puts -nonewline $handle $board_text
close $handle

create_project pipeline_50mhz [file join $stage_root project] -part xc7a35tcsg324-1 -force
create_ip -name clk_wiz -vendor xilinx.com -library ip -version 6.0 -module_name clk_wiz_0 -dir [file join $stage_root ip]
set_property -dict [list \
    CONFIG.PRIM_IN_FREQ {100.000} \
    CONFIG.PRIM_SOURCE {Single_ended_clock_capable_pin} \
    CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {50.000} \
    CONFIG.CLKOUT1_USED {true} \
    CONFIG.USE_LOCKED {true} \
    CONFIG.USE_RESET {true} \
    CONFIG.RESET_TYPE {ACTIVE_LOW} \
] [get_ips clk_wiz_0]
generate_target all [get_ips clk_wiz_0]

add_files [glob [file join $stage_root src *.v]]
add_files [file join $stage_root src sort_uart.mem]
add_files -fileset constrs_1 [file join $stage_root constraints ees338_uart.xdc]
set_property top board_cpu_system [current_fileset]
update_compile_order -fileset sources_1

launch_runs impl_1 -to_step write_bitstream -jobs 2
wait_on_run impl_1
set impl_status [get_property STATUS [get_runs impl_1]]
set impl_progress [get_property PROGRESS [get_runs impl_1]]
puts "PIPELINE_50MHZ_IMPL status=$impl_status progress=$impl_progress"

open_run impl_1
set timing_report [file join $result_dir pipeline_50mhz_full_system_timing_summary.txt]
report_timing_summary -delay_type max -max_paths 10 -report_unconstrained -file $timing_report
set timing_path [get_timing_paths -delay_type max -max_paths 1]
set wns [get_property SLACK $timing_path]
set met [expr {$wns >= 0.0 ? 1 : 0}]

set source_bit [file join $stage_root project pipeline_50mhz.runs impl_1 board_cpu_system.bit]
set result_bit [file join $result_dir pipeline_50mhz_full_system.bit]
if {![file exists $source_bit]} {
    error "Missing bitstream: $source_bit"
}
file copy -force $source_bit $result_bit

set result [open [file join $result_dir pipeline_50mhz_full_system.tsv] w]
puts $result "frequency_mhz\tperiod_ns\twns_ns\ttiming_met\tuart_bit_cycles\tbaud"
puts $result "50\t20\t$wns\t$met\t434\t115200"
close $result
puts "PIPELINE_50MHZ_RESULT wns_ns=$wns timing_met=$met bitstream=$result_bit"
close_project
exit
