#!/bin/sh
#
# run_panamax_extract.sh --
#
#	Generate extracted SPICE netlist from the layout
#
#	Run this in the mag/ directory
#
export PDK_ROOT=/usr/share/pdk
export PDK=sky130A

magic -dnull -noconsole -rcfile ${PDKROOT}/${PDK}/libs.tech/magic/${PDK}.magicrc << EOF
load panamax
select top cell
expand
extract path extfiles
extract no all
extract all
ext2spice lvs
ext2spice -p extfiles
EOF
rm -r extfiles
mv panamax.spice ../netlist/layout/
exit 0
