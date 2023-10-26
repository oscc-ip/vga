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
    output wire [ 8:0] vsync_end_o,
    output wire [ 2:0] vpulse_end_o,
    output wire [ 4:0] vdata_begin_o,
    output wire [ 8:0] vdata_end_o,
    // address signals, used by Ping Pong Register
    output wire [ADDR_WIDTH-1:0] base_addr_o,
    output wire [ADDR_WIDTH-1:0] top_addr_o,
    output wire                  self_test_o
);


// =========================================================================
// ============================ variables =============================
// =========================================================================
    reg [62:0] self_test_resolution;
    reg [63:0] resolution [3:0]; // resolution config registers
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
            resolution_sel <=  2'h0;
            self_test      <=  1'h0;
            resolution[0]  <= 64'h0;    
            resolution[1]  <= 64'h0;    
            resolution[2]  <= 64'h0;    
            resolution[3]  <= 64'h0;    
            self_test_resolution <= 63'h8106c1b884830320;
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
                    32'h4: begin
                        resolution[0][31: 0] <= pwdata_i;
                    end
                    32'h5: begin
                        resolution[0][63:32] <= pwdata_i;
                    end
                    32'h6: begin
                        resolution[1][31: 0] <= pwdata_i;
                    end
                    32'h7: begin
                        resolution[1][63:32] <= pwdata_i;
                    end
                    32'h8: begin
                        resolution[2][31: 0] <= pwdata_i;
                    end
                    32'h9: begin
                        resolution[2][63:32] <= pwdata_i;
                    end
                    32'ha: begin
                        resolution[3][31: 0] <= pwdata_i;
                    end
                    32'hb: begin
                        resolution[3][63:32] <= pwdata_i;
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
    assign vsync_end_o   = self_test ? self_test_resolution[45:37]: resolution[resolution_sel][45:37];
    assign vpulse_end_o  = self_test ? self_test_resolution[48:46]: resolution[resolution_sel][48:46];
    assign vdata_begin_o = self_test ? self_test_resolution[53:49]: resolution[resolution_sel][53:49];
    assign vdata_end_o   = self_test ? self_test_resolution[62:54]: resolution[resolution_sel][62:54];
    
    // output address
    assign base_addr_o = base_addr;
    assign top_addr_o  = base_addr+offset;
    assign self_test_o = self_test;
    
endmodule
`endif
