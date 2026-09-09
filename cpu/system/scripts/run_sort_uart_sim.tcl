# Run with Vivado 2019.2. Sources are staged under an ASCII temporary path to
# avoid the Windows/Tcl encoding issue caused by the repository's Chinese path.
# M6 第三步：冯丽嘉的应用汇编（排序 + UART 输出 + 收 'r' 重跑）系统集成测试。
set script_dir [file dirname [file normalize [info script]]]
set system_dir [file normalize [file join $script_dir ..]]
set cpu_dir [file normalize [file join $system_dir ..]]
set repo_dir [file normalize [file join $cpu_dir ..]]
set stage_dir [file normalize [file join $::env(TEMP) bit_hw_sort_uart_sim]]
file delete -force $stage_dir
file mkdir $stage_dir

foreach source [glob [file join $cpu_dir pipeline src *.v]] {
    file copy -force $source [file join $stage_dir [file tail $source]]
}
file copy -force [file join $system_dir src cpu_system.v] $stage_dir
file copy -force [file join $system_dir sim sort_uart_tb.v] $stage_dir
file copy -force [file join $system_dir programs sort_uart.mem] $stage_dir

set env_matches [glob -nocomplain [file join $repo_dir * rtl system_env.v]]
set uart_matches [glob -nocomplain [file join $repo_dir * rtl uart_mmio.v]]
if {[llength $env_matches] != 1 || [llength $uart_matches] != 1} {
    error "SYSTEM_ENV_SOURCES_NOT_UNIQUE"
}
file copy -force [lindex $env_matches 0] [file join $stage_dir system_env.v]
file copy -force [lindex $uart_matches 0] [file join $stage_dir uart_mmio.v]

set original_dir [pwd]
cd $stage_dir
set sources [glob [file join $stage_dir *.v]]
set transcript ""
foreach cmd [list \
    [list xvlog -sv {*}$sources] \
    [list xelab sort_uart_tb -s sort_uart_snapshot -debug typical] \
    [list xsim sort_uart_snapshot -runall]] {
    if {[catch {exec {*}$cmd 2>@1} result]} {
        append transcript "$result\n"
        cd $original_dir
        error "SORT_UART_SYSTEM_FAILED\n$transcript"
    }
    append transcript "$result\n"
}
cd $original_dir
if {[string first "SORT_UART_SYSTEM_PASS" $transcript] < 0} {
    error "SORT_UART_SYSTEM_MARKER_MISSING\n$transcript"
}
puts "SORT_UART system integration: PASS"
puts $transcript
file delete -force $stage_dir
