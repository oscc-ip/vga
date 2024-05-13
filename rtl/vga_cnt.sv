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

module vga_cnt (
    input  logic                     clk_i,
    input  logic                     rst_n_i,
    input  logic                     en_i,
    input  logic [`VGA_TB_WIDTH-1:0] bpsize_i,
    input  logic [`VGA_TB_WIDTH-1:0] snsize_i,
    input  logic [`VGA_TB_WIDTH-1:0] fpsize_i,
    input  logic [`VGA_VB_WIDTH-1:0] vlen_i,
    output logic                     vis_o,
    output logic                     sync_o,
    output logic                     end_o
);

  logic [`VGA_TIMFSM_WIDTH-1:0] s_vga_fsm_d, s_vga_fsm_q;
  logic [`VGA_TIMCNT_WIDTH-1:0] s_vga_cnt_d, s_vga_cnt_q;
  logic cnt_done;

  assign cnt_done = ~(|s_vga_cnt_q);
  assign vis_o    = s_vga_fsm_q == `VGA_TIMFSM_VISIBLE;
  assign sync_o   = s_vga_fsm_q == `VGA_TIMFSM_SYNC;
  assign end_o    = s_vga_fsm_q == `VGA_TIMFSM_SYNC && cnt_done;

  always_comb begin
    unique case (s_vga_fsm_q)
      `VGA_TIMFSM_BACKPORCH:  if (en_i && cnt_done) s_vga_fsm_d = `VGA_TIMFSM_VISIBLE;
      `VGA_TIMFSM_VISIBLE:    if (en_i && cnt_done) s_vga_fsm_d = `VGA_TIMFSM_FRONTPORCH;
      `VGA_TIMFSM_FRONTPORCH: if (en_i && cnt_done) s_vga_fsm_d = `VGA_TIMFSM_SYNC;
      `VGA_TIMFSM_SYNC:       if (en_i && cnt_done) s_vga_fsm_d = `VGA_TIMFSM_VISIBLE;
      default:                s_vga_fsm_d = `VGA_TIMFSM_BACKPORCH;
    endcase
  end
  dffer #(`VGA_TIMFSM_WIDTH) u_vga_fsm (
      clk_i,
      rst_n_i,
      en_i && cnt_done,
      s_vga_fsm_d,
      s_vga_fsm_q
  );

  always_comb begin
    s_vga_cnt_d = s_vga_cnt_q;
    unique case (s_vga_fsm_q)
      `VGA_TIMFSM_BACKPORCH:  if (en_i && cnt_done) s_vga_cnt_d = vlen_i;
      `VGA_TIMFSM_VISIBLE:    if (en_i && cnt_done) s_vga_cnt_d = fpsize_i;
      `VGA_TIMFSM_FRONTPORCH: if (en_i && cnt_done) s_vga_cnt_d = snsize_i;
      `VGA_TIMFSM_SYNC:       if (en_i && cnt_done) s_vga_cnt_d = bpsize_i;
      default:                s_vga_cnt_d = '0;
    endcase
  end
  dffer #(`VGA_TIMCNT_WIDTH) u_vga_cnt (
      clk_i,
      rst_n_i,
      en_i && cnt_done,
      s_vga_cnt_d,
      s_vga_cnt_q
  );

endmodule
