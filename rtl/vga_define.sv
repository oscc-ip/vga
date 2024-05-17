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

`ifndef INC_VGA_DEF_SV
`define INC_VGA_DEF_SV

// RGB MODE: RGB565(VGA or LCD) RGB555 RGB444 RGB332
// RES: 
//      VGA: 640x350@70(25M) 640x400@70(25M) 640x480@60(25M)
//           800x600@60(40M) 800x600@72(50M)
//      LCD: 480x272 800x480

/* register mapping
 * VGA_CTRL:
 * BITS:   | 31:27 | 26:19  | 18:17 | 16   | 15:8 | 7     | 6     | 5     | 4    | 3     | 2   | 1   | 0  |
 * FIELDS: | RES   | BRULEN | MODE  | TEST | DIV  | VSPOL | HSPOL | BLPOL | VBSE | VBSIE | VIE | HIE | EN |
 * PERMS:  | NONE  | RW     | RW    | RW   | RW   | RW    | RW    | RW    | RW   | RW    | RW  | RW  | RW |
 * --------------------------------------------------------------------------------------------------------
 * VGA_HVVL:
 * BITS:   | 31:16 | 15:0  |
 * FIELDS: | VVLEN | HVLEN |
 * PERMS:  | RW    | RW    |
 * --------------------------------------------------------------------------------------------------------
 * VGA_HTIM:
 * BITS:   | 31:30 | 29:20   | 19:10   | 9:0     |
 * FIELDS: | RES   | HBPSIZE | HSNSIZE | HFPSIZE |
 * PERMS:  | NONE  | RW      | RW      | RW      |
 * --------------------------------------------------------------------------------------------------------
 * VGA_VTIM:
 * BITS:   | 31:30 | 29:20   | 19:10   | 9:0     |
 * FIELDS: | RES   | VBPSIZE | VSNSIZE | VFPSIZE |
 * PERMS:  | NONE  | RW      | RW      | RW      |
 * --------------------------------------------------------------------------------------------------------
 * VGA_FBBA1:
 * BITS:   | 31:0  |
 * FIELDS: | FBBA1 |
 * PERMS:  | RW    |
 * --------------------------------------------------------------------------------------------------------
 * VGA_FBBA2:
 * BITS:   | 31:0  |
 * FIELDS: | FBBA2 |
 * PERMS:  | RW    |
 * --------------------------------------------------------------------------------------------------------
 * VGA_STAT:
 * BITS:   | 31:4 | 3   | 2      | 1      | 0      |
 * FIELDS: | RES  | CFB | VBSIF  | VIF    | HIF    |
 * PERMS:  | NONE | RO  | RO_W0C | RO_W0C | RO_W0C |
 * --------------------------------------------------------------------------------------------------------
*/

// verilog_format: off
`define VGA_CTRL  4'b0000 // BASEADDR + 0x00
`define VGA_HVVL  4'b0001 // BASEADDR + 0x04
`define VGA_HTIM  4'b0010 // BASEADDR + 0x08
`define VGA_VTIM  4'b0011 // BASEADDR + 0x0C
`define VGA_FBBA1 4'b0100 // BASEADDR + 0x10
`define VGA_FBBA2 4'b0101 // BASEADDR + 0x14
`define VGA_STAT  4'b0110 // BASEADDR + 0x18


`define VGA_CTRL_ADDR  {26'b0, `VGA_CTRL , 2'b00}
`define VGA_HVVL_ADDR  {26'b0, `VGA_HVVL , 2'b00}
`define VGA_HTIM_ADDR  {26'b0, `VGA_HTIM , 2'b00}
`define VGA_VTIM_ADDR  {26'b0, `VGA_VTIM , 2'b00}
`define VGA_FBBA1_ADDR {26'b0, `VGA_FBBA1, 2'b00}
`define VGA_FBBA2_ADDR {26'b0, `VGA_FBBA2, 2'b00}
`define VGA_STAT_ADDR  {26'b0, `VGA_STAT , 2'b00}

