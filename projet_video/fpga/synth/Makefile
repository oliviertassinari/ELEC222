# Le nom du projet doit être le nom du module de plus haut niveau
export PROJET = fpga
export TOPDIR = $(shell pwd)/../..


.PHONY: all clean program

all:
		quartus_sh -t syn_DE2_quartus.tcl

program:
		@quartus_pgm -c USB-Blaster  -m JTAG -oP\;${PROJET}.sof
clean:
		rm -rf ${PROJET}*
		rm -rf db
		rm -rf incremental_db*
