# SPDX-FileCopyrightText: 2020 Efabless Corporation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# SPDX-License-Identifier: Apache-2.0
#
# LVS the entire Caravel Panamax pad frame (panamax)
#
# Run this with "netgen -batch source lvs_panamax.tcl"

if {[catch {set PDK_PATH $::env(PDK_PATH)}]} {
    set PDK_PATH /usr/share/pdk
}
if {[catch {set PDK $::env(PDK)}]} {
    set PDK sky130A
}

set circuit1 [readnet spice ../netlist/layout/panamax.spice]

# This forces the verilog to be treated as case-insensitive, since the
# SPICE files attached to the netlist will be case-insensitive.
set circuit2 [readnet spice /dev/null]
readnet verilog ../verilog/rtl/panamax.v $circuit2

# Read base libraries
readnet spice ${PDK_PATH}/${PDK}/libs.ref/sky130_fd_io/spice/sky130_fd_io.spice $circuit2
# readnet spice ${PDK_PATH}/${PDK}/libs.ref/sky130_fd_io/spice/sky130_ef_io_analog.spice $circuit2
readnet spice ${PDK_PATH}/${PDK}/libs.ref/sky130_fd_sc_hd/spice/sky130_fd_sc_hd.spice $circuit2

lvs "$circuit1 panamax" "$circuit2 panamax" ${PDK_PATH}/${PDK}/libs.tech/netgen/sky130A_setup.tcl panamax_comp.out
