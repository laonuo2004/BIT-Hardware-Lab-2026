# Smoke test for round 2: pipeline_on + btfnt_loop.
set script_dir [file dirname [file normalize [info script]]]
set perf_dir [file normalize [file join $script_dir ..]]
set cpu_dir [file dirname $perf_dir]
set programs_dir [file join $perf_dir programs]
set work [file join $perf_dir build vivado_f3_round2 smoke_pipeline_on_btfnt_loop]
file mkdir $work
file copy -force [file join $programs_dir btfnt_loop_text.mem] [file join $work text.mem]
file copy -force [file join $programs_dir btfnt_loop_data.mem] [file join $work data.mem]
set sources [glob [file join $cpu_dir pipeline src *.v]]
lappend sources [file join $perf_dir sim perf_pipeline_tb.v]
set original_dir [pwd]
cd $work
exec xvlog -sv {*}$sources 2>@1
exec xelab perf_pipeline_tb -s sim_snapshot -debug typical \
    -generic_top TEST_ID=5 -generic_top END_PC=16 -generic_top PREDICT_EN=1 2>@1
set transcript [exec xsim sim_snapshot -runall 2>@1]
puts $transcript
if {[string first "F3_PASS" $transcript] < 0 ||
    [string first "program=btfnt_loop" $transcript] < 0 ||
    [string first "branches=256 mispredicts=1" $transcript] < 0} {
    error "F3_ROUND2_SMOKE_FAILED"
}
cd $original_dir
puts "F3_ROUND2_SMOKE_PASS pipeline_on btfnt_loop"
exit
