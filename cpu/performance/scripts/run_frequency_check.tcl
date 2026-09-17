# Post-route frequency check for the single-cycle and pipelined CPU cores.
# Usage example:
#   set TARGET_PERIOD_NS 20.0
#   source run_frequency_check.tcl

set script_dir [file dirname [file normalize [info script]]]
set repo_dir [file normalize [file join $script_dir .. .. ..]]
set result_dir [file join $repo_dir cpu performance results frequency_check]
file mkdir $result_dir

if {[info exists ::env(TARGET_PERIOD_NS)]} {
    set target_period_ns $::env(TARGET_PERIOD_NS)
} elseif {[info exists TARGET_PERIOD_NS]} {
    set target_period_ns $TARGET_PERIOD_NS
} else {
    set target_period_ns 20.0
}

set stage_root [file normalize [file join $::env(TEMP) bit_hw_frequency_check]]
file delete -force $stage_root
file mkdir $stage_root

set result_file [file join $result_dir "period_${target_period_ns}ns.tsv"]
set out [open $result_file w]
puts $out "design\tperiod_ns\twns_ns\ttiming_met"

proc run_design {name top sources period_ns stage_root result_dir out} {
    set design_stage [file join $stage_root $name]
    file mkdir $design_stage
    foreach source $sources {
        file copy -force $source [file join $design_stage [file tail $source]]
    }

    if {$name eq "single"} {
        # The functional Top has no output ports, so Vivado legitimately removes
        # it. Add observation-only outputs to the staged copy; repository RTL is
        # not modified and the complete architectural critical paths are kept.
        set staged_top [file join $design_stage Top.v]
        set source_file [open $staged_top r]
        set source_text [read $source_file]
        close $source_file
        set old_header "module Top(\n    input clk,\n    input rst\n);"
        set new_header "module SingleTimingTop(\n    input clk,\n    input rst,\n    output \[31:0\] timing_next_pc,\n    output \[31:0\] timing_wb_data,\n    output \[31:0\] timing_mem_rdata\n);"
        set source_text [string map [list $old_header $new_header] $source_text]
        set final_end [string last "endmodule" $source_text]
        set observations "assign timing_next_pc = next_pc;\n    assign timing_wb_data = wb_data;\n    assign timing_mem_rdata = mem_rdata;\n"
        set source_text "[string range $source_text 0 [expr {$final_end-1}]]$observations[string range $source_text $final_end end]"
        set source_file [open $staged_top w]
        puts -nonewline $source_file $source_text
        close $source_file

        set single_root [file normalize [file join [file dirname [lindex $sources 0]] ..]]
        foreach mem_name {text.mem data.mem} {
            file copy -force [file join $single_root programs $mem_name] [file join $design_stage $mem_name]
        }
    } else {
        set pipeline_root [file normalize [file join [file dirname [lindex $sources 0]] ..]]
        foreach mem_name {text.mem data.mem} {
            file copy -force [file join $pipeline_root programs $mem_name] [file join $design_stage $mem_name]
        }
    }

    set old_dir [pwd]
    cd $design_stage
    create_project -in_memory -part xc7a35tcsg324-1
    read_verilog [glob [file join $design_stage *.v]]
    set xdc_path [file join $design_stage timing.xdc]
    set xdc [open $xdc_path w]
    puts $xdc "create_clock -name cpu_clk -period $period_ns \[get_ports clk\]"
    close $xdc
    read_xdc $xdc_path
    synth_design -top $top -part xc7a35tcsg324-1
    opt_design
    place_design
    phys_opt_design
    route_design

    set report_path [file join $result_dir "${name}_${period_ns}ns_timing_summary.txt"]
    report_timing_summary -delay_type max -max_paths 10 -report_unconstrained -file $report_path
    set timing_path [get_timing_paths -delay_type max -max_paths 1]
    set wns [get_property SLACK $timing_path]
    set met [expr {$wns >= 0.0 ? 1 : 0}]
    puts $out "$name\t$period_ns\t$wns\t$met"
    flush $out
    puts "FREQUENCY_CHECK design=$name period_ns=$period_ns wns_ns=$wns timing_met=$met"
    close_project
    cd $old_dir
}

set single_sources [list [file join $repo_dir cpu single_cycle_baseline src Top.v]]
set pipeline_sources [concat \
    [glob [file join $repo_dir cpu pipeline src *.v]] \
    [list [file join $repo_dir cpu performance rtl pipeline_timing_top.v]]]

run_design single SingleTimingTop $single_sources $target_period_ns $stage_root $result_dir $out
run_design pipeline PipelineTimingTop $pipeline_sources $target_period_ns $stage_root $result_dir $out

close $out
file delete -force $stage_root
puts "FREQUENCY_CHECK_COMPLETE result=$result_file"
exit
