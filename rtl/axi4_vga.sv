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
`include "fifo.sv"
`include "axi4_define.sv"
`include "vga_define.sv"

// BPP: pixel percent trans
`define VGA_RGB332_PPT `AXI4_DATA_BYTES
`define VGA_RGBOTH_PPT (`AXI4_DATA_BYTES / 2)

module axi4_vga #(
    parameter int FIFO_DEPTH = 512
) (
    apb4_if.slave  apb4,
    axi4_if.master axi4,
    vga_if.dut     vga
);
  localparam LOG_FIFO_DEPTH = $clog2(FIFO_DEPTH);

  logic [3:0] s_apb4_addr;
  logic s_apb4_wr_hdshk, s_apb4_rd_hdshk;
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
  logic [`VGA_THOLD_WIDTH-1:0] s_vga_thold_d, s_vga_thold_q;
  logic s_vga_thold_en;
  logic [`VGA_STAT_WIDTH-1:0] s_vga_stat_d, s_vga_stat_q;
  // bit signal
  logic s_bit_en, s_bit_hie, s_bit_vie, s_bit_vbsie, s_bit_vbse;
  logic s_bit_blpol, s_bit_hspol, s_bit_vspol, s_bit_test;
  logic s_bit_hif, s_bit_vif, s_bit_vbsif, s_bit_cfb;
  logic [                  1:0] s_bit_mode;
  logic [   `VGA_DIV_WIDTH-1:0] s_bit_div;
  logic [`VGA_BURLEN_WIDTH-1:0] s_bit_burlen;
  logic [`VGA_VB_WIDTH-1:0] s_bit_hvlen, s_bit_vvlen;
  logic [`VGA_TB_WIDTH-1:0] s_bit_hfpsize, s_bit_hsnsize, s_bit_hbpsize;
  logic [`VGA_TB_WIDTH-1:0] s_bit_vfpsize, s_bit_vsnsize, s_bit_vbpsize;
  // ctrl signal
  logic s_hsync, s_vsync;
  // fifo signal
  logic s_tx_push_valid, s_tx_push_ready, s_tx_empty, s_tx_full, s_tx_pop_valid, s_tx_pop_ready;
  logic [63:0] s_tx_push_data, s_tx_pop_data;
  logic [LOG_FIFO_DEPTH:0] s_tx_elem, s_fifo_rem_len;
  logic [19:0] s_pixel_cnt_d, s_pixel_cnt_q, s_all_pixel_len, s_rem_pixel_len;
  // irq signal
  logic s_vbsirq, s_verirq, s_horirq, s_cfb_d, s_cfb_q;
  logic s_vbsirq_trg, s_verirq_trg, s_horirq_trg;
  // axi4 signal
  logic s_axi4_mst_state_d, s_axi4_mst_state_q;
  logic s_axi4_ar_hdshk, s_axi4_r_hdshk;
  logic [31:0] s_axi4_addr_d, s_axi4_addr_q;
  logic [7:0] s_axi4_arlen_d, s_axi4_arlen_q;
  logic s_norm_mode;

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
  assign s_bit_burlen    = s_vga_ctrl_q[26:19];
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

  assign s_norm_mode     = s_bit_en && ~s_bit_test;

  assign vga.vga_hsync_o = s_hsync ^ s_bit_hspol;
  assign vga.vga_vsync_o = s_vsync ^ s_bit_vspol;

  assign s_horirq_trg    = s_bit_hie & s_bit_hif;
  assign s_verirq_trg    = s_bit_vie & s_bit_vif;
  assign s_vbsirq_trg    = s_bit_vbse & s_bit_vbsif;
  assign vga.irq_o       = s_horirq_trg | s_verirq_trg | s_vbsirq_trg;

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

  assign s_vga_thold_en = s_apb4_wr_hdshk && s_apb4_addr == `VGA_THOLD;
  assign s_vga_thold_d  = apb4.pwdata[`VGA_THOLD_WIDTH-1:0];
  dffer #(`VGA_THOLD_WIDTH) u_vga_thold_dffer (
      apb4.pclk,
      apb4.presetn,
      s_vga_thold_en,
      s_vga_thold_d,
      s_vga_thold_q
  );

  always_comb begin
    s_vga_stat_d[3] = s_cfb_q;
    // xx_irq_i has higher priority, when xx_irq_i is 1, dont care other signal
    // when xx_irq_i is 0, if xx_if is 0, write 0/1 no effect
    // when xx_irq_i is 0, if xx_if is 1, write 0 clear bit, write 1 no effect
    if (s_apb4_wr_hdshk && s_apb4_addr == `VGA_STAT) begin
      s_vga_stat_d[2] = s_vbsirq | (s_vga_stat_q[2] & apb4.pwdata[2]);
      s_vga_stat_d[1] = s_verirq | (s_vga_stat_q[1] & apb4.pwdata[1]);
      s_vga_stat_d[0] = s_horirq | (s_vga_stat_q[0] & apb4.pwdata[0]);
    end else begin
      // irq signal only keep trigger one cycle
      s_vga_stat_d[2] = s_vga_stat_q[2] | s_vbsirq;
      s_vga_stat_d[1] = s_vga_stat_q[1] | s_verirq;
      s_vga_stat_d[0] = s_vga_stat_q[0] | s_horirq;
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
        `VGA_THOLD: apb4.prdata[`VGA_THOLD_WIDTH-1:0] = s_vga_thold_q;
        `VGA_STAT:  apb4.prdata[`VGA_STAT_WIDTH-1:0] = s_vga_stat_q;
        default:    apb4.prdata = '0;
      endcase
    end
  end

  // vga master interface[fetch data]
  // dont use aw, w and b chnl
  assign axi4.awid       = '0;
  assign axi4.awaddr     = '0;
  assign axi4.awlen      = '0;
  assign axi4.awsize     = '0;
  assign axi4.awburst    = '0;
  assign axi4.awlock     = '0;
  assign axi4.awcache    = '0;
  assign axi4.awprot     = '0;
  assign axi4.awqos      = '0;
  assign axi4.awregion   = '0;
  assign axi4.awuser     = '0;
  assign axi4.awvalid    = '0;
  assign axi4.wdata      = '0;
  assign axi4.wstrb      = '0;
  assign axi4.wlast      = '0;
  assign axi4.wuser      = '0;
  assign axi4.wvalid     = '0;
  assign axi4.bready     = '0;
  // ar, r chnl
  assign axi4.arid       = '0;
  assign axi4.araddr     = s_axi4_addr_q;
  assign axi4.arsize     = 3'd3;  // dont support narrow trans
  assign axi4.arburst    = 2'd1;  // inc mode
  assign axi4.arlock     = '0;
  assign axi4.arcache    = '0;
  assign axi4.arprot     = '0;
  assign axi4.arqos      = '0;
  assign axi4.arregion   = '0;
  assign axi4.aruser     = '0;
  // verilog_format: off
  assign axi4.arvalid    = s_norm_mode && s_tx_push_ready && s_axi4_mst_state_q == `VGA_AXI_MST_FSM_AR && (s_tx_elem <= s_vga_thold_q);
  assign axi4.rready     = 1'b1;
  // verilog_format: on

  assign s_axi4_ar_hdshk = axi4.arvalid && axi4.arready;
  assign s_axi4_r_hdshk  = axi4.rvalid && axi4.rready;

  assign s_fifo_rem_len  = FIFO_DEPTH - s_tx_elem;
  assign s_all_pixel_len = s_bit_mode == `VGA_RGB332_MODE ?
                           (s_bit_hvlen+1) * (s_bit_vvlen + 1) / `VGA_RGB332_PPT : (s_bit_hvlen + 1) * (s_bit_vvlen + 1) / `VGA_RGBOTH_PPT;
  assign s_rem_pixel_len = s_all_pixel_len - s_pixel_cnt_q;
  // control logic signals
  // [araddr, arlen, arvalid, arready]
  // [rid, rdata, rresp, rlast, rvalid]
  always_comb begin
    if (s_norm_mode) begin
      s_axi4_mst_state_d = s_axi4_mst_state_q;
      s_axi4_addr_d      = s_axi4_addr_q;
      s_axi4_arlen_d     = s_axi4_arlen_q;
      s_pixel_cnt_d      = s_pixel_cnt_q;
      s_cfb_d            = s_cfb_q;
      axi4.arlen         = s_axi4_addr_q;
      s_vbsirq           = '0;
      unique case (s_axi4_mst_state_q)
        `VGA_AXI_MST_FSM_AR: begin
          if (s_axi4_ar_hdshk) begin
            // $display("s_rem_pixel_len: %h", s_rem_pixel_len);
            s_axi4_mst_state_d = `VGA_AXI_MST_FSM_R;
            if (s_rem_pixel_len < s_fifo_rem_len) begin  // aligned to the one frame bound
              axi4.arlen = (s_rem_pixel_len - 1 < s_bit_burlen) ? s_rem_pixel_len - 1 : s_bit_burlen;
            end else begin
              axi4.arlen = (s_fifo_rem_len - 1 < s_bit_burlen) ? s_fifo_rem_len - 1 : s_bit_burlen;
            end
            s_axi4_arlen_d = axi4.arlen;
            // $display("axi4.arlen: %d val: %d", axi4.arlen, axi4.arlen * 8);
          end
        end
        `VGA_AXI_MST_FSM_R: begin
          if (s_axi4_r_hdshk && axi4.rlast) begin
            s_axi4_mst_state_d = `VGA_AXI_MST_FSM_AR;
            if (s_rem_pixel_len - 1 == s_axi4_arlen_q) begin
              s_pixel_cnt_d = '0;
              s_axi4_addr_d = s_cfb_q ? s_vga_fbba1_q : s_vga_fbba2_q;
              s_cfb_d       = s_cfb_q ^ s_bit_vbse;
              s_vbsirq      = 1'b1;
              // if(s_cfb_q == 1'b1) $finish;
            end else begin
              if (s_bit_mode == `VGA_RGB332_MODE) begin
                s_pixel_cnt_d = s_pixel_cnt_q + s_axi4_arlen_q + 1;
              end else begin
                s_pixel_cnt_d = s_pixel_cnt_q + s_axi4_arlen_q + 1;
              end
              s_axi4_addr_d = s_axi4_addr_q + (s_axi4_arlen_q + 1) * `AXI4_DATA_BYTES;
              // $display("axi4_addr: %h arlen: %h", s_axi4_addr_q, s_axi4_arlen_q);
            end
          end
        end
      endcase
    end else begin
      s_axi4_mst_state_d = `VGA_AXI_MST_FSM_AR;
      s_axi4_addr_d      = s_vga_fbba1_q;
      s_axi4_arlen_d     = s_bit_burlen;
      s_pixel_cnt_d      = s_pixel_cnt_q;
      s_cfb_d            = s_cfb_q;
      axi4.arlen         = s_bit_burlen;
      s_vbsirq           = '0;
    end
  end
  dffer #(1) u_axi4_mst_state_dffer (
      axi4.aclk,
      axi4.aresetn,
      s_norm_mode,
      s_axi4_mst_state_d,
      s_axi4_mst_state_q
  );

  dffr #(32) u_axi4_addr_dffr (
      axi4.aclk,
      axi4.aresetn,
      s_axi4_addr_d,
      s_axi4_addr_q
  );

  dffr #(8) u_axi4_arlen_dffr (
      axi4.aclk,
      axi4.aresetn,
      s_axi4_arlen_d,
      s_axi4_arlen_q
  );

  dffer #(20) u_pixel_cnt_dffer (
      axi4.aclk,
      axi4.aresetn,
      s_norm_mode,
      s_pixel_cnt_d,
      s_pixel_cnt_q
  );

  dffer #(1) u_cfb_dffer (
      axi4.aclk,
      axi4.aresetn,
      s_norm_mode,
      s_cfb_d,
      s_cfb_q
  );

  // tx sync fifo[axi4 -> fifo -> vga_core]
  // verilog_format: off
  assign s_tx_push_valid = s_norm_mode && s_axi4_mst_state_q == `VGA_AXI_MST_FSM_R && s_axi4_r_hdshk;
  assign s_tx_push_data  = axi4.rdata;
  assign s_tx_push_ready = ~s_tx_full;
  assign s_tx_pop_valid  = ~s_tx_empty;
  // verilog_format: on
  fifo #(
      .DATA_WIDTH  (64),
      .BUFFER_DEPTH(FIFO_DEPTH)
  ) u_tx_fifo (
      .clk_i  (axi4.aclk),
      .rst_n_i(axi4.aresetn),
      .flush_i(~s_norm_mode),
      .cnt_o  (s_tx_elem),
      .push_i (s_tx_push_valid),
      .full_o (s_tx_full),
      .dat_i  (s_tx_push_data),
      .pop_i  (s_tx_pop_ready),
      .empty_o(s_tx_empty),
      .dat_o  (s_tx_pop_data)
  );

  // gen sync and rgb signals
  vga_core u_vga_core (
      .clk_i        (axi4.aclk),
      .rst_n_i      (axi4.aresetn),
      .en_i         (s_bit_en),
      .div_i        (s_bit_div),
      .test_i       (s_bit_test),
      .mode_i       (s_bit_mode),
      .hbpsize_i    (s_bit_hbpsize),
      .hsnsize_i    (s_bit_hsnsize),
      .hfpsize_i    (s_bit_hfpsize),
      .hvlen_i      (s_bit_hvlen),
      .vbpsize_i    (s_bit_vbpsize),
      .vsnsize_i    (s_bit_vsnsize),
      .vfpsize_i    (s_bit_vfpsize),
      .vvlen_i      (s_bit_vvlen),
      .pixel_valid_i(s_tx_pop_valid),
      .pixel_ready_o(s_tx_pop_ready),
      .pixel_data_i (s_tx_pop_data),
      .vga_r_o      (vga.vga_r_o),
      .vga_g_o      (vga.vga_g_o),
      .vga_b_o      (vga.vga_b_o),
      .hsync_o      (s_hsync),
      .hend_o       (s_horirq),
      .vsync_o      (s_vsync),
      .vend_o       (s_verirq),
      .pclk_o       (vga.vga_pclk_o),
      .de_o         (vga.vga_de_o)
  );

endmodule
