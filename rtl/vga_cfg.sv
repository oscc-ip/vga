// Copyright (c) 2023 Beijing Institute of Open Source Chip
// vga is licensed under Mulan PSL v2.
// You can use this software according to the terms and conditions of the Mulan PSL v2.
// You may obtain a copy of Mulan PSL v2 at:
//             http://license.coscl.org.cn/MulanPSL2
// THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
// EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
// MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
// See the Mulan PSL v2 for more details.

`include "register.sv"
`include "vga_define.sv"

module vga_cfg (
    apb4_if.slave apb4
);

  logic [3:0] s_apb4_addr;
  logic [`VGA_CTRL_WIDTH-1:0] s_vga_ctrl_d, s_vga_ctrl_q;
  logic s_vga_ctrl_en;
  logic [`VGA_HVVL_WIDTH-1:0] s_vga_hvvl_d, s_vga_hvvl_q;
  logic s_vga_hvvl_en;
  logic [`VGA_HTIM_WIDTH-1:0] s_vga_htim_d, s_vga_htim_q;
  logic s_vga_htim_en;
  logic [`VGA_VTIM_WIDTH-1:0] s_vga_vtim_d, s_vga_vtim_q;
  logic s_vga_vtim_en;
  logic [`VGA_FBBA1_WIDTH-1:0] s_vga_fbba1_d, s_vga_fbba1_q;
  logic s_vga_fbba1_en;
  logic [`VGA_FBBA2_WIDTH-1:0] s_vga_fbba2_d, s_vga_fbba2_q;
  logic s_vga_fbba2_en;
  logic [`VGA_STAT_WIDTH-1:0] s_vga_stat_d, s_vga_stat_q;

  logic s_bit_en, s_bit_hie, s_bit_vie, s_bit_vbsie, s_bit_vbse;
  logic s_bit_blpol, s_bit_hspol, s_bit_vspol, s_bit_test;
  logic [1:0] s_bit_mode;
  logic [7:0] s_bit_div, s_bit_brulen;
  logic [`VGA_VB_WIDTH-1:0] s_bit_hvlen, s_bit_vvlen;
  logic [`VGA_TB_WIDTH-1:0] s_bit_hfpsize, s_bit_hsnsize, s_bit_hbpsize;
  logic [`VGA_TB_WIDTH-1:0] s_bit_vfpsize, s_bit_vsnsize, s_bit_vbpsize;

  assign s_apb4_addr     = apb4.paddr[5:2];
  assign s_apb4_wr_hdshk = apb4.psel && apb4.penable && apb4.pwrite;
  assign s_apb4_rd_hdshk = apb4.psel && apb4.penable && (~apb4.pwrite);
  assign apb4.pready     = 1'b1;
  assign apb4.pslverr    = 1'b0;

  assign s_bit_en        = s_vga_ctrl_q[0];
  assign s_bit_hie       = s_vga_ctrl_q[1];
  assign s_bit_vie       = s_vga_ctrl_q[2];
  assign s_bit_vbsie     = s_vga_ctrl_q[3];
  assign s_bit_vbse      = s_vga_ctrl_q[4];
  assign s_bit_blpol     = s_vga_ctrl_q[5];
  assign s_bit_hspol     = s_vga_ctrl_q[6];
  assign s_bit_vspol     = s_vga_ctrl_q[7];
  assign s_bit_div       = s_vga_ctrl_q[15:8];
  assign s_bit_test      = s_vga_ctrl_q[16];
  assign s_bit_mode      = s_vga_ctrl_q[18:17];
  assign s_bit_brulen    = s_vga_ctrl_q[26:19];
  assign s_bit_hvlen     = s_vga_hvvl_q[`VGA_VB_WIDTH-1:0];
  assign s_bit_vvlen     = s_vga_hvvl_q[31:`VGA_VB_WIDTH];
  assign s_bit_hfpsize   = s_vga_htim_q[`VGA_TB_WIDTH-1:0];
  assign s_bit_hsnsize   = s_vga_htim_q[2*`VGA_TB_WIDTH-1:`VGA_TB_WIDTH];
  assign s_bit_hbpsize   = s_vga_htim_q[3*`VGA_TB_WIDTH-1:2*`VGA_TB_WIDTH];
  assign s_bit_vfpsize   = s_vga_vtim_q[`VGA_TB_WIDTH-1:0];
  assign s_bit_vsnsize   = s_vga_vtim_q[2*`VGA_TB_WIDTH-1:`VGA_TB_WIDTH];
  assign s_bit_vbpsize   = s_vga_vtim_q[3*`VGA_TB_WIDTH-1:2*`VGA_TB_WIDTH];

  assign s_vga_ctrl_en   = s_apb4_wr_hdshk && s_apb4_addr == `VGA_CTRL;
  assign s_vga_ctrl_d    = apb4.pwdata[`VGA_CTRL_WIDTH-1:0];
  dffer #(`VGA_CTRL_WIDTH) u_vga_ctrl_dffr (
      apb4.pclk,
      apb4.presetn,
      s_vga_ctrl_en,
      s_vga_ctrl_d,
      s_vga_ctrl_q
  );

  assign s_vga_hvvl_en = s_apb4_wr_hdshk && s_apb4_addr == `VGA_HVVL;
  assign s_vga_hvvl_d  = apb4.pwdata[`VGA_HVVL_WIDTH-1:0];
  dffer #(`VGA_HVVL_WIDTH) u_vga_hvvl_dffr (
      apb4.pclk,
      apb4.presetn,
      s_vga_hvvl_en,
      s_vga_hvvl_d,
      s_vga_hvvl_q
  );


  assign s_vga_htim_en = s_apb4_wr_hdshk && s_apb4_addr == `VGA_HTIM;
  assign s_vga_htim_d  = apb4.pwdata[`VGA_HTIM_WIDTH-1:0];
  dffer #(`VGA_HTIM_WIDTH) u_vga_htim_dffr (
      apb4.pclk,
      apb4.presetn,
      s_vga_htim_en,
      s_vga_htim_d,
      s_vga_htim_q
  );

  assign s_vga_vtim_en = s_apb4_wr_hdshk && s_apb4_addr == `VGA_VTIM;
  assign s_vga_vtim_d  = apb4.pwdata[`VGA_VTIM_WIDTH-1:0];
  dffer #(`VGA_VTIM_WIDTH) u_vga_vtim_dffr (
      apb4.pclk,
      apb4.presetn,
      s_vga_vtim_en,
      s_vga_vtim_d,
      s_vga_vtim_q
  );

  assign s_vga_fbba1_en = s_apb4_wr_hdshk && s_apb4_addr == `VGA_FBBA1;
  assign s_vga_fbba1_d  = apb4.pwdata[`VGA_FBBA1_WIDTH-1:0];
  dffer #(`VGA_FBBA1_WIDTH) u_vga_fbba1_dffr (
      apb4.pclk,
      apb4.presetn,
      s_vga_fbba1_en,
      s_vga_fbba1_d,
      s_vga_fbba1_q
  );

  assign s_vga_fbba2_en = s_apb4_wr_hdshk && s_apb4_addr == `VGA_FBBA2;
  assign s_vga_fbba2_d  = apb4.pwdata[`VGA_FBBA2_WIDTH-1:0];
  dffer #(`VGA_FBBA2_WIDTH) u_vga_fbba2_dffr (
      apb4.pclk,
      apb4.presetn,
      s_vga_fbba2_en,
      s_vga_fbba2_d,
      s_vga_fbba2_q
  );

  always_comb begin
    apb4.prdata = '0;
    if (s_apb4_rd_hdshk) begin
      unique case (s_apb4_addr)
        `VGA_CTRL:  apb4.prdata[`VGA_CTRL_WIDTH-1:0] = s_vga_ctrl_q;
        `VGA_HVVL:  apb4.prdata[`VGA_HVVL_WIDTH-1:0] = s_vga_hvvl_q;
        `VGA_HTIM:  apb4.prdata[`VGA_HTIM_WIDTH-1:0] = s_vga_htim_q;
        `VGA_VTIM:  apb4.prdata[`VGA_VTIM_WIDTH-1:0] = s_vga_vtim_q;
        `VGA_FBBA1: apb4.prdata[`VGA_FBBA1_WIDTH-1:0] = s_vga_fbba1_q;
        `VGA_FBBA2: apb4.prdata[`VGA_FBBA2_WIDTH-1:0] = s_vga_fbba2_q;
        default:    apb4.prdata = '0;
      endcase
    end
  end

endmodule
