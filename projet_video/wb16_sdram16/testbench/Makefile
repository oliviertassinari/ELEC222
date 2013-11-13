.PHONY: clean all simu_batch compile simu_gui

TOPDIR = $(shell pwd)
TB_TOP = testbench_top
WORK_DIR = work_simu

#VPATH := ${TOPDIR} ${TOPDIR}/.. 

# Whisbone interface sources
WSHBSRCDIR  = $(TOPDIR)/../../wshb_if
WSHBSRC     = $(wildcard $(WSHBSRCDIR)/*.sv)
DEP         = $(patsubst $(WSHBSRCDIR)/%.sv,$(WORK_DIR)/.%.compiled,${WSHBSRC})
# Whishbone testbench sources
WSHBTBSRCDIR  = $(TOPDIR)/../../wshb_if/testbench
WSHBTBSRC     = $(wildcard $(WSHBTBSRCDIR)/*.sv)
DEP          += $(patsubst $(WSHBTBSRCDIR)/%.sv,$(WORK_DIR)/.%.compiled,${WSHBTBSRC})
# Module sources
SRCDIR    = $(TOPDIR)/../src
SRC       = $(wildcard $(SRCDIR)/*.sv)
DEP      += $(patsubst $(SRCDIR)/%.sv,$(WORK_DIR)/.%.compiled,${SRC})
# Module testbench sources
TBDIR     = $(TOPDIR)
TBSRC     = $(wildcard $(TBDIR)/*.sv)
DEP      += $(patsubst $(TBDIR)/%.sv,$(WORK_DIR)/.%.compiled,${TBSRC})
# VHDL SDRAM model
SDRAMDIR  = $(TOPDIR)/sdram_model
SDRAMSRC  = $(wildcard $(SDRAMDIR)/*.vhd)
DEPVHD    = $(patsubst $(SDRAMDIR)/%.vhd,$(WORK_DIR)/.%.compiled,${SDRAMSRC})



all: simu_batch

simu_batch: compile
	cd $(WORK_DIR) ; vsim  -c -t 1ps -lib work $(TB_TOP) -do "run -all ; quit"

simu_gui: compile
	cd $(WORK_DIR); vsim  -t 1ps -lib work $(TB_TOP) -do "run -all ; quit"

compile: $(DEP) $(DEPVHD)

$(WORK_DIR)/.%.compiled: $(WSHBTBSRCDIR)/%.sv | $(WORK_DIR)/work
	cd $(WORK_DIR) ; vlog  +acc $< 
	touch $@

$(WORK_DIR)/.%.compiled: $(WSHBSRCDIR)/%.sv | $(WORK_DIR)/work
	cd $(WORK_DIR) ; vlog  +acc $< 
	touch $@

$(WORK_DIR)/.%.compiled: $(TBDIR)/%.sv | $(WORK_DIR)/work
	cd $(WORK_DIR) ; vlog  +acc $< 
	touch $@

$(WORK_DIR)/.%.compiled: $(SRCDIR)/%.sv | $(WORK_DIR)/work
	cd $(WORK_DIR) ; vlog  +acc $< 
	touch $@

$(WORK_DIR)/.%.compiled: $(BRDGSRCDIR)/%.sv | $(WORK_DIR)/work
	cd $(WORK_DIR) ; vlog  +acc $< 
	touch $@

$(WORK_DIR)/.%.compiled: $(SDRAMDIR)/%.vhd | $(WORK_DIR)/work
	cd $(WORK_DIR) ; vcom   $< 
	touch $@

$(WORK_DIR):
	mkdir $(WORK_DIR) 
	cp km416s4030.mem $(WORK_DIR)

$(WORK_DIR)/work: $(WORK_DIR)
	cd $(WORK_DIR) ; vlib work

clean:
	rm -rf $(WORK_DIR)
