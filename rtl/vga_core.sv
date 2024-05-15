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

module vga_core (
    input  logic                     clk_i,
    input  logic                     rst_n_i,
    input  logic                     en_i,
    input  logic                     test_i,
    input  logic [`VGA_TB_WIDTH-1:0] hbpsize_i,
    input  logic [`VGA_TB_WIDTH-1:0] hsnsize_i,
    input  logic [`VGA_TB_WIDTH-1:0] hfpsize_i,
    input  logic [`VGA_VB_WIDTH-1:0] hvlen_i,
    input  logic [`VGA_TB_WIDTH-1:0] vbpsize_i,
    input  logic [`VGA_TB_WIDTH-1:0] vsnsize_i,
    input  logic [`VGA_TB_WIDTH-1:0] vfpsize_i,
    input  logic [`VGA_VB_WIDTH-1:0] vvlen_i,
    input  logic                     pixel_valid_i,
    output logic                     pixel_ready_o,
    input  logic [             63:0] pixel_data_i,
    output logic [              4:0] vga_r_o,
    output logic [              5:0] vga_g_o,
    output logic [              4:0] vga_b_o,
    output logic                     hsync_o,
    output logic                     hend_o,
    output logic                     vsync_o,
    output logic                     vend_o,
    output logic                     pclk_en_o,
    output logic                     de_o
);

  logic [`VGA_TIMCNT_WIDTH-1:0] s_pos_x;
  logic [`VGA_DIV_WIDTH-1:0] s_pclk_cnt_d, s_pclk_cnt_q, s_pclk_div;
  logic pclk_en_i;
  logic [15:0] s_tm_data_d, s_tm_data_q, s_fb_data, s_pixel_data;

  // gen pclk
  assign pclk_en_i    = s_pclk_cnt_q == '0;
  assign s_pclk_div   = (|s_bit_div) ? s_bit_div : 8'b1;
  assign s_pclk_cnt_d = s_pclk_cnt_q == s_pclk_div - 1 ? '0 : s_pclk_cnt_q + 1'b1;
  dffr #(`VGA_DIV_WIDTH) u_pclk_cnt_dffr (
      clk_i,
      rst_n_i,
      s_pclk_cnt_d,
      s_pclk_cnt_q
  );

  vga_timgen u_vga_timgen (
      .clk_i    (clk_i),
      .rst_n_i  (rst_n_i),
      .en_i     (en_i),
      .pclk_en_i(pclk_en_i),
      .hbpsize_i(hbpsize_i),
      .hsnsize_i(hsnsize_i),
      .hfpsize_i(hfpsize_i),
      .hvlen_i  (hvlen_i),
      .vbpsize_i(vbpsize_i),
      .vsnsize_i(vsnsize_i),
      .vfpsize_i(vfpsize_i),
      .vvlen_i  (vvlen_i),
      .pos_x_o  (s_pos_x),
      .hsync_o  (hsync_o),
      .hend_o   (hend_o),
      .vsync_o  (vsync_o),
      .vend_o   (vend_o),
      .de_o     (de_o)
  );

  assign s_pixel_data = ~de_o ? '0 : test_i ? s_tm_data_q : s_fb_data;
  always_comb begin
    s_tm_data_d = '0;
    if (test_i) begin
      s_tm_data_d = '0;
      if (s_pos_x >= 0 && s_pos_x < ((hvlen_i / 10) * 1)) begin
        unique case (s_bit_mode)
          `VGA_RGB332_MODE: s_tm_data_d = `VGA_RGB332_COLOR_RED;
          `VGA_RGB444_MODE: s_tm_data_d = `VGA_RGB444_COLOR_RED;
          `VGA_RGB555_MODE: s_tm_data_d = `VGA_RGB555_COLOR_RED;
          `VGA_RGB565_MODE: s_tm_data_d = `VGA_RGB565_COLOR_RED;
          default:          s_tm_data_d = `VGA_RGB565_COLOR_RED;
        endcase
      end else if (s_pos_x >= ((hvlen_i / 10) * 1) && s_pos_x < ((hvlen_i / 10) * 2)) begin
        unique case (s_bit_mode)
          `VGA_RGB332_MODE: s_tm_data_d = `VGA_RGB332_COLOR_ORANGE;
          `VGA_RGB444_MODE: s_tm_data_d = `VGA_RGB444_COLOR_ORANGE;
          `VGA_RGB555_MODE: s_tm_data_d = `VGA_RGB555_COLOR_ORANGE;
          `VGA_RGB565_MODE: s_tm_data_d = `VGA_RGB565_COLOR_ORANGE;
          default:          s_tm_data_d = `VGA_RGB565_COLOR_ORANGE;
        endcase
      end else if (s_pos_x >= ((hvlen_i / 10) * 2) && s_pos_x < ((hvlen_i / 10) * 3)) begin
        unique case (s_bit_mode)
          `VGA_RGB332_MODE: s_tm_data_d = `VGA_RGB332_COLOR_YELLOW;
          `VGA_RGB444_MODE: s_tm_data_d = `VGA_RGB444_COLOR_YELLOW;
          `VGA_RGB555_MODE: s_tm_data_d = `VGA_RGB555_COLOR_YELLOW;
          `VGA_RGB565_MODE: s_tm_data_d = `VGA_RGB565_COLOR_YELLOW;
          default:          s_tm_data_d = `VGA_RGB565_COLOR_YELLOW;
        endcase
      end else if (s_pos_x >= ((hvlen_i / 10) * 3) && s_pos_x < ((hvlen_i / 10) * 4)) begin
        unique case (s_bit_mode)
          `VGA_RGB332_MODE: s_tm_data_d = `VGA_RGB332_COLOR_GREEN;
          `VGA_RGB444_MODE: s_tm_data_d = `VGA_RGB444_COLOR_GREEN;
          `VGA_RGB555_MODE: s_tm_data_d = `VGA_RGB555_COLOR_GREEN;
          `VGA_RGB565_MODE: s_tm_data_d = `VGA_RGB565_COLOR_GREEN;
          default:          s_tm_data_d = `VGA_RGB565_COLOR_GREEN;
        endcase
      end else if (s_pos_x >= ((hvlen_i / 10) * 4) && s_pos_x < ((hvlen_i / 10) * 5)) begin
        unique case (s_bit_mode)
          `VGA_RGB332_MODE: s_tm_data_d = `VGA_RGB332_COLOR_CYAN;
          `VGA_RGB444_MODE: s_tm_data_d = `VGA_RGB444_COLOR_CYAN;
          `VGA_RGB555_MODE: s_tm_data_d = `VGA_RGB555_COLOR_CYAN;
          `VGA_RGB565_MODE: s_tm_data_d = `VGA_RGB565_COLOR_CYAN;
          default:          s_tm_data_d = `VGA_RGB565_COLOR_CYAN;
        endcase
      end else if (s_pos_x >= ((hvlen_i / 10) * 5) && s_pos_x < ((hvlen_i / 10) * 6)) begin
        unique case (s_bit_mode)
          `VGA_RGB332_MODE: s_tm_data_d = `VGA_RGB332_COLOR_BLUE;
          `VGA_RGB444_MODE: s_tm_data_d = `VGA_RGB444_COLOR_BLUE;
          `VGA_RGB555_MODE: s_tm_data_d = `VGA_RGB555_COLOR_BLUE;
          `VGA_RGB565_MODE: s_tm_data_d = `VGA_RGB565_COLOR_BLUE;
          default:          s_tm_data_d = `VGA_RGB565_COLOR_BLUE;
        endcase
      end else if (s_pos_x >= ((hvlen_i / 10) * 6) && s_pos_x < ((hvlen_i / 10) * 7)) begin
        unique case (s_bit_mode)
          `VGA_RGB332_MODE: s_tm_data_d = `VGA_RGB332_COLOR_PURPPLE;
          `VGA_RGB444_MODE: s_tm_data_d = `VGA_RGB444_COLOR_PURPPLE;
          `VGA_RGB555_MODE: s_tm_data_d = `VGA_RGB555_COLOR_PURPPLE;
          `VGA_RGB565_MODE: s_tm_data_d = `VGA_RGB565_COLOR_PURPPLE;
          default:          s_tm_data_d = `VGA_RGB565_COLOR_PURPPLE;
        endcase
      end else if (s_pos_x >= ((hvlen_i / 10) * 7) && s_pos_x < ((hvlen_i / 10) * 8)) begin
        unique case (s_bit_mode)
          `VGA_RGB332_MODE: s_tm_data_d = `VGA_RGB332_COLOR_BLACK;
          `VGA_RGB444_MODE: s_tm_data_d = `VGA_RGB444_COLOR_BLACK;
          `VGA_RGB555_MODE: s_tm_data_d = `VGA_RGB555_COLOR_BLACK;
          `VGA_RGB565_MODE: s_tm_data_d = `VGA_RGB565_COLOR_BLACK;
          default:          s_tm_data_d = `VGA_RGB565_COLOR_BLACK;
        endcase
      end else if (s_pos_x >= ((hvlen_i / 10) * 8) && s_pos_x < ((hvlen_i / 10) * 9)) begin
        unique case (s_bit_mode)
          `VGA_RGB332_MODE: s_tm_data_d = `VGA_RGB332_COLOR_WHITE;
          `VGA_RGB444_MODE: s_tm_data_d = `VGA_RGB444_COLOR_WHITE;
          `VGA_RGB555_MODE: s_tm_data_d = `VGA_RGB555_COLOR_WHITE;
          `VGA_RGB565_MODE: s_tm_data_d = `VGA_RGB565_COLOR_WHITE;
          default:          s_tm_data_d = `VGA_RGB565_COLOR_WHITE;
        endcase
      end else if (s_pos_x >= ((hvlen_i / 10) * 9) && s_pos_x < (hvlen_i)) begin
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

  // RGB332 RGB444 RGB555 RGB565
  always_comb begin
    vga_r_o = '0;
    if (vga.vga_de_o) begin
      unique case (s_bit_mode)
        `VGA_RGB332_MODE: vga_r_o = s_pixel_data[7:5];
        `VGA_RGB444_MODE: vga_r_o = s_pixel_data[11:8];
        `VGA_RGB555_MODE: vga_r_o = s_pixel_data[14:10];
        `VGA_RGB565_MODE: vga_r_o = s_pixel_data[15:11];
        default:          vga_r_o = '0;
      endcase
    end
  end

  always_comb begin
    vga_g_o = '0;
    if (vga.vga_de_o) begin
      unique case (s_bit_mode)
        `VGA_RGB332_MODE: vga_g_o = s_pixel_data[4:2];
        `VGA_RGB444_MODE: vga_g_o = s_pixel_data[7:4];
        `VGA_RGB555_MODE: vga_g_o = s_pixel_data[9:5];
        `VGA_RGB565_MODE: vga_g_o = s_pixel_data[10:5];
        default:          vga_g_o = '0;
      endcase
    end
  end

  always_comb begin
    vga_b_o = '0;
    if (vga.vga_de_o) begin
      unique case (s_bit_mode)
        `VGA_RGB332_MODE: vga_b_o = s_pixel_data[1:0];
        `VGA_RGB444_MODE: vga_b_o = s_pixel_data[3:0];
        `VGA_RGB555_MODE: vga_b_o = s_pixel_data[4:0];
        `VGA_RGB565_MODE: vga_b_o = s_pixel_data[4:0];
        default:          vga_b_o = '0;
      endcase
    end
  end
endmodule
