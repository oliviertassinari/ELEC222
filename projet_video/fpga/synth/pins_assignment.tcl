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
set_location_assignment PIN_C8 -to VGA_R[0]
set_location_assignment PIN_F10 -to VGA_R[1]
set_location_assignment PIN_G10 -to VGA_R[2]
set_location_assignment PIN_D9 -to VGA_R[3]
set_location_assignment PIN_C9 -to VGA_R[4]
set_location_assignment PIN_A8 -to VGA_R[5]
set_location_assignment PIN_H11 -to VGA_R[6]
set_location_assignment PIN_H12 -to VGA_R[7]
set_location_assignment PIN_F11 -to VGA_R[8]
set_location_assignment PIN_E10 -to VGA_R[9]
set_location_assignment PIN_B9 -to VGA_G[0]
set_location_assignment PIN_A9 -to VGA_G[1]
set_location_assignment PIN_C10 -to VGA_G[2]
set_location_assignment PIN_D10 -to VGA_G[3]
set_location_assignment PIN_B10 -to VGA_G[4]
set_location_assignment PIN_A10 -to VGA_G[5]
set_location_assignment PIN_G11 -to VGA_G[6]
set_location_assignment PIN_D11 -to VGA_G[7]
set_location_assignment PIN_E12 -to VGA_G[8]
set_location_assignment PIN_D12 -to VGA_G[9]
set_location_assignment PIN_J13 -to VGA_B[0]
set_location_assignment PIN_J14 -to VGA_B[1]
set_location_assignment PIN_F12 -to VGA_B[2]
set_location_assignment PIN_G12 -to VGA_B[3]
set_location_assignment PIN_J10 -to VGA_B[4]
set_location_assignment PIN_J11 -to VGA_B[5]
set_location_assignment PIN_C11 -to VGA_B[6]
set_location_assignment PIN_B11 -to VGA_B[7]
set_location_assignment PIN_C12 -to VGA_B[8]
set_location_assignment PIN_B12 -to VGA_B[9]
set_location_assignment PIN_B8 -to VGA_CLK
set_location_assignment PIN_D6 -to VGA_BLANK
set_location_assignment PIN_A7 -to VGA_HS
set_location_assignment PIN_D8 -to VGA_VS
set_location_assignment PIN_C4 -to TD_RESET
set_location_assignment PIN_B7 -to VGA_SYNC

set_io_assignment 8 -name OUTPUT_PIN_LOAD -io_standard LVTTL

set_location_assignment PIN_D13 -to CLK_AUX