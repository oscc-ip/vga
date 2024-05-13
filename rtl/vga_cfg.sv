/////////////////////////////////////////////////////////////////////
////                                                             ////
////  WISHBONE rev.B2 compliant enhanced VGA/LCD Core            ////
////  Wishbone slave interface                                   ////
////                                                             ////
////  Author: Richard Herveille                                  ////
////          richard@asics.ws                                   ////
////          www.asics.ws                                       ////
////                                                             ////
////  Downloaded from: http://www.opencores.org/projects/vga_lcd ////
////                                                             ////
/////////////////////////////////////////////////////////////////////
////                                                             ////
//// Copyright (C) 2001, 2002 Richard Herveille                  ////
////                    richard@asics.ws                         ////
////                                                             ////
//// This source file may be used and distributed without        ////
//// restriction provided that this copyright statement is not   ////
//// removed from the file and that any derivative work contains ////
//// the original copyright notice and the associated disclaimer.////
////                                                             ////
////     THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY     ////
//// EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED   ////
//// TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS   ////
//// FOR A PARTICULAR PURPOSE. IN NO EVENT SHALL THE AUTHOR      ////
//// OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,         ////
//// INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES    ////
//// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE   ////
//// GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR        ////
//// BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF  ////
//// LIABILITY, WHETHER IN  CONTRACT, STRICT LIABILITY, OR TORT  ////
//// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT  ////
//// OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE         ////
//// POSSIBILITY OF SUCH DAMAGE.                                 ////
////                                                             ////
/////////////////////////////////////////////////////////////////////
//
// -- Adaptable modifications are redistributed under compatible License --
//
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
    apb4_if.slave apb4,

    output logic                         en_o,
    output logic                         hie_o,
    output logic                         vie_o,
    output logic                         vbsie_o,
    output logic                         vbse_o,
    output logic                         blpol_o,
    output logic                         hspol_o,
    output logic                         vspol_o,
    output logic                         test_o,
    output logic [                  1:0] mode_o,
    output logic [`VGA_BRULEN_WIDTH-1:0] brulen_o,
    output logic [    `VGA_VB_WIDTH-1:0] hvlen_o,
    output logic [    `VGA_VB_WIDTH-1:0] vvlen_o,
    output logic [    `VGA_TB_WIDTH-1:0] hfpsize_o,
    output logic [    `VGA_TB_WIDTH-1:0] hsnsize_o,
    output logic [    `VGA_TB_WIDTH-1:0] hbpsize_o,
    output logic [    `VGA_TB_WIDTH-1:0] vfpsize_o,
    output logic [    `VGA_TB_WIDTH-1:0] vsnsize_o,
    output logic [    `VGA_TB_WIDTH-1:0] vbpsize_o,
    output logic [                 31:0] fbba1_o,
    output logic [                 31:0] fbba2_o,
    input  logic                         cfb_i,
    input  logic                         vbsirq_i,
    input  logic                         verirq_i,
    input  logic                         horirq_i,
    output logic                         pclk_en_o,
    output logic                         irq_o
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
  // bit signal
  logic s_bit_en, s_bit_hie, s_bit_vie, s_bit_vbsie, s_bit_vbse;
  logic s_bit_blpol, s_bit_hspol, s_bit_vspol, s_bit_test;
  logic s_bit_hif, s_bit_vif, s_bit_vbsif, s_bit_cfb;
  logic [                  1:0] s_bit_mode;
  logic [   `VGA_DIV_WIDTH-1:0] s_bit_div;
  logic [`VGA_BRULEN_WIDTH-1:0] s_bit_brulen;
  logic [`VGA_VB_WIDTH-1:0] s_bit_hvlen, s_bit_vvlen;
  logic [`VGA_TB_WIDTH-1:0] s_bit_hfpsize, s_bit_hsnsize, s_bit_hbpsize;
  logic [`VGA_TB_WIDTH-1:0] s_bit_vfpsize, s_bit_vsnsize, s_bit_vbpsize;

  logic [`VGA_DIV_WIDTH-1:0] s_pclk_cnt_d, s_pclk_cnt_q, s_pclk_div;

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
  assign s_bit_hif       = s_vga_stat_q[0];
  assign s_bit_vif       = s_vga_stat_q[1];
  assign s_bit_vbsif     = s_vga_stat_q[2];
  assign s_bit_cfb       = s_vga_stat_q[3];

  assign en_o            = s_bit_en;
  assign hie_o           = s_bit_hie;
  assign vie_o           = s_bit_vie;
  assign vbsie_o         = s_bit_vbsie;
  assign vbse_o          = s_bit_vbse;
  assign blpol_o         = s_bit_blpol;
  assign hspol_o         = s_bit_hspol;
  assign vspol_o         = s_bit_vspol;
  assign div_o           = s_bit_div;
  assign test_o          = s_bit_test;
  assign mode_o          = s_bit_mode;
  assign brulen_o        = s_bit_brulen;
  assign hvlen_o         = s_bit_hvlen;
  assign vvlen_o         = s_bit_vvlen;
  assign hfpsize_o       = s_bit_hfpsize;
  assign hsnsize_o       = s_bit_hsnsize;
  assign hbpsize_o       = s_bit_hbpsize;
  assign vfpsize_o       = s_bit_vfpsize;
  assign vsnsize_o       = s_bit_vsnsize;
  assign vbpsize_o       = s_bit_vbpsize;
  assign pclk_en_o       = s_pclk_cnt_q == '0;
  assign irq_o           = (s_bit_hie & s_bit_hif) | (s_bit_vie & s_bit_vif);

  assign s_vga_ctrl_en   = s_apb4_wr_hdshk && s_apb4_addr == `VGA_CTRL;
  assign s_vga_ctrl_d    = apb4.pwdata[`VGA_CTRL_WIDTH-1:0];
  dffer #(`VGA_CTRL_WIDTH) u_vga_ctrl_dffer (
      apb4.pclk,
      apb4.presetn,
      s_vga_ctrl_en,
      s_vga_ctrl_d,
      s_vga_ctrl_q
  );

  assign s_vga_hvvl_en = s_apb4_wr_hdshk && s_apb4_addr == `VGA_HVVL;
  assign s_vga_hvvl_d  = apb4.pwdata[`VGA_HVVL_WIDTH-1:0];
  dffer #(`VGA_HVVL_WIDTH) u_vga_hvvl_dffer (
      apb4.pclk,
      apb4.presetn,
      s_vga_hvvl_en,
      s_vga_hvvl_d,
      s_vga_hvvl_q
  );


  assign s_vga_htim_en = s_apb4_wr_hdshk && s_apb4_addr == `VGA_HTIM;
  assign s_vga_htim_d  = apb4.pwdata[`VGA_HTIM_WIDTH-1:0];
  dffer #(`VGA_HTIM_WIDTH) u_vga_htim_dffer (
      apb4.pclk,
      apb4.presetn,
      s_vga_htim_en,
      s_vga_htim_d,
      s_vga_htim_q
  );

  assign s_vga_vtim_en = s_apb4_wr_hdshk && s_apb4_addr == `VGA_VTIM;
  assign s_vga_vtim_d  = apb4.pwdata[`VGA_VTIM_WIDTH-1:0];
  dffer #(`VGA_VTIM_WIDTH) u_vga_vtim_dffer (
      apb4.pclk,
      apb4.presetn,
      s_vga_vtim_en,
      s_vga_vtim_d,
      s_vga_vtim_q
  );

  assign s_vga_fbba1_en = s_apb4_wr_hdshk && s_apb4_addr == `VGA_FBBA1;
  assign s_vga_fbba1_d  = apb4.pwdata[`VGA_FBBA1_WIDTH-1:0];
  dffer #(`VGA_FBBA1_WIDTH) u_vga_fbba1_dffer (
      apb4.pclk,
      apb4.presetn,
      s_vga_fbba1_en,
      s_vga_fbba1_d,
      s_vga_fbba1_q
  );

  assign s_vga_fbba2_en = s_apb4_wr_hdshk && s_apb4_addr == `VGA_FBBA2;
  assign s_vga_fbba2_d  = apb4.pwdata[`VGA_FBBA2_WIDTH-1:0];
  dffer #(`VGA_FBBA2_WIDTH) u_vga_fbba2_dffer (
      apb4.pclk,
      apb4.presetn,
      s_vga_fbba2_en,
      s_vga_fbba2_d,
      s_vga_fbba2_q
  );

  always_comb begin
    assign s_vga_stat_d[3] = cfb_i;
    // xx_irq_i has higher priority, when xx_irq_i is 1, dont care other signal
    // when xx_irq_i is 0, if xx_if is 0, write 0/1 no effect
    // when xx_irq_i is 0, if xx_if is 1, write 0 clear bit, write 1 no effect
    if (s_apb4_wr_hdshk && s_apb4_addr == `VGA_STAT) begin
      s_vga_stat_d[2] = vbsirq_i | (s_vga_stat_q[2] & apb4.pwdata[2]);
      s_vga_stat_d[1] = verirq_i | (s_vga_stat_q[1] & apb4.pwdata[1]);
      s_vga_stat_d[0] = horirq_i | (s_vga_stat_q[0] & apb4.pwdata[0]);
    end else begin
      // irq signal only keep trigger one cycle
      s_vga_stat_d[2] = s_vga_stat_q[2] | vbsirq_i;
      s_vga_stat_d[1] = s_vga_stat_q[1] | verirq_i;
      s_vga_stat_d[0] = s_vga_stat_q[0] | horirq_i;
    end
  end
  dffr #(`VGA_STAT_WIDTH) u_vga_stat_dffr (
      apb4.pclk,
      apb4.presetn,
      s_vga_stat_d,
      s_vga_stat_q
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
        `VGA_STAT:  apb4.prdata[`VGA_STAT_WIDTH-1:0] = s_vga_stat_q;
        default:    apb4.prdata = '0;
      endcase
    end
  end

  assign s_pclk_div   = (|s_bit_div) ? s_bit_div : 8'b1;
  assign s_pclk_cnt_d = s_pclk_cnt_q == s_pclk_div - 1 ? '0 : s_pclk_cnt_q + 1'b1;
  dffr #(`VGA_DIV_WIDTH) u_pclk_cnt_dffr (
      apb4.pclk,
      apb4.presetn,
      s_pclk_cnt_d,
      s_pclk_cnt_q
  );
endmodule
