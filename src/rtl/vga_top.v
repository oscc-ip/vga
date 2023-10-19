`ifndef __VGA_TOP__
`define __VGA_TOP__
`include "ping_pong_register.v"
`include "vga_ctrl.v"

module vga_top
#(
    parameter ADDR_WIDTH=64,
    parameter DATA_WIDTH=64
)
(
    
    // ======================= ppr inputs =======================
    input  wire                  clk_v,      // clock with vga block
    input  wire                  resetn_v,
    input  wire                  self_test_i, // VGA self test mode
    // signals with CU(config unit)
    input  wire [ADDR_WIDTH-1:0] base_addr_i,      // SDRAM read base addr
    input  wire [ADDR_WIDTH-1:0] top_addr_i, // memory length
    // signals with AXI bus
    input  wire                  clk_a,      // clock with AXI bus
    input  wire                  resetn_a,      // clock with AXI bus
    input  wire                  arready_i,
    input  wire                  rvalid_i,
    input  wire [1:0]            rresp_i,
    input  wire [DATA_WIDTH-1:0] rdata_i,
    // ====================== ppr outputs =======================
    output reg  [ADDR_WIDTH-1:0] araddr_o,
    output reg  [1:0]            arburst_o,
    output reg  [7:0]            arlen_o,
    output reg  [2:0]            arsize_o,
    output reg                   arvalid_o,
    output reg                   rready_o,
    // ======================= vc outputs =======================
    output wire [ 3:0] red_o,      // rea color
    output wire [ 3:0] green_o,    // green color
    output wire [ 3:0] blue_o,     // blue color
    output reg         vsync_o,    // vertical sync
    output reg         hsync_o,    // horizontal sync
    output reg         blank_o     // vga has valid color output
);


// =========================================================================
// ============================ local variables ============================
// =========================================================================
    wire [11:0] data_o;
    wire        data_req_o;// request data from ping pong register

// =========================================================================
// ============================ implementation =============================
// =========================================================================
  ping_pong_register 
  #(
    .ADDR_WIDTH (ADDR_WIDTH ),
    .DATA_WIDTH (DATA_WIDTH )
  )
  u_ping_pong_register(
  	.clk_v       (clk_v       ),
    .resetn_v    (resetn_v    ),
    .data_req_i  (data_req_o  ),
    .self_test_i (self_test_i ),
    .data_o      (data_o      ),
    .base_addr_i (base_addr_i ),
    .top_addr_i  (top_addr_i  ),
    .clk_a       (clk_a       ),
    .resetn_a    (resetn_a    ),
    .arready_i   (arready_i   ),
    .rvalid_i    (rvalid_i    ),
    .rresp_i     (rresp_i     ),
    .rdata_i     (rdata_i     ),
    .araddr_o    (araddr_o    ),
    .arburst_o   (arburst_o   ),
    .arlen_o     (arlen_o     ),
    .arsize_o    (arsize_o    ),
    .arvalid_o   (arvalid_o   ),
    .rready_o    (rready_o    )
  );

 vga_ctrl u_vga_ctrl(
 	.clk           (clk_v         ),
    .resetn        (resetn_v      ),
    .hsync_end_i   (800 ),
    .hpulse_end_i  (96 ),
    .hdata_begin_i (144 ),
    .hdata_end_i   (784 ),
    .vsync_end_i   (525 ),
    .vpulse_end_i  (2 ),
    .vdata_begin_i (35 ),
    .vdata_end_i   (515 ),
    .data_i        (data_o        ),
    .data_req_o    (data_req_o    ),
    .red_o         (red_o         ),
    .green_o       (green_o       ),
    .blue_o        (blue_o        ),
    .vsync_o       (vsync_o       ),
    .hsync_o       (hsync_o       ),
    .blank_o       (blank_o       )
 );
  
endmodule
`endif
