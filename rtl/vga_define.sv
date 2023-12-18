// Copyright (c) 2023 Beijing Institute of Open Source Chip
// vga is licensed under Mulan PSL v2.
// You can use this software according to the terms and conditions of the Mulan PSL v2.
// You may obtain a copy of Mulan PSL v2 at:
//             http://license.coscl.org.cn/MulanPSL2
// THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
// EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
// MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
// See the Mulan PSL v2 for more details.

`ifndef INC_VGA_DEF_SV
`define INC_VGA_DEF_SV

// RGB MODE: RGB565(VGA or LCD) RGB555 RGB444 RGB332
// RES: 
//      VGA: 640x350@70 640x400@70 640x480@60 800x600@60 800x600@72
//      LCD: 480x272 800x480

/* register mapping
 * VGA_CTRL:
 * BITS:   | 31:21 | 20:13  | 12   | 11   | 10:3 | 2     | 1     | 0  |
 * FIELDS: | RES   | BRULEN | MODE | TEST | DIV  | VSPOL | HSPOL | EN |
 * PERMS:  | NONE  | RW     | RW   | RW   | RW   | RW    | RW    | RW |
 * --------------------------------------------------------------------
 * VGA_HVSIZE:
 * BITS:   | 31:16 | 15:0   |
 * FIELDS: | RES   | HVSIZE |
 * PERMS:  | NONE  | RW     |
 * --------------------------------------------------------------------
 * VGA_HFPSIZE:
 * BITS:   | 31:16 | 15:0    |
 * FIELDS: | RES   | HFPSIZE |
 * PERMS:  | NONE  | none    |
 * --------------------------------------------------------------------
 * VGA_HSNSIZE:
 * BITS:   | 31:16 | 15:0    |
 * FIELDS: | RES   | HSNSIZE |
 * PERMS:  | NONE  | RW      |
 * --------------------------------------------------------------------
 * VGA_HBPSIZE:
 * BITS:   | 31:16 | 15:0    |
 * FIELDS: | RES   | HBPSIZE |
 * PERMS:  | NONE  | RW      |
 * --------------------------------------------------------------------
 * VGA_VVSIZE:
 * BITS:   | 31:16 | 15:0   |
 * FIELDS: | RES   | VVSIZE |
 * PERMS:  | NONE  | RW     |
 * --------------------------------------------------------------------
 * VGA_VFPSIZE:
 * BITS:   | 31:16 | 15:0    |
 * FIELDS: | RES   | VFPSIZE |
 * PERMS:  | NONE  | none    |
 * --------------------------------------------------------------------
 * VGA_VSNSIZE:
 * BITS:   | 31:16 | 15:0    |
 * FIELDS: | RES   | VSNSIZE |
 * PERMS:  | NONE  | RW      |
 * --------------------------------------------------------------------
 * VGA_VBPSIZE:
 * BITS:   | 31:16 | 15:0    |
 * FIELDS: | RES   | VBPSIZE |
 * PERMS:  | NONE  | RW      |
 * --------------------------------------------------------------------
 * VGA_FBSTART:
 * BITS:   | 31:0    |
 * FIELDS: | FPSTART |
 * PERMS:  | RW      |
 * --------------------------------------------------------------------
 * VGA_FBSIZE:
 * BITS:   | 31:0   |
 * FIELDS: | FBSIZE |
 * PERMS:  | RW     |
 * --------------------------------------------------------------------
*/

// verilog_format: off
`define VGA_CTRL    4'b0000 // BASEADDR + 0x00
`define VGA_HVSIZE  4'b0001 // BASEADDR + 0x04
`define VGA_HFPSIZE 4'b0010 // BASEADDR + 0x08
`define VGA_HSNSIZE 4'b0011 // BASEADDR + 0x0C
`define VGA_HBPSIZE 4'b0100 // BASEADDR + 0x10
`define VGA_VVSIZE  4'b0101 // BASEADDR + 0x14
`define VGA_VFPSIZE 4'b0110 // BASEADDR + 0x18
`define VGA_VSNSIZE 4'b0111 // BASEADDR + 0x1C
`define VGA_VBPSIZE 4'b1000 // BASEADDR + 0x20
`define VGA_FBSTART 4'b1001 // BASEADDR + 0x24
`define VGA_FBSIZE  4'b1010 // BASEADDR + 0x28

`define VGA_CTRL_ADDR    {26'b0, `VGA_CTRL   , 2'b00}
`define VGA_HVSIZE_ADDR  {26'b0, `VGA_HVSIZE , 2'b00}
`define VGA_HFPSIZE_ADDR {26'b0, `VGA_HFPSIZE, 2'b00}
`define VGA_HSNSIZE_ADDR {26'b0, `VGA_HSNSIZE, 2'b00}
`define VGA_HBPSIZE_ADDR {26'b0, `VGA_HBPSIZE, 2'b00}
`define VGA_VVSIZE_ADDR  {26'b0, `VGA_VVSIZE , 2'b00}
`define VGA_VFPSIZE_ADDR {26'b0, `VGA_VFPSIZE, 2'b00}
`define VGA_VSNSIZE_ADDR {26'b0, `VGA_VSNSIZE, 2'b00}
`define VGA_VBPSIZE_ADDR {26'b0, `VGA_VBPSIZE, 2'b00}
`define VGA_FBSTART_ADDR {26'b0, `VGA_FBSTART, 2'b00}
`define VGA_FBSIZE_ADDR  {26'b0, `VGA_FBSIZE , 2'b00}

`define VGA_CTRL_WIDTH    21
`define VGA_HVSIZE_WIDTH  16
`define VGA_HFPSIZE_WIDTH 16
`define VGA_HSNSIZE_WIDTH 16
`define VGA_HBPSIZE_WIDTH 16
`define VGA_VVSIZE_WIDTH  16
`define VGA_VFPSIZE_WIDTH 16
`define VGA_VSNSIZE_WIDTH 16
`define VGA_VBPSIZE_WIDTH 16
`define VGA_FBSTART_WIDTH 32
`define VGA_FBSIZE_WIDTH  32

// `define VGA_PSCR_MIN_VAL  {{(`VGA_PSCR_WIDTH-2){1'b0}}, 2'd2}
// verilog_format: on

interface vga_if ();
  logic [4:0] vga_r_o;
  logic [5:0] vga_g_o;
  logic [4:0] vga_b_o;
  logic       vga_hsync_o;
  logic       vga_vsync_o;
  logic       vga_de_o;
  logic       vga_pclk_o;
  logic       irq_o;

  modport dut(
      output vga_r_o,
      output vga_g_o,
      output vga_b_o,
      output vga_hsync_o,
      output vga_vsync_o,
      output vga_de_o,
      output vga_pclk_o,
      output irq_o
  );

  modport tb(
      input vga_r_o,
      input vga_g_o,
      input vga_b_o,
      input vga_hsync_o,
      input vga_vsync_o,
      input vga_de_o,
      input vga_pclk_o,
      input irq_o
  );
endinterface

`endif
