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
    output wire [ADDR_WIDTH-1:0] top_addr_o
);


// =========================================================================
// ============================ variables =============================
// =========================================================================
    reg [63:0] resolution [3:0]; // resolution config registers
    reg [31:0] base_addr, top_addr;
    reg [ 1:0] resolution_sel;


// =========================================================================
// ============================ implementation =============================
// =========================================================================
    // pre-defined resolution 
    always @(posedge clk ) begin 
        if(~resetn) begin
            resolution[0] <= 64'h0;    
            resolution[1] <= 64'h0;    
            resolution[2] <= 64'h0;    
            resolution[3] <= 64'h0;    
        end
    end

    // resolution choose
    always @(posedge clk ) begin 
        if(~resetn) begin
            resolution_sel <= 2'h0;    
        end
        //TODO: add resolution_sel write logic
    end

    // APB signals
    always @(posedge clk ) begin 
        if(~resetn) begin
            pready_o  <= 1'h0;    
            pslverr_o <= 1'h0;
            prdata_o  <=32'h0;
        end
        else if(psel_i && penable_i) begin
            pready_o  <= 1'h1;    
            if(pwrite_i) begin
                case(paddr_i) 
                    32'h0: begin
                        base_addr <= pwdata_i;
                    end
                    32'h1: begin
                        top_addr  <= pwdata_i;
                    end
                    default: begin
                        resolution_sel <= pwdata_i[1:0];
                    end
                endcase
            end
        end
    end

    // output resolution
    assign hsync_end_o   = resolution[resolution_sel][10: 0];
    assign hpulse_end_o  = resolution[resolution_sel][18:11];
    assign hdata_begin_o = resolution[resolution_sel][26:19];
    assign hdata_end_o   = resolution[resolution_sel][36:27];
    assign vsync_end_o   = resolution[resolution_sel][45:37];
    assign vpulse_end_o  = resolution[resolution_sel][48:46];
    assign vdata_begin_o = resolution[resolution_sel][53:49];
    assign vdata_end_o   = resolution[resolution_sel][62:54];
    
    // output address
    assign base_addr_o = base_addr;
    assign top_addr_o  = top_addr;
    
endmodule
`endif
