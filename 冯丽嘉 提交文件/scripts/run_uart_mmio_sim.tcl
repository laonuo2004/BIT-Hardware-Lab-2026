# 冯丽嘉 M4 UART 测试台在 Vivado 2019.2 中的运行脚本。
# 与 cpu/system/scripts 下的脚本同样方式：把源文件暂存到 ASCII 临时目录再跑，
# 避免仓库中文路径在 Windows/Tcl 下的编码问题。
set script_dir [file dirname [file normalize [info script]]]
set feng_dir [file normalize [file join $script_dir ..]]
set repo_dir [file normalize [file join $feng_dir ..]]
set stage_dir [file normalize [file join $::env(TEMP) bit_hw_uart_mmio_sim]]
file delete -force $stage_dir
file mkdir $stage_dir

file copy -force [file join $feng_dir sim uart_mmio_tb.v] $stage_dir
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
    [list xelab uart_mmio_tb -s uart_mmio_snapshot -debug typical] \
    [list xsim uart_mmio_snapshot -runall]] {
    if {[catch {exec {*}$cmd 2>@1} result]} {
        append transcript "$result\n"
        cd $original_dir
        error "UART_MMIO_TB_FAILED\n$transcript"
    }
    append transcript "$result\n"
}
cd $original_dir
if {[string first "UART_MMIO_TB_PASS" $transcript] < 0} {
    error "UART_MMIO_TB_MARKER_MISSING\n$transcript"
}
puts "UART_MMIO_TB: PASS"
puts $transcript
file delete -force $stage_dir
