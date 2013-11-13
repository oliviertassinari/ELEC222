## Get files from env
set HDL_FILES [split $env(SOURCE_FILES)]
set TOP_MODULE $env(TOP_MODULE)

# Define a project
new_project -name $TOP_MODULE -folder . -createimpl_name $TOP_MODULE -force

source "global.tcl"

## Add design files
add_input_file -work work $HDL_FILES
## Set TOP LEVEL module
setup_design -design $TOP_MODULE

# Compile/Synthesize
compile
synthesize

# Save project and exit
save_impl
save_project

# if you run this script in batch
# close_project
# exit -f

