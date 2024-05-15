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
`include "vga_define.sv"

module axi4_vga #(
    parameter int FIFO_DEPTH = 512
) (
    apb4_if.slave  apb4,
    axi4_if.master axi4,
    vga_if.dut     vga
);

  logic [3:0] s_apb4_addr;
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
  logic [`VGA_STAT_WIDTH-1:0] s_vga_stat_d, s_vga_stat_q;
  // bit signal
  logic s_bit_en, s_bit_hie, s_bit_vie, s_bit_vbsie, s_bit_vbse;
  logic s_bit_blpol, s_bit_hspol, s_bit_vspol, s_bit_test;
  logic s_bit_hif, s_bit_vif, s_bit_vbsif, s_bit_cfb;
  logic [                  1:0] s_bit_mode;
  logic [   `VGA_DIV_WIDTH-1:0] s_bit_div;
  logic [`VGA_BRULEN_WIDTH-1:0] s_bit_brulen;
  logic [`VGA_VB_WIDTH-1:0] s_bit_hvlen, s_bit_vvlen;
  logic [`VGA_TB_WIDTH-1:0] s_bit_hfpsize, s_bit_hsnsize, s_bit_hbpsize;
  logic [`VGA_TB_WIDTH-1:0] s_bit_vfpsize, s_bit_vsnsize, s_bit_vbpsize;
  // ctrl signal
  logic s_hsync, s_vsync;
  // fifo signal
  logic s_tx_push_valid, s_tx_push_ready, s_tx_empty, s_tx_full, s_tx_pop_valid, s_tx_pop_ready;
  logic [63:0] s_tx_push_data, s_tx_pop_data;
  // irq signal
  logic s_cfb, s_vbsirq, s_verirq, s_horirq;

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
  assign s_bit_brulen    = s_vga_ctrl_q[26:19];
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

  assign vga.vga_hsync_o = s_hsync ^ s_bit_hspol;
  assign vga.vga_vsync_o = s_vsync ^ s_bit_vspol;
  assign vga.irq_o       = (s_bit_hie & s_bit_hif) | (s_bit_vie & s_bit_vif);

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

  always_comb begin
    assign s_vga_stat_d[3] = s_cfb;
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
  assign axi4.arsize     = 3'd3;  // dont support narrow trans
  assign axi4.arburst    = 2'd1;  // inc mode
  assign axi4.arlock     = '0;
  assign axi4.arcache    = '0;
  assign axi4.arprot     = '0;
  assign axi4.arqos      = '0;
  assign axi4.arregion   = '0;
  assign axi4.aruser     = '0;

  // control logic signals
  // araddr, arlen, arvalid, arready
  // rid, rdata, rresp, rlast, rvalid, rready


  // vga sync fifo[axi4 -> fifo -> vga_core]
  assign s_tx_push_ready = ~s_tx_full;
  assign s_tx_pop_valid  = ~s_tx_empty;
  fifo #(
      .DATA_WIDTH  (64),
      .BUFFER_DEPTH(FIFO_DEPTH)
  ) u_tx_fifo (
      .clk_i  (axi4.pclk),
      .rst_n_i(axi4.presetn),
      .flush_i(~s_bit_en),
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
      .test_i       (s_bit_test),
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
      .hend_o       (),
      .vsync_o      (s_vsync),
      .vend_o       (),
      .pclk_en_o    (vga.vga_pclk_o),
      .de_o         (vga.vga_de_o)
  );

endmodule
