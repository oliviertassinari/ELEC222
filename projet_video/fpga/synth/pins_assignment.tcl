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

# Clock 50KHz
set_location_assignment PIN_N2 -to CLK

# KEY0
set_location_assignment PIN_G26 -to NRST

# LEDG0
set_location_assignment PIN_AE23 -to LED_ROUGE
set_instance_assignment -name OUTPUT_PIN_LOAD 8 -to LED_ROUGE

# LEDR0
set_location_assignment PIN_AE22 -to LED_VERTE
set_instance_assignment -name OUTPUT_PIN_LOAD 8 -to LED_VERTE

# SW0
set_location_assignment PIN_N25 -to SW

# VGA
set_location_assignment VGA_R[0] -to PIN_C8
set_location_assignment VGA_R[1] -to PIN_F10
set_location_assignment VGA_R[2] -to PIN_G10
set_location_assignment VGA_R[3] -to PIN_D9
set_location_assignment VGA_R[4] -to PIN_C9
set_location_assignment VGA_R[5] -to PIN_A8
set_location_assignment VGA_R[6] -to PIN_H11
set_location_assignment VGA_R[7] -to PIN_H12
set_location_assignment VGA_R[8] -to PIN_F11
set_location_assignment VGA_R[9] -to PIN_E10
set_location_assignment VGA_G[0] -to PIN_B9
set_location_assignment VGA_G[1] -to PIN_A9
set_location_assignment VGA_G[2] -to PIN_C10
set_location_assignment VGA_G[3] -to PIN_D10
set_location_assignment VGA_G[4] -to PIN_B10
set_location_assignment VGA_G[5] -to PIN_A10
set_location_assignment VGA_G[6] -to PIN_G11
set_location_assignment VGA_G[7] -to PIN_D11
set_location_assignment VGA_G[8] -to PIN_E12
set_location_assignment VGA_G[9] -to PIN_D12
set_location_assignment VGA_B[0] -to PIN_J13
set_location_assignment VGA_B[1] -to PIN_J14
set_location_assignment VGA_B[2] -to PIN_F12
set_location_assignment VGA_B[3] -to PIN_G12
set_location_assignment VGA_B[4] -to PIN_J10
set_location_assignment VGA_B[5] -to PIN_J11
set_location_assignment VGA_B[6] -to PIN_C11
set_location_assignment VGA_B[7] -to PIN_B11
set_location_assignment VGA_B[8] -to PIN_C12
set_location_assignment VGA_B[9] -to PIN_B12
set_location_assignment VGA_CLK -to PIN_B8
set_location_assignment VGA_BLANK -to PIN_D6
set_location_assignment VGA_HS -to PIN_A7
set_location_assignment VGA_VS -to PIN_D8
set_location_assignment TD_RESET -to PIN_C4
set_location_assignment VGA_SYNC -to PIN_B7

set_io_assignment 8 -name OUTPUT_PIN_LOAD -io_standard LVTTL

set_location_assignment CLK_AUX -to PIN_D13