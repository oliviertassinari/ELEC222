# Les contraintes sur les entrés sorties sont plusieur type.
#  - choix des pattes associées à chaque signal entrant ou sortant du FPGA
#  - programmation des caractéristiques électriques de ces signaux
#  - programmation des caractéristiques des pattes non utilisées.
#  ATTENTION : il est important de maîtriser le comportement de TOUTES les pattes du FPGA
#  même si elles ne sont pas utilisées dans le design courant (évitons les courts circuits fâcheux...)

# NEUTRALISATON DE TOUTES LES ENTREES SORTIES NON UTILISEES
set_global_assignment -name RESERVE_ALL_UNUSED_PINS_NO_OUTPUT_GND "AS INPUT TRI-STATED"
set_global_assignment -name RESERVE_ALL_UNUSED_PINS "AS INPUT TRI-STATED"

# RECUPERATION OU INVALIDATION EVENTUELLE DES ENTREES SORTIES DE PROGRAMMATION DU FPGA POUR  L'APPLICATION 
# (entrées/sorties à double usage...)
set_global_assignment -name CYCLONEII_RESERVE_NCEO_AFTER_CONFIGURATION "USE AS REGULAR IO"
set_global_assignment -name RESERVE_ASDO_AFTER_CONFIGURATION "AS OUTPUT DRIVING AN UNSPECIFIED SIGNAL"

# DEFINITION DU STANDARD ELECTRIQUE DES CHOISI POUR LES ENTREES/SORTIES PAR DEFAUT
# SUR LA CARTE DE2 TOUT LES CHIP EXTERNES  FONCTIONNENT EN 3V3 standard "Low Voltage CMOS" ou "Low Voltage LVTTL"
# LES VALEURS POSSIBLES SONT DEFINIES PAR LE CONSTRUCTEUR.
set_global_assignment -name STRATIX_DEVICE_IO_STANDARD "3.3-V LVTTL"

# Pour définir le standard d'une IO en particulier on peut utiliser la syntaxe suivante
#     set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to mon_signal

# On peut définir le courant maximum débité par une sortie: le limiter pour limiter la consommation, ou
# l'augmenter pour tenir compte de la charge, la syntaxe est la suivante
#     set_instance_assignment -name CURRENT_STRENGTH_NEW "4MA" -to min_signal

# On peut programmer les "temps de montée", l'insertion de résistances de "pull-up" ou de "pull-down", l'insertion de maintien de bus....

# CHOIX DE POSITION DES ENTREES SORTIES
# Cela doit évidemment être en fait en cohérence avec ce que l'on sait du FPGA et des circuits
# qui lui sont reliés. La ligne ci-dessous est un exemple d'assignation.
#     set_location_assignment PIN_M20 -to address[10] -comment "Address pin to Second FPGA"
#

##### LA LISTE DES PINS PROPREMENT DITE

