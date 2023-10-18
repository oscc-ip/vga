`ifndef __VGA_TOP__
`define __VGA_TOP__
`include "ping_pong_register.v"
`include "vga_ctrl.v"

module vga_top(
    output wire        data_req_o, // request data from ping pong register
    output wire [ 3:0] red_o,      // rea color
    output wire [ 3:0] green_o,    // green color
    output wire [ 3:0] blue_o,     // blue color
    output reg         vsync_o,    // vertical sync
    output reg         hsync_o,    // horizontal sync
    output reg         blank_o     // vga has valid color output
);

  ping_pong_register 
  #(
    .ADDR_WIDTH (64 ),
    .DATA_WIDTH (64 )
  )
  u_ping_pong_register(
  	.clk_v       (clk_v       ),
    .resetn_v    (resetn_v    ),
    .data_req_i  (data_req_i  ),
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
 	.clk           (clk           ),
    .resetn        (resetn        ),
    .hsync_end_i   (hsync_end_i   ),
    .hpulse_end_i  (hpulse_end_i  ),
    .hdata_begin_i (hdata_begin_i ),
    .hdata_end_i   (hdata_end_i   ),
    .vsync_end_i   (vsync_end_i   ),
    .vpulse_end_i  (vpulse_end_i  ),
    .vdata_begin_i (vdata_begin_i ),
    .vdata_end_i   (vdata_end_i   ),
    .data_i        (data_i        ),
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
