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
// Copyright (c) 2023-2024 Miao Yuchi <miaoyuchi@ict.ac.cn>
// vgalcd is licensed under Mulan PSL v2.
// You can use this software according to the terms and conditions of the Mulan PSL v2.
// You may obtain a copy of Mulan PSL v2 at:
//             http://license.coscl.org.cn/MulanPSL2
// THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
// EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
// MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
// See the Mulan PSL v2 for more details.

`ifndef INC_VGALCD_DEF_SV
`define INC_VGALCD_DEF_SV

// RGB MODE: RGB565(VGA or LCD) RGB555 RGB444 RGB332
// RES: 
//      VGA: 640x350@70(25M)
//           640x400@70(25M)
//           640x480@60(25M)
//           800x600@60(40M)
//           800x600@72(50M)
//      LCD: 480x272@60(9M)    tolerance: 8~12M
//           480x480@60(16M)   tolerance: 8~12M
//           800x480@60(33.3M) tolerance: 30~50M
//           1024x600@60(50M)

/* register mapping
 * VGALCD_CTRL:
 * BITS:   | 31:27 | 26:19  | 18:17 | 16   | 15:8 | 7     | 6     | 5     | 4    | 3     | 2   | 1   | 0  |
 * FIELDS: | RES   | BURLEN | MODE  | TEST | DIV  | VSPOL | HSPOL | BLPOL | VBSE | VBSIE | VIE | HIE | EN |
 * PERMS:  | NONE  | RW     | RW    | RW   | RW   | RW    | RW    | RW    | RW   | RW    | RW  | RW  | RW |
 * --------------------------------------------------------------------------------------------------------
 * VGALCD_HVVL:
 * BITS:   | 31:16 | 15:0  |
 * FIELDS: | VVLEN | HVLEN |
 * PERMS:  | RW    | RW    |
 * --------------------------------------------------------------------------------------------------------
 * VGALCD_HTIM:
 * BITS:   | 31:30 | 29:20   | 19:10   | 9:0     |
 * FIELDS: | RES   | HBPSIZE | HSNSIZE | HFPSIZE |
 * PERMS:  | NONE  | RW      | RW      | RW      |
 * --------------------------------------------------------------------------------------------------------
 * VGALCD_VTIM:
 * BITS:   | 31:30 | 29:20   | 19:10   | 9:0     |
 * FIELDS: | RES   | VBPSIZE | VSNSIZE | VFPSIZE |
 * PERMS:  | NONE  | RW      | RW      | RW      |
 * --------------------------------------------------------------------------------------------------------
 * VGALCD_FBBA1:
 * BITS:   | 31:0  |
 * FIELDS: | FBBA1 |
 * PERMS:  | RW    |
 * --------------------------------------------------------------------------------------------------------
 * VGALCD_FBBA2:
 * BITS:   | 31:0  |
 * FIELDS: | FBBA2 |
 * PERMS:  | RW    |
 * --------------------------------------------------------------------------------------------------------
 * VGALCD_THOLD:
 * BITS:   | 31:10 | 9:0   |
 * FIELDS: | RES   | THOLD |
 * PERMS:  | NONE  | RW    |
 * --------------------------------------------------------------------------------------------------------
 * VGALCD_STAT:
 * BITS:   | 31:4 | 3   | 2      | 1      | 0      |
 * FIELDS: | RES  | CFB | VBSIF  | VIF    | HIF    |
 * PERMS:  | NONE | RO  | RO_W0C | RO_W0C | RO_W0C |
 * --------------------------------------------------------------------------------------------------------
*/

// verilog_format: off
`define VGALCD_CTRL  4'b0000 // BASEADDR + 0x00
`define VGALCD_HVVL  4'b0001 // BASEADDR + 0x04
`define VGALCD_HTIM  4'b0010 // BASEADDR + 0x08
`define VGALCD_VTIM  4'b0011 // BASEADDR + 0x0C
`define VGALCD_FBBA1 4'b0100 // BASEADDR + 0x10
`define VGALCD_FBBA2 4'b0101 // BASEADDR + 0x14
`define VGALCD_THOLD 4'b0110 // BASEADDR + 0x18
`define VGALCD_STAT  4'b0111 // BASEADDR + 0x1C


`define VGALCD_CTRL_ADDR  {26'b0, `VGALCD_CTRL , 2'b00}
`define VGALCD_HVVL_ADDR  {26'b0, `VGALCD_HVVL , 2'b00}
`define VGALCD_HTIM_ADDR  {26'b0, `VGALCD_HTIM , 2'b00}
`define VGALCD_VTIM_ADDR  {26'b0, `VGALCD_VTIM , 2'b00}
`define VGALCD_FBBA1_ADDR {26'b0, `VGALCD_FBBA1, 2'b00}
`define VGALCD_FBBA2_ADDR {26'b0, `VGALCD_FBBA2, 2'b00}
`define VGALCD_THOLD_ADDR {26'b0, `VGALCD_THOLD, 2'b00}
`define VGALCD_STAT_ADDR  {26'b0, `VGALCD_STAT , 2'b00}

`define VGALCD_CTRL_WIDTH  27
`define VGALCD_HVVL_WIDTH  32
`define VGALCD_HTIM_WIDTH  30
`define VGALCD_VTIM_WIDTH  30
`define VGALCD_FBBA1_WIDTH 32
`define VGALCD_FBBA2_WIDTH 32
`define VGALCD_THOLD_WIDTH 10
`define VGALCD_STAT_WIDTH  4

