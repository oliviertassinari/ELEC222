#**************************************************************
# Time Information
#**************************************************************

set_time_format -unit ns -decimal_places 1


#**************************************************************
# Create Clocks
#**************************************************************

# L'horloge externe à 50Mhz
create_clock -name {CLK} -period 20.0 -waveform { 0.0 10.0 } [get_ports {CLK}]

# -----------------------------------------------------------------
# Cut timing paths
# -----------------------------------------------------------------
#
# The timing for the I/Os in this design is arbitrary, so cut all
# paths to the I/Os, even the ones that are used in the design,
# i.e., the LEDs, switches, and hex displays.
#

# Les entrées manuelles
set_false_path -from [get_ports NRST] -to *
set_false_path -from [get_ports SW] -to *

# Les afficheurs
set_false_path -from * -to [get_ports {LED_*}]

# Ajout automatique des contraintes pour les PLL et les autres horloges dérivées
derive_pll_clocks -create_base_clocks