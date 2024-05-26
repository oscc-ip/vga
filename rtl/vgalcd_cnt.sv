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

module vgalcd_cnt (
    input  logic                            clk_i,
    input  logic                            rst_n_i,
    input  logic                            en_i,
    input  logic [    `VGALCD_TB_WIDTH-1:0] bpsize_i,
    input  logic [    `VGALCD_TB_WIDTH-1:0] snsize_i,
    input  logic [    `VGALCD_TB_WIDTH-1:0] fpsize_i,
    input  logic [    `VGALCD_VB_WIDTH-1:0] vlen_i,
    output logic [`VGALCD_TIMCNT_WIDTH-1:0] cnt_o,
    output logic                            vis_o,
    output logic                            sync_o,
    output logic                            end_o
);

  logic [`VGALCD_TIMFSM_WIDTH-1:0] s_vgalcd_fsm_d, s_vgalcd_fsm_q;
  logic [`VGALCD_TIMCNT_WIDTH-1:0] s_vgalcd_cnt_d, s_vgalcd_cnt_q;
  logic cnt_done;

  assign cnt_done = ~(|s_vgalcd_cnt_q);
  assign cnt_o    = (s_vgalcd_fsm_q == `VGALCD_TIMFSM_VISIBLE) ? s_vgalcd_cnt_q : '0;
  assign vis_o    = s_vgalcd_fsm_q == `VGALCD_TIMFSM_VISIBLE;
  assign sync_o   = s_vgalcd_fsm_q == `VGALCD_TIMFSM_SYNC;
  assign end_o    = s_vgalcd_fsm_q == `VGALCD_TIMFSM_SYNC && cnt_done;

  always_comb begin
    unique case (s_vgalcd_fsm_q)
      `VGALCD_TIMFSM_BACKPORCH:  if (en_i && cnt_done) s_vgalcd_fsm_d = `VGALCD_TIMFSM_VISIBLE;
      `VGALCD_TIMFSM_VISIBLE:    if (en_i && cnt_done) s_vgalcd_fsm_d = `VGALCD_TIMFSM_FRONTPORCH;
      `VGALCD_TIMFSM_FRONTPORCH: if (en_i && cnt_done) s_vgalcd_fsm_d = `VGALCD_TIMFSM_SYNC;
      `VGALCD_TIMFSM_SYNC:       if (en_i && cnt_done) s_vgalcd_fsm_d = `VGALCD_TIMFSM_BACKPORCH;
      default:                   s_vgalcd_fsm_d = `VGALCD_TIMFSM_BACKPORCH;
    endcase
  end
  dffer #(`VGALCD_TIMFSM_WIDTH) u_vgalcd_fsm (
      clk_i,
      rst_n_i,
      en_i && cnt_done,
      s_vgalcd_fsm_d,
      s_vgalcd_fsm_q
  );

  always_comb begin
    s_vgalcd_cnt_d = s_vgalcd_cnt_q - 1'b1;
    unique case (s_vgalcd_fsm_q)
      `VGALCD_TIMFSM_BACKPORCH:  if (en_i && cnt_done) s_vgalcd_cnt_d = vlen_i;
      `VGALCD_TIMFSM_VISIBLE:    if (en_i && cnt_done) s_vgalcd_cnt_d = fpsize_i;
      `VGALCD_TIMFSM_FRONTPORCH: if (en_i && cnt_done) s_vgalcd_cnt_d = snsize_i;
      `VGALCD_TIMFSM_SYNC:       if (en_i && cnt_done) s_vgalcd_cnt_d = bpsize_i;
      default:                   s_vgalcd_cnt_d = '1;
    endcase
  end
  dffer #(`VGALCD_TIMCNT_WIDTH) u_vgalcd_cnt (
      clk_i,
      rst_n_i,
      en_i,
      s_vgalcd_cnt_d,
      s_vgalcd_cnt_q
  );

endmodule
