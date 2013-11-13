# La liste des fichiers source à utiliser.

set_global_assignment -name SYSTEMVERILOG_FILE ${TOPDIR}/fpga/src/fpga.sv
set_global_assignment -name SYSTEMVERILOG_FILE ${TOPDIR}/fpga/src/reset.sv
set_global_assignment -name SYSTEMVERILOG_FILE ${TOPDIR}/fpga/src/wshb_pll.v

set_global_assignment -name SYSTEMVERILOG_FILE ${TOPDIR}/vga/src/vga.sv
set_global_assignment -name SYSTEMVERILOG_FILE ${TOPDIR}/vga/src/VGA_PLL.v

set_global_assignment -name SYSTEMVERILOG_FILE ${TOPDIR}/fifo_async/src/fifo_async.sv

set_global_assignment -name SYSTEMVERILOG_FILE ${TOPDIR}/wb16_sdram16/src/wb16_sdram16.sv
set_global_assignment -name SYSTEMVERILOG_FILE ${TOPDIR}/wb16_sdram16/src/xess_sdramcntl.sv
set_global_assignment -name SYSTEMVERILOG_FILE ${TOPDIR}/wb16_sdram16/src/wb_bridge_xess.sv

set_global_assignment -name SYSTEMVERILOG_FILE ${TOPDIR}/wishbone/wshb_if/wshb_if.sv