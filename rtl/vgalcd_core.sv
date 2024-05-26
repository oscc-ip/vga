// Copyright (c) 2023 Beijing Institute of Open Source Chip
// vgalcd is licensed under Mulan PSL v2.
// You can use this software according to the terms and conditions of the Mulan PSL v2.
// You may obtain a copy of Mulan PSL v2 at:
//             http://license.coscl.org.cn/MulanPSL2
// THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
// EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
// MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
// See the Mulan PSL v2 for more details.

`include "register.sv"
`include "vgalcd_define.sv"

module vgalcd_core (
    input  logic                         clk_i,
    input  logic                         rst_n_i,
    input  logic                         en_i,
    input  logic [`VGALCD_DIV_WIDTH-1:0] div_i,
    input  logic                         test_i,
    input  logic [                  1:0] mode_i,
    input  logic [ `VGALCD_TB_WIDTH-1:0] hbpsize_i,
    input  logic [ `VGALCD_TB_WIDTH-1:0] hsnsize_i,
    input  logic [ `VGALCD_TB_WIDTH-1:0] hfpsize_i,
    input  logic [ `VGALCD_VB_WIDTH-1:0] hvlen_i,
    input  logic [ `VGALCD_TB_WIDTH-1:0] vbpsize_i,
    input  logic [ `VGALCD_TB_WIDTH-1:0] vsnsize_i,
    input  logic [ `VGALCD_TB_WIDTH-1:0] vfpsize_i,
    input  logic [ `VGALCD_VB_WIDTH-1:0] vvlen_i,
    input  logic                         pixel_valid_i,
    output logic                         pixel_ready_o,
    input  logic [                 63:0] pixel_data_i,
    output logic [                  4:0] vgalcd_r_o,
    output logic [                  5:0] vgalcd_g_o,
    output logic [                  4:0] vgalcd_b_o,
    output logic                         hsync_o,
    output logic                         hend_o,
    output logic                         vsync_o,
    output logic                         vend_o,
    output logic                         pclk_o,
    output logic                         de_o
);

  logic [`VGALCD_TIMCNT_WIDTH-1:0] s_pos_x;
  logic [`VGALCD_DIV_WIDTH-1:0] s_pclk_cnt_d, s_pclk_cnt_q, s_pclk_div;
  logic s_pclk_d, s_pclk_q;
  logic [15:0] s_tm_data_d, s_tm_data_q, s_fb_data, s_pixel_data;
  logic [1:0] s_fetch_cnt_d, s_fetch_cnt_q;
  logic [63:0] s_fetch_data_d, s_fetch_data_q;
  logic s_norm_mode;

  // gen pclk
  assign pclk_o       = s_pclk_q;
  assign s_pclk_div   = (|div_i) ? div_i : 8'b1;
  assign s_pclk_cnt_d = s_pclk_cnt_q == s_pclk_div - 1 ? '0 : s_pclk_cnt_q + 1'b1;
  dffr #(`VGALCD_DIV_WIDTH) u_pclk_cnt_dffr (
      clk_i,
      rst_n_i,
      s_pclk_cnt_d,
      s_pclk_cnt_q
  );

  assign s_pclk_d = s_pclk_cnt_q == s_pclk_div - 1 ? ~s_pclk_q : s_pclk_q;
  dffr #(1) u_pclk_dffr (
      clk_i,
      rst_n_i,
      s_pclk_d,
      s_pclk_q
  );

  vgalcd_timgen u_vgalcd_timgen (
      .clk_i    (clk_i),
      .rst_n_i  (rst_n_i),
      .en_i     (en_i),
      .pclk_en_i(s_pclk_cnt_q == '0),
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

  assign s_norm_mode   = en_i && ~test_i;
  assign pixel_ready_o = s_norm_mode && (s_fetch_cnt_q == '0);

  always_comb begin
    s_fetch_cnt_d = s_fetch_cnt_q;
    if (s_norm_mode) begin
      s_fetch_cnt_d = s_fetch_cnt_q == '1 ? '0 : s_fetch_cnt_q + 1'b1;
    end
  end
  dffer #(2) u_fetch_cnt_dffer (
      clk_i,
      rst_n_i,
      s_norm_mode,
      s_fetch_cnt_d,
      s_fetch_cnt_q
  );

  assign s_fetch_data_d = (pixel_valid_i && pixel_ready_o) ? pixel_data_i : s_fetch_data_q;
  dffr #(64) u_fetch_data_dffr (
      clk_i,
      rst_n_i,
      s_fetch_data_d,
      s_fetch_data_q
  );

  always_comb begin
    unique case (s_fetch_cnt_q)
      2'b00: s_fb_data = pixel_data_i[15:0];
      2'b01: s_fb_data = s_fetch_data_q[31:16];
      2'b10: s_fb_data = s_fetch_data_q[47:32];
      2'b11: s_fb_data = s_fetch_data_q[63:48];
    endcase
  end

  assign s_pixel_data = ~de_o ? '0 : test_i ? s_tm_data_q : s_fb_data;
  always_comb begin
    s_tm_data_d = '0;
    if (test_i) begin
      s_tm_data_d = '0;
      if (s_pos_x >= 0 && s_pos_x < ((hvlen_i / 10) * 1)) begin
        unique case (mode_i)
          `VGALCD_RGB332_MODE: s_tm_data_d = `VGALCD_RGB332_COLOR_RED;
          `VGALCD_RGB444_MODE: s_tm_data_d = `VGALCD_RGB444_COLOR_RED;
          `VGALCD_RGB555_MODE: s_tm_data_d = `VGALCD_RGB555_COLOR_RED;
          `VGALCD_RGB565_MODE: s_tm_data_d = `VGALCD_RGB565_COLOR_RED;
          // default:          s_tm_data_d = `VGALCD_RGB565_COLOR_RED;
        endcase
      end else if (s_pos_x >= ((hvlen_i / 10) * 1) && s_pos_x < ((hvlen_i / 10) * 2)) begin
        unique case (mode_i)
          `VGALCD_RGB332_MODE: s_tm_data_d = `VGALCD_RGB332_COLOR_ORANGE;
          `VGALCD_RGB444_MODE: s_tm_data_d = `VGALCD_RGB444_COLOR_ORANGE;
          `VGALCD_RGB555_MODE: s_tm_data_d = `VGALCD_RGB555_COLOR_ORANGE;
          `VGALCD_RGB565_MODE: s_tm_data_d = `VGALCD_RGB565_COLOR_ORANGE;
          //   // default:          s_tm_data_d = `VGALCD_RGB565_COLOR_ORANGE;
        endcase
      end else if (s_pos_x >= ((hvlen_i / 10) * 2) && s_pos_x < ((hvlen_i / 10) * 3)) begin
        unique case (mode_i)
          `VGALCD_RGB332_MODE: s_tm_data_d = `VGALCD_RGB332_COLOR_YELLOW;
          `VGALCD_RGB444_MODE: s_tm_data_d = `VGALCD_RGB444_COLOR_YELLOW;
          `VGALCD_RGB555_MODE: s_tm_data_d = `VGALCD_RGB555_COLOR_YELLOW;
          `VGALCD_RGB565_MODE: s_tm_data_d = `VGALCD_RGB565_COLOR_YELLOW;
          // default:          s_tm_data_d = `VGALCD_RGB565_COLOR_YELLOW;
        endcase
      end else if (s_pos_x >= ((hvlen_i / 10) * 3) && s_pos_x < ((hvlen_i / 10) * 4)) begin
        unique case (mode_i)
          `VGALCD_RGB332_MODE: s_tm_data_d = `VGALCD_RGB332_COLOR_GREEN;
          `VGALCD_RGB444_MODE: s_tm_data_d = `VGALCD_RGB444_COLOR_GREEN;
          `VGALCD_RGB555_MODE: s_tm_data_d = `VGALCD_RGB555_COLOR_GREEN;
          `VGALCD_RGB565_MODE: s_tm_data_d = `VGALCD_RGB565_COLOR_GREEN;
          // default:          s_tm_data_d = `VGALCD_RGB565_COLOR_GREEN;
        endcase
      end else if (s_pos_x >= ((hvlen_i / 10) * 4) && s_pos_x < ((hvlen_i / 10) * 5)) begin
        unique case (mode_i)
          `VGALCD_RGB332_MODE: s_tm_data_d = `VGALCD_RGB332_COLOR_CYAN;
          `VGALCD_RGB444_MODE: s_tm_data_d = `VGALCD_RGB444_COLOR_CYAN;
          `VGALCD_RGB555_MODE: s_tm_data_d = `VGALCD_RGB555_COLOR_CYAN;
          `VGALCD_RGB565_MODE: s_tm_data_d = `VGALCD_RGB565_COLOR_CYAN;
          // default:          s_tm_data_d = `VGALCD_RGB565_COLOR_CYAN;
        endcase
      end else if (s_pos_x >= ((hvlen_i / 10) * 5) && s_pos_x < ((hvlen_i / 10) * 6)) begin
        unique case (mode_i)
          `VGALCD_RGB332_MODE: s_tm_data_d = `VGALCD_RGB332_COLOR_BLUE;
          `VGALCD_RGB444_MODE: s_tm_data_d = `VGALCD_RGB444_COLOR_BLUE;
          `VGALCD_RGB555_MODE: s_tm_data_d = `VGALCD_RGB555_COLOR_BLUE;
          `VGALCD_RGB565_MODE: s_tm_data_d = `VGALCD_RGB565_COLOR_BLUE;
          // default:          s_tm_data_d = `VGALCD_RGB565_COLOR_BLUE;
        endcase
      end else if (s_pos_x >= ((hvlen_i / 10) * 6) && s_pos_x < ((hvlen_i / 10) * 7)) begin
        unique case (mode_i)
          `VGALCD_RGB332_MODE: s_tm_data_d = `VGALCD_RGB332_COLOR_PURPPLE;
          `VGALCD_RGB444_MODE: s_tm_data_d = `VGALCD_RGB444_COLOR_PURPPLE;
          `VGALCD_RGB555_MODE: s_tm_data_d = `VGALCD_RGB555_COLOR_PURPPLE;
          `VGALCD_RGB565_MODE: s_tm_data_d = `VGALCD_RGB565_COLOR_PURPPLE;
          // default:          s_tm_data_d = `VGALCD_RGB565_COLOR_PURPPLE;
        endcase
      end else if (s_pos_x >= ((hvlen_i / 10) * 7) && s_pos_x < ((hvlen_i / 10) * 8)) begin
        unique case (mode_i)
          `VGALCD_RGB332_MODE: s_tm_data_d = `VGALCD_RGB332_COLOR_BLACK;
          `VGALCD_RGB444_MODE: s_tm_data_d = `VGALCD_RGB444_COLOR_BLACK;
          `VGALCD_RGB555_MODE: s_tm_data_d = `VGALCD_RGB555_COLOR_BLACK;
          `VGALCD_RGB565_MODE: s_tm_data_d = `VGALCD_RGB565_COLOR_BLACK;
          // default:          s_tm_data_d = `VGALCD_RGB565_COLOR_BLACK;
        endcase
      end else if (s_pos_x >= ((hvlen_i / 10) * 8) && s_pos_x < ((hvlen_i / 10) * 9)) begin
        unique case (mode_i)
          `VGALCD_RGB332_MODE: s_tm_data_d = `VGALCD_RGB332_COLOR_WHITE;
          `VGALCD_RGB444_MODE: s_tm_data_d = `VGALCD_RGB444_COLOR_WHITE;
          `VGALCD_RGB555_MODE: s_tm_data_d = `VGALCD_RGB555_COLOR_WHITE;
          `VGALCD_RGB565_MODE: s_tm_data_d = `VGALCD_RGB565_COLOR_WHITE;
          // default:          s_tm_data_d = `VGALCD_RGB565_COLOR_WHITE;
        endcase
      end else if (s_pos_x >= ((hvlen_i / 10) * 9) && s_pos_x < (hvlen_i)) begin
        unique case (mode_i)
          `VGALCD_RGB332_MODE: s_tm_data_d = `VGALCD_RGB332_COLOR_GRAY;
          `VGALCD_RGB444_MODE: s_tm_data_d = `VGALCD_RGB444_COLOR_GRAY;
          `VGALCD_RGB555_MODE: s_tm_data_d = `VGALCD_RGB555_COLOR_GRAY;
          `VGALCD_RGB565_MODE: s_tm_data_d = `VGALCD_RGB565_COLOR_GRAY;
          // default:          s_tm_data_d = `VGALCD_RGB565_COLOR_GRAY;
        endcase
      end
    end
  end
  dffr #(16) u_tm_data_dffr (
      clk_i,
      rst_n_i,
      s_tm_data_d,
      s_tm_data_q
  );

  // RGB332 RGB444 RGB555 RGB565
  always_comb begin
    vgalcd_r_o = '0;
    if (de_o) begin
      unique case (mode_i)
        `VGALCD_RGB332_MODE: vgalcd_r_o = s_pixel_data[7:5];
        `VGALCD_RGB444_MODE: vgalcd_r_o = s_pixel_data[11:8];
        `VGALCD_RGB555_MODE: vgalcd_r_o = s_pixel_data[14:10];
        `VGALCD_RGB565_MODE: vgalcd_r_o = s_pixel_data[15:11];
        default:             vgalcd_r_o = '0;
      endcase
    end
  end

  always_comb begin
    vgalcd_g_o = '0;
    if (de_o) begin
      unique case (mode_i)
        `VGALCD_RGB332_MODE: vgalcd_g_o = s_pixel_data[4:2];
        `VGALCD_RGB444_MODE: vgalcd_g_o = s_pixel_data[7:4];
        `VGALCD_RGB555_MODE: vgalcd_g_o = s_pixel_data[9:5];
        `VGALCD_RGB565_MODE: vgalcd_g_o = s_pixel_data[10:5];
        default:             vgalcd_g_o = '0;
      endcase
    end
  end

  always_comb begin
    vgalcd_b_o = '0;
    if (de_o) begin
      unique case (mode_i)
        `VGALCD_RGB332_MODE: vgalcd_b_o = s_pixel_data[1:0];
        `VGALCD_RGB444_MODE: vgalcd_b_o = s_pixel_data[3:0];
        `VGALCD_RGB555_MODE: vgalcd_b_o = s_pixel_data[4:0];
        `VGALCD_RGB565_MODE: vgalcd_b_o = s_pixel_data[4:0];
        default:             vgalcd_b_o = '0;
      endcase
    end
  end
endmodule
