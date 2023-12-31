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
    apb4_if.slave apb4,
    // axi4_if.master axi4,
    vga_if.dut    vga
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

  logic s_bit_en, s_bit_hspol, s_bit_vspol, s_bit_test;
  logic [1:0] s_bit_mode;
  logic [7:0] s_bit_div, s_bit_brulen;

  logic s_pclk;
  logic [10:0] s_hori_cnt_d, s_hori_cnt_q;  // 0 ~ 2047
  logic [10:0] s_vert_cnt_d, s_vert_cnt_q;  // 0 ~ 2047
  logic [10:0] s_pixel_x, s_pixel_y;
  logic [15:0] s_testmode_data_d, s_testmode_data_q, s_fb_data, s_pixel_data;

  assign s_apb4_addr = apb4.paddr[5:2];
  assign s_apb4_wr_hdshk = apb4.psel && apb4.penable && apb4.pwrite;
  assign s_apb4_rd_hdshk = apb4.psel && apb4.penable && (~apb4.pwrite);
  assign apb4.pready = 1'b1;
  assign apb4.pslverr = 1'b0;

  assign s_bit_en = s_vga_ctrl_q[0];
  assign s_bit_hspol = s_vga_ctrl_q[1];
  assign s_bit_vspol = s_vga_ctrl_q[2];
  assign s_bit_div = s_vga_ctrl_q[10:3];
  assign s_bit_test = s_vga_ctrl_q[11];
  assign s_bit_mode = s_vga_ctrl_q[13:12];
  assign s_bit_brulen = s_vga_ctrl_q[21:14];


  assign s_pixel_x = vga.vga_de_o ? s_hori_cnt_q - (s_vga_hsnsize_q + s_vga_hbpsize_q - 1) : '0;
  assign s_pixel_y = vga.vga_de_o ? s_vert_cnt_q - (s_vga_vsnsize_q + s_vga_vbpsize_q) : '0;
  assign s_pixel_data = ~vga.vga_de_o ? '0 : s_bit_test ? s_testmode_data_q : s_fb_data;

  always_comb begin
    s_testmode_data_d = '0;
    if (s_bit_test) begin
      s_testmode_data_d = '0;
      if (s_pixel_x >= 0 && s_pixel_x < ((s_vga_hvsize_q / 10) * 1)) begin
        unique case (s_bit_mode)
          `VGA_RGB332_MODE: s_testmode_data_d = `VGA_RGB332_COLOR_RED;
          `VGA_RGB444_MODE: s_testmode_data_d = `VGA_RGB444_COLOR_RED;
          `VGA_RGB555_MODE: s_testmode_data_d = `VGA_RGB555_COLOR_RED;
          `VGA_RGB565_MODE: s_testmode_data_d = `VGA_RGB565_COLOR_RED;
          default:          s_testmode_data_d = `VGA_RGB565_COLOR_RED;
        endcase
      end else if(s_pixel_x >= ((s_vga_hvsize_q / 10) * 1) && s_pixel_x < ((s_vga_hvsize_q / 10 ) * 2)) begin
        unique case (s_bit_mode)
          `VGA_RGB332_MODE: s_testmode_data_d = `VGA_RGB332_COLOR_ORANGE;
          `VGA_RGB444_MODE: s_testmode_data_d = `VGA_RGB444_COLOR_ORANGE;
          `VGA_RGB555_MODE: s_testmode_data_d = `VGA_RGB555_COLOR_ORANGE;
          `VGA_RGB565_MODE: s_testmode_data_d = `VGA_RGB565_COLOR_ORANGE;
          default:          s_testmode_data_d = `VGA_RGB565_COLOR_ORANGE;
        endcase
      end else if(s_pixel_x >= ((s_vga_hvsize_q / 10) * 2) && s_pixel_x < ((s_vga_hvsize_q / 10 ) * 3)) begin
        unique case (s_bit_mode)
          `VGA_RGB332_MODE: s_testmode_data_d = `VGA_RGB332_COLOR_YELLOW;
          `VGA_RGB444_MODE: s_testmode_data_d = `VGA_RGB444_COLOR_YELLOW;
          `VGA_RGB555_MODE: s_testmode_data_d = `VGA_RGB555_COLOR_YELLOW;
          `VGA_RGB565_MODE: s_testmode_data_d = `VGA_RGB565_COLOR_YELLOW;
          default:          s_testmode_data_d = `VGA_RGB565_COLOR_YELLOW;
        endcase
      end else if(s_pixel_x >= ((s_vga_hvsize_q / 10) * 3) && s_pixel_x < ((s_vga_hvsize_q / 10 ) * 4)) begin
        unique case (s_bit_mode)
          `VGA_RGB332_MODE: s_testmode_data_d = `VGA_RGB332_COLOR_GREEN;
          `VGA_RGB444_MODE: s_testmode_data_d = `VGA_RGB444_COLOR_GREEN;
          `VGA_RGB555_MODE: s_testmode_data_d = `VGA_RGB555_COLOR_GREEN;
          `VGA_RGB565_MODE: s_testmode_data_d = `VGA_RGB565_COLOR_GREEN;
          default:          s_testmode_data_d = `VGA_RGB565_COLOR_GREEN;
        endcase
      end else if(s_pixel_x >= ((s_vga_hvsize_q / 10) * 4) && s_pixel_x < ((s_vga_hvsize_q / 10 ) * 5)) begin
        unique case (s_bit_mode)
          `VGA_RGB332_MODE: s_testmode_data_d = `VGA_RGB332_COLOR_CYAN;
          `VGA_RGB444_MODE: s_testmode_data_d = `VGA_RGB444_COLOR_CYAN;
          `VGA_RGB555_MODE: s_testmode_data_d = `VGA_RGB555_COLOR_CYAN;
          `VGA_RGB565_MODE: s_testmode_data_d = `VGA_RGB565_COLOR_CYAN;
          default:          s_testmode_data_d = `VGA_RGB565_COLOR_CYAN;
        endcase
      end else if(s_pixel_x >= ((s_vga_hvsize_q / 10) * 5) && s_pixel_x < ((s_vga_hvsize_q / 10 ) * 6)) begin
        unique case (s_bit_mode)
          `VGA_RGB332_MODE: s_testmode_data_d = `VGA_RGB332_COLOR_BLUE;
          `VGA_RGB444_MODE: s_testmode_data_d = `VGA_RGB444_COLOR_BLUE;
          `VGA_RGB555_MODE: s_testmode_data_d = `VGA_RGB555_COLOR_BLUE;
          `VGA_RGB565_MODE: s_testmode_data_d = `VGA_RGB565_COLOR_BLUE;
          default:          s_testmode_data_d = `VGA_RGB565_COLOR_BLUE;
        endcase
      end else if(s_pixel_x >= ((s_vga_hvsize_q / 10) * 6) && s_pixel_x < ((s_vga_hvsize_q / 10 ) * 7)) begin
        unique case (s_bit_mode)
          `VGA_RGB332_MODE: s_testmode_data_d = `VGA_RGB332_COLOR_PURPPLE;
          `VGA_RGB444_MODE: s_testmode_data_d = `VGA_RGB444_COLOR_PURPPLE;
          `VGA_RGB555_MODE: s_testmode_data_d = `VGA_RGB555_COLOR_PURPPLE;
          `VGA_RGB565_MODE: s_testmode_data_d = `VGA_RGB565_COLOR_PURPPLE;
          default:          s_testmode_data_d = `VGA_RGB565_COLOR_PURPPLE;
        endcase
      end else if(s_pixel_x >= ((s_vga_hvsize_q / 10) * 7) && s_pixel_x < ((s_vga_hvsize_q / 10 ) * 8)) begin
        unique case (s_bit_mode)
          `VGA_RGB332_MODE: s_testmode_data_d = `VGA_RGB332_COLOR_BLACK;
          `VGA_RGB444_MODE: s_testmode_data_d = `VGA_RGB444_COLOR_BLACK;
          `VGA_RGB555_MODE: s_testmode_data_d = `VGA_RGB555_COLOR_BLACK;
          `VGA_RGB565_MODE: s_testmode_data_d = `VGA_RGB565_COLOR_BLACK;
          default:          s_testmode_data_d = `VGA_RGB565_COLOR_BLACK;
        endcase
      end else if(s_pixel_x >= ((s_vga_hvsize_q / 10) * 8) && s_pixel_x < ((s_vga_hvsize_q / 10 ) * 9)) begin
        unique case (s_bit_mode)
          `VGA_RGB332_MODE: s_testmode_data_d = `VGA_RGB332_COLOR_WHITE;
          `VGA_RGB444_MODE: s_testmode_data_d = `VGA_RGB444_COLOR_WHITE;
          `VGA_RGB555_MODE: s_testmode_data_d = `VGA_RGB555_COLOR_WHITE;
          `VGA_RGB565_MODE: s_testmode_data_d = `VGA_RGB565_COLOR_WHITE;
          default:          s_testmode_data_d = `VGA_RGB565_COLOR_WHITE;
        endcase
      end else if (s_pixel_x >= ((s_vga_hvsize_q / 10) * 9) && s_pixel_x < (s_vga_hvsize_q)) begin
        unique case (s_bit_mode)
          `VGA_RGB332_MODE: s_testmode_data_d = `VGA_RGB332_COLOR_GRAY;
          `VGA_RGB444_MODE: s_testmode_data_d = `VGA_RGB444_COLOR_GRAY;
          `VGA_RGB555_MODE: s_testmode_data_d = `VGA_RGB555_COLOR_GRAY;
          `VGA_RGB565_MODE: s_testmode_data_d = `VGA_RGB565_COLOR_GRAY;
          default:          s_testmode_data_d = `VGA_RGB565_COLOR_GRAY;
        endcase
      end
    end
  end

  dffr #(16) u_testmode_data_dffr (
      apb4.pclk,
      apb4.presetn,
      s_testmode_data_d,
      s_testmode_data_q
  );


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
