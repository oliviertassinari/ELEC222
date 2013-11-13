# @file  Makefile
# @brief The project source files
# @note  This file can be edited by the user to adapt it to its project

export SYN_DIR = $(shell pwd)

# source files directory
export SRC_DIR = $(SYN_DIR)/..

# source files for synthesis
export SOURCE_FILES = $(SRC_DIR)/wb_bram.sv $(SRC_DIR)/../wshb_if/wshb_if.sv
					  # separated with spaces	

# Top module for synthesis
export TOP_MODULE  = wb_bram

# End of SOURCE_FILES
.PHONY : all clean

all:
ifeq ($(TOP_MODULE),)
	@echo "You have to define the TOP MODULE !!!"
else 
ifeq ($(SOURCE_FILES),)
	@echo "You have to define the SOURCE FILES !!!"
else
	@echo "==> TOP LEVEL MODULE  : $(TOP_MODULE)"
	@echo "==> FILES : $(SOURCE_FILES)"
	precision -file synthesis.tcl
endif
endif

clean:
	@rm -rf $(TOP_MODULE)
	@rm -rf $(PART_MODULE)
	@rm -fr *.log *.psp impl*
	@rm -fr *_temp_*
