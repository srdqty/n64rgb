//////////////////////////////////////////////////////////////////////////////////
//
// This file is part of the N64 RGB/YPbPr DAC project.
//
// Copyright (C) 2016-2018 by Peter Bartmann <borti4938@gmx.de>
//
// N64 RGB/YPbPr DAC is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
//
//////////////////////////////////////////////////////////////////////////////////
//
// Company:  Circuit-Board.de
// Engineer: borti4938
//
// Module Name:    n64_vdemux
// Project Name:   N64 RGB DAC Mod
// Target Devices: universial
// Tool versions:  Altera Quartus Prime
// Description:    demux the video data from the input data stream
//
// Dependencies: vh/n64rgb_params.vh
//
// Revision: 1.0
//
///////////////////////////////////////////////////////////////////////////////////////////


module n64_vdemux(
  nCLK,
  nDSYNC,

  D_i,
  demuxparams_i,

  vdata_r_0,
  vdata_r_1
);

`include "vh/n64rgb_params.vh"

input nCLK;
input nDSYNC;

input  [color_width-1:0] D_i;
input              [4:0] demuxparams_i;

output reg [`VDATA_FU_SLICE] vdata_r_0; // buffer for sync, red, green and blue
output reg [`VDATA_FU_SLICE] vdata_r_1; // (unpacked array types in ports requires system verilog)


// unpack deblur info

wire [1:0] data_cnt  = demuxparams_i[4:3];
wire ndo_deblur      = demuxparams_i[  2];
wire nblank_rgb      = demuxparams_i[  1];
reg  n15bit_mode; // = demuxparams_i[  0] (updated each frame)

// start of rtl


`ifdef DEBUG
  reg [3:0] S_DBr[1:5];
`endif


always @(negedge nCLK) begin // data register management
  if (~nDSYNC) begin
    if (vdata_r_0[vdata_width-1] & ~D_i[3]) // negedge at nVSYNC detected - new frame, new setting for 15bit mode
      n15bit_mode <= demuxparams_i[0];
    // shift data to output registers
    if(ndo_deblur)        // deblur inactive
      vdata_r_1[`VDATA_SY_SLICE] <= vdata_r_0[`VDATA_SY_SLICE];
    if (nblank_rgb)  // deblur active: pass RGB only if not blanked
      vdata_r_1[`VDATA_CO_SLICE] <= vdata_r_0[`VDATA_CO_SLICE];

    // get new sync data
    vdata_r_0[`VDATA_SY_SLICE] <= D_i[3:0];
  end else begin
    // demux of RGB
    case(data_cnt)
      2'b01: vdata_r_0[`VDATA_RE_SLICE] <= n15bit_mode ? D_i : {D_i[6:2], 2'b00};
      2'b10: begin
        vdata_r_0[`VDATA_GR_SLICE] <= n15bit_mode ? D_i : {D_i[6:2], 2'b00};
        if(~ndo_deblur)
          vdata_r_1[`VDATA_SY_SLICE] <= vdata_r_0[`VDATA_SY_SLICE];
      end
      2'b11: vdata_r_0[`VDATA_BL_SLICE] <= n15bit_mode ? D_i : {D_i[6:2], 2'b00};
    endcase
  end
end

endmodule