`define VGALCD_TB_WIDTH      10 // timing bitfield width
`define VGALCD_VB_WIDTH      16 // visible bitfield width
`define VGALCD_DIV_WIDTH     8
`define VGALCD_BURLEN_WIDTH  8
`define VGALCD_THOLD_WIDTH   10

`define VGALCD_RGB332_MODE 2'b00
`define VGALCD_RGB444_MODE 2'b01
`define VGALCD_RGB555_MODE 2'b10
`define VGALCD_RGB565_MODE 2'b11
// `define VGALCD_PSCR_MIN_VAL  {{(`VGALCD_PSCR_WIDTH-2){1'b0}}, 2'd2}
// verilog_format: on

`define VGALCD_RGB332_COLOR_RED     8'hE0
`define VGALCD_RGB332_COLOR_ORANGE  8'hF0
`define VGALCD_RGB332_COLOR_YELLOW  8'hFC
`define VGALCD_RGB332_COLOR_GREEN   8'h1C
`define VGALCD_RGB332_COLOR_CYAN    8'h1F
`define VGALCD_RGB332_COLOR_BLUE    8'h03
`define VGALCD_RGB332_COLOR_PURPPLE 8'hE3
`define VGALCD_RGB332_COLOR_BLACK   8'h00
`define VGALCD_RGB332_COLOR_WHITE   8'hFF
`define VGALCD_RGB332_COLOR_GRAY    8'h92

`define VGALCD_RGB444_COLOR_RED     12'hF00
`define VGALCD_RGB444_COLOR_ORANGE  12'hF80
`define VGALCD_RGB444_COLOR_YELLOW  12'hFF0
`define VGALCD_RGB444_COLOR_GREEN   12'h0F0
`define VGALCD_RGB444_COLOR_CYAN    12'h0FF
`define VGALCD_RGB444_COLOR_BLUE    12'h00F
`define VGALCD_RGB444_COLOR_PURPPLE 12'hF0F
`define VGALCD_RGB444_COLOR_BLACK   12'h000
`define VGALCD_RGB444_COLOR_WHITE   12'hFFF
`define VGALCD_RGB444_COLOR_GRAY    12'h888

// u16 b = rgb565_val & 0x1F;
// u16 g = ((rgb565_val >> 5) & 0x3F) >> 1;
// u16 r = (rgb565_val >> 11) & 0x1F;
// u16 tmp = (r << 10) | (g << 5) | b;
`define VGALCD_RGB555_COLOR_RED     15'h7C00
`define VGALCD_RGB555_COLOR_ORANGE  15'h7E00
`define VGALCD_RGB555_COLOR_YELLOW  15'h7FE0
`define VGALCD_RGB555_COLOR_GREEN   15'h03E0
`define VGALCD_RGB555_COLOR_CYAN    15'h03FF
`define VGALCD_RGB555_COLOR_BLUE    15'h001F
`define VGALCD_RGB555_COLOR_PURPPLE 15'h7C1F
`define VGALCD_RGB555_COLOR_BLACK   15'h0000
`define VGALCD_RGB555_COLOR_WHITE   15'h7FFF
`define VGALCD_RGB555_COLOR_GRAY    15'h6B5A

`define VGALCD_RGB565_COLOR_RED     16'hF800
`define VGALCD_RGB565_COLOR_ORANGE  16'hFC00
`define VGALCD_RGB565_COLOR_YELLOW  16'hFFE0
`define VGALCD_RGB565_COLOR_GREEN   16'h07E0
`define VGALCD_RGB565_COLOR_CYAN    16'h07FF
`define VGALCD_RGB565_COLOR_BLUE    16'h001F
`define VGALCD_RGB565_COLOR_PURPPLE 16'hF81F
`define VGALCD_RGB565_COLOR_BLACK   16'h0000
`define VGALCD_RGB565_COLOR_WHITE   16'hFFFF
`define VGALCD_RGB565_COLOR_GRAY    16'hD69A

`define VGALCD_TIMFSM_WIDTH         2
`define VGALCD_TIMFSM_BACKPORCH     2'b00
`define VGALCD_TIMFSM_VISIBLE       2'b01
`define VGALCD_TIMFSM_FRONTPORCH    2'b10
`define VGALCD_TIMFSM_SYNC          2'b11

`define VGALCD_TIMCNT_WIDTH         12
`define VGALCD_AXI_MST_FSM_AR       1'b0
`define VGALCD_AXI_MST_FSM_R        1'b1

interface vgalcd_if ();
  logic [4:0] vgalcd_r_o;
  logic [5:0] vgalcd_g_o;
  logic [4:0] vgalcd_b_o;
  logic       vgalcd_hsync_o;
  logic       vgalcd_vsync_o;
  logic       vgalcd_de_o;
  logic       vgalcd_pclk_o;
  logic       irq_o;

  modport dut(
      output vgalcd_r_o,
      output vgalcd_g_o,
      output vgalcd_b_o,
      output vgalcd_hsync_o,
      output vgalcd_vsync_o,
      output vgalcd_de_o,
      output vgalcd_pclk_o,
      output irq_o
  );

  modport tb(
      input vgalcd_r_o,
      input vgalcd_g_o,
      input vgalcd_b_o,
      input vgalcd_hsync_o,
      input vgalcd_vsync_o,
      input vgalcd_de_o,
      input vgalcd_pclk_o,
      input irq_o
  );
endinterface

`endif
