# Official F3 performance matrix for Vivado 2019.2.
# Usage: vivado -mode batch -source cpu/performance/scripts/run_f3_vivado.tcl
set script_dir [file dirname [file normalize [info script]]]
set perf_dir [file normalize [file join $script_dir ..]]
set cpu_dir [file dirname $perf_dir]
set repo_dir [file dirname $cpu_dir]
set programs_dir [file join $perf_dir programs]
set build_dir [file join $perf_dir build vivado_f3]
set results_dir [file join $perf_dir results f3]
set raw_dir [file join $results_dir raw]
file mkdir $build_dir
file mkdir $raw_dir

set fp [open [file join $programs_dir cases.tsv] r]
set program_rows [split [read $fp] "\n"]
close $fp

set programs {}
foreach row $program_rows {
    if {$row eq "" || [string index $row 0] eq "#"} {continue}
    lassign [split $row "\t"] program test_id end_pc text_mem data_mem
    lappend programs [list $program $test_id $end_pc $text_mem $data_mem]
}

set versions {
    {single perf_single_tb -1 single_cycle_baseline}
    {pipeline_off perf_pipeline_tb 0 pipeline}
    {pipeline_on perf_pipeline_tb 1 pipeline}
}

set original_dir [pwd]
set failures 0
set total 0
set out [open [file join $results_dir raw_results.tsv] w]
puts $out "version\tprogram\tcycles\tretired\tstalls\tbranches\tmispredicts\ttime_ns"

foreach version_row $versions {
    lassign $version_row version top predict group
    foreach program_row $programs {
        lassign $program_row program test_id end_pc text_mem data_mem
        incr total
        set case_name "${version}_${program}"
        set work [file join $build_dir $case_name]
        file mkdir $work
        file copy -force [file join $programs_dir $text_mem] [file join $work text.mem]
        file copy -force [file join $programs_dir $data_mem] [file join $work data.mem]

        if {$version eq "single"} {
            set sources [list [file join $cpu_dir single_cycle_baseline src Top.v] \
                              [file join $perf_dir sim perf_single_tb.v]]
        } else {
            set sources [glob [file join $cpu_dir pipeline src *.v]]
            lappend sources [file join $perf_dir sim perf_pipeline_tb.v]
        }

        cd $work
        set transcript ""
        set compile_ok 1
        set xvlog_cmd [list xvlog -sv {*}$sources]
        if {[catch {exec {*}$xvlog_cmd 2>@1} result]} {set compile_ok 0}
        append transcript "$result\n"

        if {$compile_ok} {
            set xelab_cmd [list xelab $top -s sim_snapshot -debug typical \
                           -generic_top TEST_ID=$test_id -generic_top END_PC=$end_pc]
            if {$predict ne "-1"} {lappend xelab_cmd -generic_top PREDICT_EN=$predict}
            if {[catch {exec {*}$xelab_cmd 2>@1} result]} {set compile_ok 0}
            append transcript "$result\n"
        }

        set sim_error 0
        if {$compile_ok} {
            set sim_error [catch {exec xsim sim_snapshot -runall 2>@1} result]
            append transcript "$result\n"
        }

        set clean_transcript [string map [list $repo_dir <repository>] $transcript]
        set log [open [file join $raw_dir ${case_name}.log] w]
        puts $log $clean_transcript
        close $log

        set passed [expr {$compile_ok && !$sim_error && [string first "F3_PASS" $transcript] >= 0}]
        set pattern {F3_RESULT version=([^ ]+) program=([^ ]+) cycles=([0-9]+) retired=([0-9]+) stalls=([0-9]+) branches=([0-9]+) mispredicts=(-?[0-9]+) time_ns=([0-9]+)}
        if {![regexp $pattern $transcript match actual_version actual_program cycles retired stalls branches misses time_ns]} {
            set passed 0
        } else {
            puts $out "$actual_version\t$actual_program\t$cycles\t$retired\t$stalls\t$branches\t$misses\t$time_ns"
        }
        puts "[expr {$passed ? {PASS} : {FAIL}}] $case_name"
        if {!$passed} {incr failures}
    }
}

close $out
set meta [open [file join $results_dir metadata.txt] w]
puts $meta "tool=[version -short]"
puts $meta "simulation_clock_hz=10000000"
puts $meta "simulation_clock_period_ns=100"
puts $meta "single_model_clock_hz=10000000"
puts $meta "single_model_period_ns=100"
puts $meta "pipeline_configured_clock_hz=50000000"
puts $meta "pipeline_configured_period_ns=20"
puts $meta "pipeline_50mhz_post_route_wns_ns=6.527"
puts $meta "single_50mhz_core_post_route_wns_ns=6.080"
puts $meta "revision=[string trim [exec git -C $repo_dir rev-parse HEAD]]"
puts $meta "matrix=$total"
puts $meta "passed=[expr {$total-$failures}]"
close $meta
cd $original_dir
puts "F3 Vivado performance: [expr {$total-$failures}]/$total passed. Results: $results_dir"
if {$failures} {error "F3_PERFORMANCE_FAILED cases=$failures"}
exit
