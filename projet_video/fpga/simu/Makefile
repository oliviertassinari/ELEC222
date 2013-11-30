# @file  Makefile
# @brief The project source files
# @note  This file can be edited by the user to adapt it to its project

# source files directory
export TOP_DIR = ../..
export FPGA_SRC_DIR = ../src
export TB_FPGA_SRC_DIR = ../tb_src
export VGA_SRC_DIR = ../../vga/src

# source files for synthesis
export SOURCE_FILES = $(FPGA_SRC_DIR)/fpga.sv $(TB_FPGA_SRC_DIR)/tb_fpga.sv $(VGA_SRC_DIR)/vga.sv

# End of SOURCE_FILES
.PHONY : all clean

all:
	vlib work
	vlog +acc $(TOP_DIR)/fpga/src/fpga.sv
	vlog +acc $(TOP_DIR)/fpga/src/reset.sv
	vlog +acc $(TOP_DIR)/fpga/src/wshb_pll.v
	vlog +acc $(TOP_DIR)/fpga/tb_src/tb_fpga.sv
	vlog +acc $(TOP_DIR)/vga/src/vga.sv
	vlog +acc $(TOP_DIR)/vga/src/VGA_PLL.v
	vlog +acc $(TOP_DIR)/fifo_async/src/fifo_async.sv
	sh ./$(TOP_DIR)/wb16_sdram16/compile_wshb_sdram_models.sh
	vsim tb_fpga -L altera_mf_ver

clean :
	rm -rf work *.wlf transcript *.mem