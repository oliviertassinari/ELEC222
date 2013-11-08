# @file  Makefile
# @brief The project source files
# @note  This file can be edited by the user to adapt it to its project

export SIM_DIR = $(shell pwd)

# source files directory
export FPGA_SRC_DIR = $(SIM_DIR)/../src
export TB_FPGA_SRC_DIR = $(SIM_DIR)/../tb_src
export VGA_SRC_DIR = $(SIM_DIR)/../../vga/src

# source files for synthesis
export SOURCE_FILES = $(FPGA_SRC_DIR)/fpga.sv $(TB_FPGA_SRC_DIR)/tb_fpga.sv $(VGA_SRC_DIR)/vga.sv

# End of SOURCE_FILES
.PHONY : all clean

all:
	vlib work
	vlog +acc $(FPGA_SRC_DIR)/fpga.sv
	vlog +acc $(FPGA_SRC_DIR)/reset.sv
	vlog +acc $(TB_FPGA_SRC_DIR)/tb_fpga.sv
	vlog +acc $(VGA_SRC_DIR)/vga.sv
	vlog +acc $(VGA_SRC_DIR)/VGA_PLL.v
	vsim tb_fpga -L altera_mf_ver

clean :
	rm -rf work
	rm -rf *.wlf
	rm -rf transcript