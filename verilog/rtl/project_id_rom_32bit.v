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

`default_nettype none
// This module represents an unprogrammed project ID
// block that is configured with via programming on the
// chip top level.  This value is passed to the block as
// a parameter

/// sta-blackbox
module project_id_rom_32bit #(
    parameter PROJECT_ID = 32'h0
) (
`ifdef USE_POWER_PINS
    inout VPWR,
    inout VGND,
`endif
    output [31:0] project_id
);
    wire [31:0] proj_id_high;
    wire [31:0] proj_id_low;

    // For the project ID input, use an array of digital constant logic cells

    sky130_fd_sc_hd__conb_1 project_id_value [31:0] (
`ifdef USE_POWER_PINS
            .VPWR(VPWR),
            .VPB(VPWR),
            .VNB(VGND),
            .VGND(VGND),
`endif
            .HI(proj_id_high),
            .LO(proj_id_low)
    );

    genvar i;
    generate
	for (i = 0; i < 32; i = i+1) begin
	    assign project_id[i] = (PROJECT_ID & (32'h01 << i)) ?
			proj_id_high[i] : proj_id_low[i];
	end
    endgenerate

    // Note the number and size of decap cells

    sky130_fd_sc_hd__decap_12 FILLER_12 [2:0] (
`ifdef USE_POWER_PINS
            .VPWR(VPWR),
            .VPB(VPWR),
            .VNB(VGND),
            .VGND(VGND)
`endif
    );

    sky130_fd_sc_hd__decap_6 FILLER_6 (
`ifdef USE_POWER_PINS
            .VPWR(VPWR),
            .VPB(VPWR),
            .VNB(VGND),
            .VGND(VGND)
`endif
    );

    sky130_fd_sc_hd__decap_4 FILLER_4 [1:0] (
`ifdef USE_POWER_PINS
            .VPWR(VPWR),
            .VPB(VPWR),
            .VNB(VGND),
            .VGND(VGND)
`endif
    );

    sky130_fd_sc_hd__decap_3 FILLER_3 [5:0] (
`ifdef USE_POWER_PINS
            .VPWR(VPWR),
            .VPB(VPWR),
            .VNB(VGND),
            .VGND(VGND)
`endif
    );

endmodule
`default_nettype wire
