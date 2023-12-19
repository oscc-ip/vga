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

module axi4_vga (
    apb4_if.slave  apb4,
    axi4_if.master axi4,
    vga_if.dut     vga
);

  logic [3:0] s_apb4_addr;
  logic [`VGA_CTRL_WIDTH-1:0] s_vga_ctrl_d, s_vga_ctrl_q;
  logic [`VGA_HVSIZE_WIDTH-1:0] s_vga_hvsize_d, s_vga_hvsize_q;
  logic [`VGA_HFPSIZE_WIDTH-1:0] s_vga_hfpsize_d, s_vga_hfpsize_q;
  logic [`VGA_HSNSIZE_WIDTH-1:0] s_vga_hsnsize_d, s_vga_hsnsize_q;
  logic [`VGA_HBPSIZE_WIDTH-1:0] s_vga_hbpsize_d, s_vga_hbpsize_q;
  logic [`VGA_VVSIZE_WIDTH-1:0] s_vga_vvsize_d, s_vga_vvsize_q;
  logic [`VGA_VFPSIZE_WIDTH-1:0] s_vga_vfpsize_d, s_vga_vfpsize_q;
  logic [`VGA_VSNSIZE_WIDTH-1:0] s_vga_vsnsize_d, s_vga_vsnsize_q;
  logic [`VGA_VBPSIZE_WIDTH-1:0] s_vga_vbpsize_d, s_vga_vbpsize_q;
  logic [`VGA_FBSTART_WIDTH-1:0] s_vga_fbstart_d, s_vga_fbstart_q;
  logic [`VGA_FBSIZE_WIDTH-1:0] s_vga_fbsize_d, s_vga_fbsize_q;

  assign s_apb4_addr = apb4.paddr[5:2];
  assign s_apb4_wr_hdshk = apb4.psel && apb4.penable && apb4.pwrite;
  assign s_apb4_rd_hdshk = apb4.psel && apb4.penable && (~apb4.pwrite);
  assign apb4.pready = 1'b1;
  assign apb4.pslverr = 1'b0;


  assign s_vga_ctrl_d = (s_apb4_wr_hdshk && s_apb4_addr == `VGA_CTRL) ? apb4.pwdata[`VGA_CTRL_WIDTH-1:0] : s_vga_ctrl_q;
  dffr #(`VGA_CTRL_WIDTH) u_vga_ctrl_dffr (
      apb4.pclk,
      apb4.presetn,
      s_vga_ctrl_d,
      s_vga_ctrl_q
  );

  assign s_vga_hvsize_d = (s_apb4_wr_hdshk && s_apb4_addr == `VGA_HVSIZE) ? apb4.pwdata[`VGA_HVSIZE_WIDTH-1:0] : s_vga_hvsize_q;
  dffr #(`VGA_HVSIZE_WIDTH) u_vga_hvsize_dffr (
      apb4.pclk,
      apb4.presetn,
      s_vga_hvsize_d,
      s_vga_hvsize_q
  );

  assign s_vga_hfpsize_d = (s_apb4_wr_hdshk && s_apb4_addr == `VGA_HFPSIZE) ? apb4.pwdata[`VGA_HFPSIZE_WIDTH-1:0] : s_vga_hfpsize_q;
  dffr #(`VGA_HFPSIZE_WIDTH) u_vga_hfpsize_dffr (
      apb4.pclk,
      apb4.presetn,
      s_vga_hfpsize_d,
      s_vga_hfpsize_q
  );

  assign s_vga_hsnsize_d = (s_apb4_wr_hdshk && s_apb4_addr == `VGA_HSNSIZE) ? apb4.pwdata[`VGA_HSNSIZE_WIDTH-1:0] : s_vga_hsnsize_q;
  dffr #(`VGA_HSNSIZE_WIDTH) u_vga_hsnsize_dffr (
      apb4.pclk,
      apb4.presetn,
      s_vga_hsnsize_d,
      s_vga_hsnsize_q
  );

  assign s_vga_hbpsize_d = (s_apb4_wr_hdshk && s_apb4_addr == `VGA_HBPSIZE) ? apb4.pwdata[`VGA_HBPSIZE_WIDTH-1:0] : s_vga_hbpsize_q;
  dffr #(`VGA_HBPSIZE_WIDTH) u_vga_hbpsize_dffr (
      apb4.pclk,
      apb4.presetn,
      s_vga_hbpsize_d,
      s_vga_hbpsize_q
  );

  assign s_vga_vvsize_d = (s_apb4_wr_hdshk && s_apb4_addr == `VGA_VVSIZE) ? apb4.pwdata[`VGA_VVSIZE_WIDTH-1:0] : s_vga_vvsize_q;
  dffr #(`VGA_VVSIZE_WIDTH) u_vga_vvsize_dffr (
      apb4.pclk,
      apb4.presetn,
      s_vga_vvsize_d,
      s_vga_vvsize_q
  );

  assign s_vga_vfpsize_d = (s_apb4_wr_hdshk && s_apb4_addr == `VGA_VFPSIZE) ? apb4.pwdata[`VGA_VFPSIZE_WIDTH-1:0] : s_vga_vfpsize_q;
  dffr #(`VGA_VFPSIZE_WIDTH) u_vga_vfpsize_dffr (
      apb4.pclk,
      apb4.presetn,
      s_vga_vfpsize_d,
      s_vga_vfpsize_q
  );


  assign s_vga_vsnsize_d = (s_apb4_wr_hdshk && s_apb4_addr == `VGA_VSNSIZE) ? apb4.pwdata[`VGA_VSNSIZE_WIDTH-1:0] : s_vga_vsnsize_q;
  dffr #(`VGA_VSNSIZE_WIDTH) u_vga_vsnsize_dffr (
      apb4.pclk,
      apb4.presetn,
      s_vga_vsnsize_d,
      s_vga_vsnsize_q
  );

  assign s_vga_vbpsize_d = (s_apb4_wr_hdshk && s_apb4_addr == `VGA_VBPSIZE) ? apb4.pwdata[`VGA_VBPSIZE_WIDTH-1:0] : s_vga_vbpsize_q;
  dffr #(`VGA_VBPSIZE_WIDTH) u_vga_vbpsize_dffr (
      apb4.pclk,
      apb4.presetn,
      s_vga_vbpsize_d,
      s_vga_vbpsize_q
  );

  assign s_vga_fbstart_d = (s_apb4_wr_hdshk && s_apb4_addr == `VGA_FBSTART) ? apb4.pwdata[`VGA_FBSTART_WIDTH-1:0] : s_vga_fbstart_q;
  dffr #(`VGA_FBSTART_WIDTH) u_vga_fbstart_dffr (
      apb4.pclk,
      apb4.presetn,
      s_vga_fbstart_d,
      s_vga_fbstart_q
  );

  assign s_vga_fbsize_d = (s_apb4_wr_hdshk && s_apb4_addr == `VGA_FBSIZE) ? apb4.pwdata[`VGA_FBSIZE_WIDTH-1:0] : s_vga_fbsize_q;
  dffr #(`VGA_FBSIZE_WIDTH) u_vga_fbsize_dffr (
      apb4.pclk,
      apb4.presetn,
      s_vga_fbsize_d,
      s_vga_fbsize_q
  );

  always_comb begin
    apb4.prdata = '0;
    if (s_apb4_rd_hdshk) begin
      unique case (s_apb4_addr)
        `VGA_CTRL:    apb4.prdata[`VGA_CTRL_WIDTH-1:0] = s_vga_ctrl_q;
        `VGA_HVSIZE:  apb4.prdata[`VGA_HVSIZE_WIDTH-1:0] = s_vga_hvsize_q;
        `VGA_HFPSIZE: apb4.prdata[`VGA_HFPSIZE_WIDTH-1:0] = s_vga_hfpsize_q;
        `VGA_HSNSIZE: apb4.prdata[`VGA_HSNSIZE_WIDTH-1:0] = s_vga_hsnsize_q;
        `VGA_HBPSIZE: apb4.prdata[`VGA_HBPSIZE_WIDTH-1:0] = s_vga_hbpsize_q;
        `VGA_VVSIZE:  apb4.prdata[`VGA_VVSIZE_WIDTH-1:0] = s_vga_vvsize_q;
        `VGA_VFPSIZE: apb4.prdata[`VGA_VFPSIZE_WIDTH-1:0] = s_vga_vfpsize_q;
        `VGA_VSNSIZE: apb4.prdata[`VGA_VSNSIZE_WIDTH-1:0] = s_vga_vsnsize_q;
        `VGA_VBPSIZE: apb4.prdata[`VGA_VBPSIZE_WIDTH-1:0] = s_vga_vbpsize_q;
        `VGA_FBSTART: apb4.prdata[`VGA_FBSTART_WIDTH-1:0] = s_vga_fbstart_q;
        `VGA_FBSIZE:  apb4.prdata[`VGA_FBSIZE_WIDTH-1:0] = s_vga_fbsize_q;
        default:      apb4.prdata = '0;
      endcase
    end
  end

  
endmodule
