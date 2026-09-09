# Run in the Vivado 2019.2 Tcl console or: vivado -mode batch -source <this file>
# Uses the same cases.tsv as run_tests.py; no Python dependency.
set script_dir [file dirname [file normalize [info script]]]
set cpu_dir [file normalize [file join $script_dir ../..]]
set repo_dir [file dirname $cpu_dir]
set pipe_dir [file join $cpu_dir pipeline]
set output_dir [file join $pipe_dir build vivado_regression]
file mkdir $output_dir
set fp [open [file join $script_dir cases.tsv] r]
set cases [split [read $fp] "\n"]
close $fp
set original_dir [pwd]
set failures 0
set number 0
foreach row $cases {
    if {$row eq "" || [string index $row 0] eq "#"} {continue}
    lassign [split $row "\t"] top marker group predict illegal
    set case_name [format "%02d_%s" $number $top]
    incr number
    set work [file join $output_dir $case_name]
    file mkdir $work
    foreach mem [glob -nocomplain [file join $cpu_dir $group programs *.mem]] {
        file copy -force $mem $work
    }
    set sources [glob [file join $cpu_dir $group src *.v]]
    if {$top eq "status_mmio_tb"} {
        lappend sources [file join $repo_dir "黄奕晨 提交文件" rtl system_env.v]
        lappend sources [file join $repo_dir "黄奕晨 提交文件" rtl uart_mmio.v]
    }
    lappend sources [file join $cpu_dir $group sim ${top}.v]
    cd $work
    set transcript ""
    set compile_ok 1
    foreach cmd [list [list xvlog -sv -i [file join $pipe_dir sim] {*}$sources] \
                      [list xelab $top -s sim_snapshot -debug typical {*}[expr {$predict eq "-1" ? {} : [list -generic_top PREDICT_EN=$predict]}]]] {
        if {[catch {exec {*}$cmd 2>@1} result]} {set compile_ok 0}
        append transcript "$result\n"
        if {!$compile_ok} {break}
    }
    set sim_error 0
    if {$compile_ok} {
        set cmd [list xsim sim_snapshot -runall -testplusarg WAVES]
        if {$illegal} {lappend cmd -testplusarg ILLEGAL}
        set sim_error [catch {exec {*}$cmd 2>@1} result]
        append transcript "$result\n"
    }
    set passed [expr {$compile_ok && [string first $marker $transcript]>=0}]
    if {!$illegal && ($sim_error || [regexp -nocase {fatal:|error:|warning:|_FAIL|TIMEOUT} $transcript])} {set passed 0}
    # The expected-illegal case also fails explicitly if no assertion occurred.
    if {$illegal && [string first MISSING_ILLEGAL_TRAP $transcript]>=0} {set passed 0}
    set fp [open result.txt w];puts $fp $transcript;close $fp
    puts "[expr {$passed ? {PASS} : {FAIL}}] $case_name"
    if {!$passed} {incr failures}
}
cd $original_dir
puts "Vivado regression: [expr {$number-$failures}]/$number passed. Logs: $output_dir"
if {$failures} {error "M3_REGRESSION_FAILED cases=$failures"}
