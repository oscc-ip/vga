`ifndef __CONFIG_UNIT__
`define __CONFIG_UNIT__
// file: vga config unit, used for resolution and address config
// the config is set by *APB Bus*
module config_unit
#(
    parameter DATA_WIDTH=32,
    parameter ADDR_WIDTH=32
)
(
    input  wire clk,
    input  wire resetn,
    // apb related signals
    input  wire [ADDR_WIDTH-1:0] paddr_i,
    input  wire [DATA_WIDTH-1:0] pwdata_i,
    input  wire psel_i,
    input  wire penable_i,
    input  wire pwrite_i,
    output reg  pready_o,
    output reg  [DATA_WIDTH-1:0] prdata_o,
    output reg  pslverr_o,
    // resolution signals, used by Vga Control Unit
    output wire [10:0] hsync_end_o,
    output wire [ 7:0] hpulse_end_o,
    output wire [ 7:0] hdata_begin_o,
    output wire [ 9:0] hdata_end_o,
    output wire [ 9:0] vsync_end_o,
    output wire [ 3:0] vpulse_end_o,
    output wire [ 5:0] vdata_begin_o,
    output wire [ 9:0] vdata_end_o,
    // address signals, used by Ping Pong Register
    output wire [ADDR_WIDTH-1:0] base_addr_o,
    output wire [ADDR_WIDTH-1:0] top_addr_o,
    output wire                  self_test_o
);









// =========================================================================
// ============================ variables =============================
// =========================================================================
    reg [66:0] self_test_resolution;
    reg [66:0] resolution [3:0]; // resolution config registers
    reg [31:0] base_addr, offset; // TODO: address may change to 2*32 bits
    reg [ 1:0] resolution_sel;
    reg        self_test;       // self test mode


// =========================================================================
// ============================ implementation =============================
// =========================================================================
    // APB signals
    always @(posedge clk ) begin 
        if(~resetn) begin
            pready_o       <=  1'h0;    
            pslverr_o      <=  1'h0;
            prdata_o       <= 32'h0;
            base_addr      <= 32'h0;
            offset         <= 32'h0;
            resolution_sel <=  2'h1;
            self_test      <=  1'h1; // enable self_test by default
            //TODO: add resolution config for 480x and so on
            resolution[0]  <= 67'h4e6da4e9fc6c40420;    
            resolution[1]  <= 67'h4071941b884830320;    
            resolution[2]  <= 67'h2386523d192914a0d;    
            resolution[3]  <= 67'h4071941b884830320;    
            self_test_resolution <= 67'h4071941b884830320; // default resolution is 640*480
        end
        else if(psel_i && penable_i) begin
            pready_o  <= 1'h1;    
            if(pwrite_i) begin
                case(paddr_i) 
                    32'h0: begin
                        base_addr <= pwdata_i;
                    end
                    32'h1: begin
                        offset    <= pwdata_i;
                    end
                    32'h2: begin
                        self_test <= pwdata_i[0];
                    end
                    32'h3: begin
                        resolution_sel <= pwdata_i[1:0];
                    end
                endcase
            end
        end
        else begin
            pready_o <= 1'h0;    
        end
    end

    // output resolution
    assign hsync_end_o   = self_test ? self_test_resolution[10: 0]: resolution[resolution_sel][10: 0];
    assign hpulse_end_o  = self_test ? self_test_resolution[18:11]: resolution[resolution_sel][18:11];
    assign hdata_begin_o = self_test ? self_test_resolution[26:19]: resolution[resolution_sel][26:19];
    assign hdata_end_o   = self_test ? self_test_resolution[36:27]: resolution[resolution_sel][36:27];
    assign vsync_end_o   = self_test ? self_test_resolution[46:37]: resolution[resolution_sel][46:37];
    assign vpulse_end_o  = self_test ? self_test_resolution[50:47]: resolution[resolution_sel][50:47];
    assign vdata_begin_o = self_test ? self_test_resolution[56:51]: resolution[resolution_sel][56:51];
    assign vdata_end_o   = self_test ? self_test_resolution[66:57]: resolution[resolution_sel][66:57];
    
    // output address
    assign base_addr_o = base_addr;
    assign top_addr_o  = base_addr+offset;
    assign self_test_o = self_test;
    
endmodule
`endif
