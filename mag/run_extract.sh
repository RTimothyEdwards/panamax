#! /bin/bash

project=panamax

echo ${PDK_ROOT:=/usr/share/pdk} > /dev/null
echo ${PDK:=sky130A} > /dev/null

magic -dnull -noconsole -rcfile \$PDK_ROOT/\$PDK/libs.tech/magic/sky130A.magicrc << EOF
load $project
#
# NOTE:  Replace newest padframe cells with abstract views for this extraction.
#
# Update: As of Feb. 2025, all cells except for SIO and GPIO OVTv2 will pass LVS,
# so only those two are abstracted away.
#
cellname filepath sky130_fd_io__top_sio_macro \$PDKPATH/libs.ref/sky130_fd_io/maglef
flush sky130_fd_io__top_sio_macro
cellname filepath sky130_fd_io__top_gpio_ovtv2 \$PDKPATH/libs.ref/sky130_fd_io/maglef
flush sky130_fd_io__top_gpio_ovtv2
#
# cellname filepath sky130_fd_io__top_pwrdetv2 \$PDKPATH/libs.ref/sky130_fd_io/maglef
# flush sky130_fd_io__top_pwrdetv2
# cellname filepath sky130_fd_io__top_amuxsplitv2 \$PDKPATH/libs.ref/sky130_fd_io/maglef
# flush sky130_fd_io__top_amuxsplitv2
# cellname filepath sky130_fd_io__top_vrefcapv2 \$PDKPATH/libs.ref/sky130_fd_io/maglef
# flush sky130_fd_io__top_vrefcapv2
# cellname filepath sky130_fd_io__top_analog_pad \$PDKPATH/libs.ref/sky130_fd_io/maglef
# flush sky130_fd_io__top_analog_pad
#
# Now back to the project
select top cell
extract path extfiles
# Avoid "extract unique" because so many I/O cells have redundant pins
# extract unique
# Do not do parasitic extraction here. . .
extract no all
extract all
ext2spice lvs
ext2spice -p extfiles -o ../netlist/layout/$project.spice
quit -noprompt
EOF
rm -r extfiles
exit 0

