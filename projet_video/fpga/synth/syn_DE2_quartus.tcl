# Script de Synthèse en langage Tcl.

# Chargement des  paquets Quartus II
package require ::quartus::project
package require ::quartus::flow

# Le nom du module top sera celui du projet
set PROJET  $env(PROJET)
# On récupère le nom du répertoire principal du projet
# Utile dans le script de chargement des sources
set TOPDIR  $env(TOPDIR)

# N'ouvre un nouveau projet que s'il n'existe pas déjà
set make_assignment   0
if {[project_exists ${PROJET}]} {
	project_open -revision ${PROJET} ${PROJET}
} else {
	project_new -revision ${PROJET} ${PROJET}
	set make_assignment   1
}

# On récupère les contraintes et définitions
if {$make_assignment} {
        # Contraintes sur le FPGA choisi
        source "device_assignment.tcl"
        # Contraintes sur les entrées sorties
        source "pins_assignment.tcl"
        # Contraintes sur les timings
        set_global_assignment -name SDC_FILE timing_constraints.sdc
        # Liste des fichiers à compiler
        source "file_list.tcl"
         # Contraintes spécifiques au projet (comment synthétiser,..)
        source "project_assignment.tcl"
        # Commit assignments
        export_assignments
}
	#run quartus flow
	execute_flow -compile

	# Close project
	project_close

	exit
