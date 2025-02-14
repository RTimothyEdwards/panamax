#!/bin/bash

#-------------------------------------------------------------------
# panamax_prep.sh --
#
# Prepare the GDS, LEF, and DEF views of panamax
# (the caravel panamax padframes)
#
# Run this from the caravel/mag/ directory after modifying the
# magic layout.
#
# Written by Tim Edwards for Fregate Panamax
# Updated 1/25/2024
# Updated 2/14/2025 for the open source Frigate harness chip
#-------------------------------------------------------------------

echo ${PDK_ROOT:=/usr/share/pdk} > /dev/null
echo ${PDK:=sky130A} > /dev/null

# Generate DEF of panamax
echo "Generating DEF view of panamax"
magic -dnull -noconsole -rcfile ${PDK_ROOT}/${PDK}/libs.tech/magic/${PDK}.magicrc << EOF
load panamax
select top cell
expand
property flatten true
flatten -doproperty panamax_flat
load panamax_flat
cellname delete panamax
cellname rename panamax_flat panamax
select top cell
extract do local
extract no all
extract all
# Declare all signals to be SPECIALNETS
set globals(vccd0) 1
set globals(vssd0) 1
set globals(vddio) 1
set globals(vssio) 1
set globals(vdda0) 1
set globals(vssa0) 1
set globals(vdda1) 1
set globals(vssa1) 1
set globals(vccd1) 1
set globals(vssd1) 1
set globals(vdda2) 1
set globals(vssa2) 1
set globals(vdda3) 1
set globals(vssa3) 1
set globals(vccd2) 1
set globals(vssd2) 1
def write panamax -units 400
quit -noprompt
EOF

rm *.ext

# Generate GDS of panamax
echo "Generating GDS view of panamax"
magic -dnull -noconsole -rcfile ${PDK_ROOT}/${PDK}/libs.tech/magic/${PDK}.magicrc << EOF
load panamax -dereference
gds compress 9
cif *hier write disable
cif *array write disable
gds write panamax
quit -noprompt
EOF

# Generate LEF of panamax
# NOTE:  Using MAGTYPE=maglef so that each PDK subcell is already
# an abstract view;  this results in a LEF file similar to what would
# be output by "lef write -hide" but dealing appropriately with the
# torus shape of the padframe.
echo "Generating LEF view of panamax"
export MAGTYPE=maglef
magic -dnull -noconsole -rcfile ${PDK_ROOT}/${PDK}/libs.tech/magic/${PDK}.magicrc << EOF
load panamax -dereference
select top cell
lef write
quit -noprompt
EOF

# Move all generated files to their proper locations

echo "Moving generated files to destination directories"
# mv panamax.lef ../lef
# mv panamax.def ../def
# mv panamax.gds.gz ../gds

echo "Done!"