`define VGA_CTRL_WIDTH  27
`define VGA_HVVL_WIDTH  32
`define VGA_HTIM_WIDTH  30
`define VGA_VTIM_WIDTH  30
`define VGA_FBBA1_WIDTH 32
`define VGA_FBBA2_WIDTH 32
`define VGA_STAT_WIDTH  4

`define VGA_TB_WIDTH      10 // timing bitfield width
`define VGA_VB_WIDTH      16 // visible bitfield width
`define VGA_DIV_WIDTH     8
`define VGA_BRULEN_WIDTH  8


`define VGA_RGB332_MODE 2'b00
`define VGA_RGB444_MODE 2'b01
`define VGA_RGB555_MODE 2'b10
`define VGA_RGB565_MODE 2'b11
// `define VGA_PSCR_MIN_VAL  {{(`VGA_PSCR_WIDTH-2){1'b0}}, 2'd2}
// verilog_format: on

`define VGA_RGB332_COLOR_RED     8'hE0;
`define VGA_RGB332_COLOR_ORANGE  8'hF0;
`define VGA_RGB332_COLOR_YELLOW  8'hFC;
`define VGA_RGB332_COLOR_GREEN   8'h1C;
`define VGA_RGB332_COLOR_CYAN    8'h1F;
`define VGA_RGB332_COLOR_BLUE    8'h03;
`define VGA_RGB332_COLOR_PURPPLE 8'hE3;
`define VGA_RGB332_COLOR_BLACK   8'h00;
`define VGA_RGB332_COLOR_WHITE   8'hFF;
`define VGA_RGB332_COLOR_GRAY    8'h92;

`define VGA_RGB444_COLOR_RED     12'hF00;
`define VGA_RGB444_COLOR_ORANGE  12'hF80;
`define VGA_RGB444_COLOR_YELLOW  12'hFF0;
`define VGA_RGB444_COLOR_GREEN   12'h0F0;
`define VGA_RGB444_COLOR_CYAN    12'h0FF;
`define VGA_RGB444_COLOR_BLUE    12'h00F;
`define VGA_RGB444_COLOR_PURPPLE 12'hF0F;
`define VGA_RGB444_COLOR_BLACK   12'h000;
`define VGA_RGB444_COLOR_WHITE   12'hFFF;
`define VGA_RGB444_COLOR_GRAY    12'h888;

// u16 b = rgb565_val & 0x1F;
// u16 g = ((rgb565_val >> 5) & 0x3F) >> 1;
// u16 r = (rgb565_val >> 11) & 0x1F;
// u16 tmp = (r << 10) | (g << 5) | b;
`define VGA_RGB555_COLOR_RED     15'h7C00;
`define VGA_RGB555_COLOR_ORANGE  15'h7E00;
`define VGA_RGB555_COLOR_YELLOW  15'h7FE0;
`define VGA_RGB555_COLOR_GREEN   15'h03E0;
`define VGA_RGB555_COLOR_CYAN    15'h03FF;
`define VGA_RGB555_COLOR_BLUE    15'h001F;
`define VGA_RGB555_COLOR_PURPPLE 15'h7C1F;
`define VGA_RGB555_COLOR_BLACK   15'h0000;
`define VGA_RGB555_COLOR_WHITE   15'h7FFF;
`define VGA_RGB555_COLOR_GRAY    15'h6B5A;

`define VGA_RGB565_COLOR_RED     16'hF800;
`define VGA_RGB565_COLOR_ORANGE  16'hFC00;
`define VGA_RGB565_COLOR_YELLOW  16'hFFE0;
`define VGA_RGB565_COLOR_GREEN   16'h07E0;
`define VGA_RGB565_COLOR_CYAN    16'h07FF;
`define VGA_RGB565_COLOR_BLUE    16'h001F;
`define VGA_RGB565_COLOR_PURPPLE 16'hF81F;
`define VGA_RGB565_COLOR_BLACK   16'h0000;
`define VGA_RGB565_COLOR_WHITE   16'hFFFF;
`define VGA_RGB565_COLOR_GRAY    16'hD69A;

`define VGA_TIMFSM_WIDTH         2
`define VGA_TIMFSM_BACKPORCH     2'b00
`define VGA_TIMFSM_VISIBLE       2'b01
`define VGA_TIMFSM_FRONTPORCH    2'b10
`define VGA_TIMFSM_SYNC          2'b11

`define VGA_TIMCNT_WIDTH         12
`define VGA_AXI_MST_FSM_AR       1'b0
`define VGA_AXI_MST_FSM_R        1'b1

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
