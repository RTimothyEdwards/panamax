#!/bin/sh
#
# Generate a DEF file of the padframe
# Run this script from the ../mag directory
#
# Specific actions critical for this to work:
# 1. Each subcell that should be in the DEF file as a route and not as a component
#    should be given the property "flatten" with value "true".  These properties may
#    be saved in the subcell.
# 2. The top cell should also be given the property "flatten" with value "true".
# 3. The top cell should be completely expanded before issuing the "flatten"
#    command.
# 4. The "flatten" command should use the "-doproperty" command.
#
# These steps ensure that the connecting wires between the padframe core-facing pins
# and the pad cells are represented as routes in the DEF file.

export PDK_ROOT=/usr/share/pdk
export PDK=sky130A

magic -dnull -noconsole -rcfile ${PDKROOT}/${PDK}/libs.tech/magic/${PDK}.magicrc << EOF
drc off
crashbackups stop
load panamax
select top cell
expand
property flatten true
flatten -doproperty panamax_flat
load panamax_flat
cellname delete panamax
cellname rename panamax_flat panamax
extract no all
extract all
def write panamax -units 400
quit -noprompt
EOF

mv panamax.def ../def/
rm *.ext
echo "Done!"
exit 0
