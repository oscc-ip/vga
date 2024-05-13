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


  logic s_pclk;
  logic [10:0] s_hori_cnt_d, s_hori_cnt_q;  // 0 ~ 2047
  logic [10:0] s_vert_cnt_d, s_vert_cnt_q;  // 0 ~ 2047
  logic [10:0] s_pixel_x, s_pixel_y;
  logic [15:0] s_tm_data_d, s_tm_data_q, s_fb_data, s_pixel_data;

  assign s_pixel_x    = vga.vga_de_o ? s_hori_cnt_q - (s_vga_hsnsize_q + s_vga_hbpsize_q - 1) : '0;
  assign s_pixel_y    = vga.vga_de_o ? s_vert_cnt_q - (s_vga_vsnsize_q + s_vga_vbpsize_q) : '0;
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

  dffr #(16) u_testmode_data_dffr (
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

  always_comb begin
    s_hori_cnt_d = s_hori_cnt_q;
    if (s_bit_en) begin
      if(s_hori_cnt_q == s_vga_hsnsize_q + s_vga_hbpsize_q + s_vga_hvsize_q + s_vga_hfpsize_q - 1) begin
        s_hori_cnt_d = '0;
      end else begin
        s_hori_cnt_d = s_hori_cnt_q + 1'b1;
      end
    end
  end
  dffr #(11) u_hori_cnt_dffr (
      s_pclk,
      apb4.presetn,
      s_hori_cnt_d,
      s_hori_cnt_q
  );

  always_comb begin
    s_vert_cnt_d = s_vert_cnt_q;
    if (s_bit_en) begin
      if((s_vert_cnt_q == s_vga_vsnsize_q + s_vga_vbpsize_q + s_vga_vvsize_q + s_vga_vfpsize_q - 1)
      && (s_hori_cnt_q == s_vga_hsnsize_q + s_vga_hbpsize_q + s_vga_hvsize_q + s_vga_hfpsize_q - 1)) begin
        s_vert_cnt_d = '0;
      end else begin
        s_vert_cnt_d = s_vert_cnt_q + 1'b1;
      end
    end
  end
  dffr #(11) u_vert_cnt_dffr (
      s_pclk,
      apb4.presetn,
      s_vert_cnt_d,
      s_vert_cnt_q
  );


endmodule
