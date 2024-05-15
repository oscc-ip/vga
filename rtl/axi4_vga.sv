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

module axi4_vga (
    apb4_if.slave  apb4,
    axi4_if.master axi4,
    vga_if.dut     vga
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



  vga_core u_vga_core (.axi4(axi4));


  logic [10:0] s_pixel_x, s_pixel_y;
  logic [15:0] s_tm_data_d, s_tm_data_q, s_fb_data, s_pixel_data;


  assign s_pixel_data = ~vga.vga_de_o ? '0 : s_bit_test ? s_tm_data_q : s_fb_data;


  always_comb begin
    s_tm_data_d = '0;
    if (s_bit_test) begin
      s_tm_data_d = '0;
      if (s_pixel_x >= 0 && s_pixel_x < ((s_vga_hvsize_q / 10) * 1)) begin
        unique case (s_bit_mode)
          `VGA_RGB332_MODE: s_tm_data_d = `VGA_RGB332_COLOR_RED;
          `VGA_RGB444_MODE: s_tm_data_d = `VGA_RGB444_COLOR_RED;
          `VGA_RGB555_MODE: s_tm_data_d = `VGA_RGB555_COLOR_RED;
          `VGA_RGB565_MODE: s_tm_data_d = `VGA_RGB565_COLOR_RED;
          default:          s_tm_data_d = `VGA_RGB565_COLOR_RED;
        endcase
      end else if(s_pixel_x >= ((s_vga_hvsize_q / 10) * 1) && s_pixel_x < ((s_vga_hvsize_q / 10 ) * 2)) begin
        unique case (s_bit_mode)
          `VGA_RGB332_MODE: s_tm_data_d = `VGA_RGB332_COLOR_ORANGE;
          `VGA_RGB444_MODE: s_tm_data_d = `VGA_RGB444_COLOR_ORANGE;
          `VGA_RGB555_MODE: s_tm_data_d = `VGA_RGB555_COLOR_ORANGE;
          `VGA_RGB565_MODE: s_tm_data_d = `VGA_RGB565_COLOR_ORANGE;
          default:          s_tm_data_d = `VGA_RGB565_COLOR_ORANGE;
        endcase
      end else if(s_pixel_x >= ((s_vga_hvsize_q / 10) * 2) && s_pixel_x < ((s_vga_hvsize_q / 10 ) * 3)) begin
        unique case (s_bit_mode)
          `VGA_RGB332_MODE: s_tm_data_d = `VGA_RGB332_COLOR_YELLOW;
          `VGA_RGB444_MODE: s_tm_data_d = `VGA_RGB444_COLOR_YELLOW;
          `VGA_RGB555_MODE: s_tm_data_d = `VGA_RGB555_COLOR_YELLOW;
          `VGA_RGB565_MODE: s_tm_data_d = `VGA_RGB565_COLOR_YELLOW;
          default:          s_tm_data_d = `VGA_RGB565_COLOR_YELLOW;
        endcase
      end else if(s_pixel_x >= ((s_vga_hvsize_q / 10) * 3) && s_pixel_x < ((s_vga_hvsize_q / 10 ) * 4)) begin
        unique case (s_bit_mode)
          `VGA_RGB332_MODE: s_tm_data_d = `VGA_RGB332_COLOR_GREEN;
          `VGA_RGB444_MODE: s_tm_data_d = `VGA_RGB444_COLOR_GREEN;
          `VGA_RGB555_MODE: s_tm_data_d = `VGA_RGB555_COLOR_GREEN;
          `VGA_RGB565_MODE: s_tm_data_d = `VGA_RGB565_COLOR_GREEN;
          default:          s_tm_data_d = `VGA_RGB565_COLOR_GREEN;
        endcase
      end else if(s_pixel_x >= ((s_vga_hvsize_q / 10) * 4) && s_pixel_x < ((s_vga_hvsize_q / 10 ) * 5)) begin
        unique case (s_bit_mode)
          `VGA_RGB332_MODE: s_tm_data_d = `VGA_RGB332_COLOR_CYAN;
          `VGA_RGB444_MODE: s_tm_data_d = `VGA_RGB444_COLOR_CYAN;
          `VGA_RGB555_MODE: s_tm_data_d = `VGA_RGB555_COLOR_CYAN;
          `VGA_RGB565_MODE: s_tm_data_d = `VGA_RGB565_COLOR_CYAN;
          default:          s_tm_data_d = `VGA_RGB565_COLOR_CYAN;
        endcase
      end else if(s_pixel_x >= ((s_vga_hvsize_q / 10) * 5) && s_pixel_x < ((s_vga_hvsize_q / 10 ) * 6)) begin
        unique case (s_bit_mode)
          `VGA_RGB332_MODE: s_tm_data_d = `VGA_RGB332_COLOR_BLUE;
          `VGA_RGB444_MODE: s_tm_data_d = `VGA_RGB444_COLOR_BLUE;
          `VGA_RGB555_MODE: s_tm_data_d = `VGA_RGB555_COLOR_BLUE;
          `VGA_RGB565_MODE: s_tm_data_d = `VGA_RGB565_COLOR_BLUE;
          default:          s_tm_data_d = `VGA_RGB565_COLOR_BLUE;
        endcase
      end else if(s_pixel_x >= ((s_vga_hvsize_q / 10) * 6) && s_pixel_x < ((s_vga_hvsize_q / 10 ) * 7)) begin
        unique case (s_bit_mode)
          `VGA_RGB332_MODE: s_tm_data_d = `VGA_RGB332_COLOR_PURPPLE;
          `VGA_RGB444_MODE: s_tm_data_d = `VGA_RGB444_COLOR_PURPPLE;
          `VGA_RGB555_MODE: s_tm_data_d = `VGA_RGB555_COLOR_PURPPLE;
          `VGA_RGB565_MODE: s_tm_data_d = `VGA_RGB565_COLOR_PURPPLE;
          default:          s_tm_data_d = `VGA_RGB565_COLOR_PURPPLE;
        endcase
      end else if(s_pixel_x >= ((s_vga_hvsize_q / 10) * 7) && s_pixel_x < ((s_vga_hvsize_q / 10 ) * 8)) begin
        unique case (s_bit_mode)
          `VGA_RGB332_MODE: s_tm_data_d = `VGA_RGB332_COLOR_BLACK;
          `VGA_RGB444_MODE: s_tm_data_d = `VGA_RGB444_COLOR_BLACK;
          `VGA_RGB555_MODE: s_tm_data_d = `VGA_RGB555_COLOR_BLACK;
          `VGA_RGB565_MODE: s_tm_data_d = `VGA_RGB565_COLOR_BLACK;
          default:          s_tm_data_d = `VGA_RGB565_COLOR_BLACK;
        endcase
      end else if(s_pixel_x >= ((s_vga_hvsize_q / 10) * 8) && s_pixel_x < ((s_vga_hvsize_q / 10 ) * 9)) begin
        unique case (s_bit_mode)
          `VGA_RGB332_MODE: s_tm_data_d = `VGA_RGB332_COLOR_WHITE;
          `VGA_RGB444_MODE: s_tm_data_d = `VGA_RGB444_COLOR_WHITE;
          `VGA_RGB555_MODE: s_tm_data_d = `VGA_RGB555_COLOR_WHITE;
          `VGA_RGB565_MODE: s_tm_data_d = `VGA_RGB565_COLOR_WHITE;
          default:          s_tm_data_d = `VGA_RGB565_COLOR_WHITE;
        endcase
      end else if (s_pixel_x >= ((s_vga_hvsize_q / 10) * 9) && s_pixel_x < (s_vga_hvsize_q)) begin
        unique case (s_bit_mode)
          `VGA_RGB332_MODE: s_tm_data_d = `VGA_RGB332_COLOR_GRAY;
          `VGA_RGB444_MODE: s_tm_data_d = `VGA_RGB444_COLOR_GRAY;
          `VGA_RGB555_MODE: s_tm_data_d = `VGA_RGB555_COLOR_GRAY;
          `VGA_RGB565_MODE: s_tm_data_d = `VGA_RGB565_COLOR_GRAY;
          default:          s_tm_data_d = `VGA_RGB565_COLOR_GRAY;
        endcase
      end
    end
  end

  dffr #(16) u_tm_data_dffr (
      apb4.pclk,
      apb4.presetn,
      s_tm_data_d,
      s_tm_data_q
  );


  // vga counter
  assign vga.vga_pclk_o = s_pclk;
  assign vga.vga_hsync_o = (s_hori_cnt_q <= s_vga_hsnsize_q - 1'b1) ? s_bit_hspol : ~s_bit_hspol;
  assign vga.vga_vsync_o = (s_vert_cnt_q <= s_vga_vsnsize_q - 1'b1) ? s_bit_vspol : ~s_bit_vspol;
  assign vga.vga_de_o    = (s_hori_cnt_q >= s_vga_hsnsize_q + s_vga_hbpsize_q)
                        && (s_hori_cnt_q < s_vga_hsnsize_q + s_vga_hbpsize_q + s_vga_hvsize_q + s_vga_hfpsize_q)
                        && (s_vert_cnt_q >= s_vga_vsnsize_q + s_vga_vbpsize_q)
                        && (s_vert_cnt_q < s_vga_vsnsize_q + s_vga_vbpsize_q + s_vga_vvsize_q + s_vga_vfpsize_q);

  // RGB332 RGB444 RGB555 RGB565
  always_comb begin
    vga.vga_r_o = '0;
    if (vga.vga_de_o) begin
      unique case (s_bit_mode)
        `VGA_RGB332_MODE: vga.vga_r_o = s_pixel_data[7:5];
        `VGA_RGB444_MODE: vga.vga_r_o = s_pixel_data[11:8];
        `VGA_RGB555_MODE: vga.vga_r_o = s_pixel_data[14:10];
        `VGA_RGB565_MODE: vga.vga_r_o = s_pixel_data[15:11];
        default:          vga.vga_r_o = '0;
      endcase
    end
  end

  always_comb begin
    vga.vga_g_o = '0;
    if (vga.vga_de_o) begin
      unique case (s_bit_mode)
        `VGA_RGB332_MODE: vga.vga_g_o = s_pixel_data[4:2];
        `VGA_RGB444_MODE: vga.vga_g_o = s_pixel_data[7:4];
        `VGA_RGB555_MODE: vga.vga_g_o = s_pixel_data[9:5];
        `VGA_RGB565_MODE: vga.vga_g_o = s_pixel_data[10:5];
        default:          vga.vga_g_o = '0;
      endcase
    end
  end

  always_comb begin
    vga.vga_b_o = '0;
    if (vga.vga_de_o) begin
      unique case (s_bit_mode)
        `VGA_RGB332_MODE: vga.vga_b_o = s_pixel_data[1:0];
        `VGA_RGB444_MODE: vga.vga_b_o = s_pixel_data[3:0];
        `VGA_RGB555_MODE: vga.vga_b_o = s_pixel_data[4:0];
        `VGA_RGB565_MODE: vga.vga_b_o = s_pixel_data[4:0];
        default:          vga.vga_b_o = '0;
      endcase
    end
  end

endmodule
