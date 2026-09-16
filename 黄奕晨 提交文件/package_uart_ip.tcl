# Package existing uart_mmio as Vivado 2019.2 IP. Do not rewrite UART RTL.
# English path only. Then import the packaged HDL in a fresh sim and rerun uart_mmio_tb.
set root {C:/Users/34556/Desktop/bgroup/b_group}
set ip_root [file join $root ip uart_mmio]
set pkg_build [file join $root uart_ip_pack_build]
set stage_dir [file normalize [file join $::env(TEMP) bit_hw_uart_ip_verify]]

file mkdir [file join $root ip]
if {[file exists $ip_root]} {
  file delete -force $ip_root
}
if {[file exists $pkg_build]} {
  file delete -force $pkg_build
}

create_project uart_ip_pack $pkg_build -part xc7a35tcsg324-1 -force
add_files [file join $root rtl uart_mmio.v]
set_property top uart_mmio [current_fileset]
update_compile_order -fileset sources_1

ipx::package_project -root_dir $ip_root -vendor bit.lab -library user -taxonomy /UserIP -import_files -force
set core [ipx::current_core]
set_property name uart_mmio $core
set_property display_name {UART MMIO} $core
set_property description {Custom UART 115200 8N1 with TX/STATUS/RX MMIO. Default BIT_CYCLES=87 at 10 MHz.} $core
set_property vendor_display_name {BIT Hardware Lab B} $core
set_property version {1.0} $core
set_property core_revision 1 $core
set_property supported_families [list artix7 Production] $core

ipx::create_xgui_files $core
ipx::update_checksums $core
ipx::save_core $core
close_project
puts "UART_IP_PACKAGED=$ip_root"

set ip_src [glob -nocomplain [file join $ip_root *.v] [file join $ip_root src *.v] [file join $ip_root hdl *.v]]
if {[llength $ip_src] < 1} {
  error "Packaged UART HDL not found under $ip_root"
}
puts "UART_IP_HDL=$ip_src"

file delete -force $stage_dir
file mkdir $stage_dir
foreach f $ip_src {
  file copy -force $f [file join $stage_dir [file tail $f]]
}
file copy -force [file join $root rtl system_env.v] [file join $stage_dir system_env.v]
file copy -force [file join $root sim uart_mmio_tb.v] [file join $stage_dir uart_mmio_tb.v]

set original_dir [pwd]
cd $stage_dir
set sources [glob [file join $stage_dir *.v]]
set transcript ""
foreach cmd [list \
    [list xvlog -sv {*}$sources] \
    [list xelab uart_mmio_tb -s uart_ip_snapshot -debug typical] \
    [list xsim uart_ip_snapshot -runall]] {
  if {[catch {exec {*}$cmd 2>@1} result]} {
    append transcript "$result\n"
    cd $original_dir
    error "UART_IP_VERIFY_FAILED\n$transcript"
  }
  append transcript "$result\n"
}
cd $original_dir
if {[string first "UART_MMIO_TB_PASS" $transcript] < 0} {
  error "UART_IP_VERIFY_MARKER_MISSING\n$transcript"
}
puts "UART_IP_VERIFY=PASS"
puts $transcript
file delete -force $stage_dir
puts "UART_IP_DONE"
