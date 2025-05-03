// SPDX-FileCopyrightText: 2020 Efabless Corporation
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// SPDX-License-Identifier: Apache-2.0

// Module xres_lvlshift is a level-shift buffer between the xres pad (used
// for digital reset, the RESETB pin) and the frigate chip core.  The xres
// pad output is in the 3.3V domain while the signal goes to the digital
// circuitry in the 1.8V domain.

module xres_lvlshift (
`ifdef USE_POWER_PINS
	inout wire VPWR,
	inout wire VGND,
	inout wire LVPWR,
	inout wire LVGND,
`endif
	output wire X,
	input wire A
);

    sky130_fd_sc_hvl__lsbufhv2lv_1 lvlshiftdown (
    `ifdef USE_POWER_PINS
	.VPWR(VPWR),
	.VPB(VPWR),
	.LVPWR(LVPWR),
	.VNB(VGND),
	.VGND(VGND),
    `endif
	.A(A),
	.X(X)
    );

    sky130_fd_sc_hvl__diode_2 ANTENNA_lvlshiftdown_A (
    `ifdef USE_POWER_PINS
	.VPWR(VPWR),
	.VPB(VPWR),
	.VNB(VGND),
	.VGND(VGND),
    `endif
	.DIODE(A)
    );

    sky130_fd_sc_hvl__decap_8 FILLER_8 [4:0] (
    `ifdef USE_POWER_PINS
	.VPWR(VPWR),
	.VPB(VPWR),
	.VNB(VGND),
	.VGND(VGND)
    `endif
    );

    sky130_fd_sc_hvl__decap_4 FILLER_4 [1:0] (
    `ifdef USE_POWER_PINS
	.VPWR(VPWR),
	.VPB(VPWR),
	.VNB(VGND),
	.VGND(VGND)
    `endif
    );

endmodule
