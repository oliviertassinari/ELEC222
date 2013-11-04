# Contraintes globales du projet
# Ici on autorise l'outil à optimiser les recompilations lorsqu'on
# a juste modifié quelques lignes dans les sources existants...
set_global_assignment -name AUTO_ENABLE_SMART_COMPILE ON
set_global_assignment -name SMART_RECOMPILE ON
set_global_assignment -name INCREMENTAL_COMPILATION INCREMENTAL_SYNTHESIS
set_global_assignment -name INCREMENTAL_COMPILATION FULL_INCREMENTAL_COMPILATION
# je ne sais pas si c'est vraiment utile...:w
set_global_assignment -name EDA_DESIGN_ENTRY_SYNTHESIS_TOOL "<None>"

