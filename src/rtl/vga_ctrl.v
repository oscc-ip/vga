`ifndef __VGA_CTRL__
`define __VGA_CTRL__
// TODO: 增加测试模式、可以输出固定的测试图像，例如显示彩条、黑白画面等
module vga_ctrl(
    input  wire        clk,
    input  wire        resetn,

    input  wire [10:0] hsync_end_i,
    input  wire [ 7:0] hpulse_end_i,
    input  wire [ 7:0] hdata_begin_i,
    input  wire [ 9:0] hdata_end_i,
    input  wire [ 9:0] vsync_end_i,
    input  wire [ 3:0] vpulse_end_i,
    input  wire [ 5:0] vdata_begin_i,
    input  wire [ 9:0] vdata_end_i,

    input  wire [11:0] data_i,
    output reg         data_req_o, // request data from ping pong register
    output wire [ 3:0] red_o,      // rea color
    output wire [ 3:0] green_o,    // green color
    output wire [ 3:0] blue_o,     // blue color
    output reg         vsync_o,    // vertical sync
    output reg         hsync_o,    // horizontal sync
    output reg         blank_o     // vga has valid color output
);

// =========================================================================
// ============================ variables =============================
// =========================================================================
    reg [10:0] hcount;
    reg [ 9:0] vcount;


// =========================================================================
// ============================ implementation =============================
// =========================================================================

    // horizontal counter
    always @(posedge clk) begin 
    // always @(posedge clk or negedge resetn) begin 
        if(~resetn) begin
            hcount <= 11'h0;    
        end
        else if(hcount >= hsync_end_i-1) begin
            hcount <= 11'h0;    
        end
        else begin
            hcount <= hcount + 11'h1;    
        end
    end
    // horizontal sync
    // assign hsync_o = (hcount <= {3'h0, hpulse_end_i}) ? 0 : 1;
    always @(posedge clk ) begin 
        hsync_o <= (hcount <= {3'h0, hpulse_end_i}) ? 0 : 1;
    end

    // veritcal counter
    always @(posedge clk) begin 
    // always @(posedge clk or negedge resetn) begin 
        if(~resetn) begin
            vcount <= 10'h0;    
        end
        else if(hcount == hsync_end_i-1) begin
            if(vcount >= vsync_end_i-1) begin
                vcount <= 10'h0;    
            end
            else begin
                vcount <= vcount + 10'h1;    
            end
        end
        else begin
            vcount <= vcount;    
        end
    end
    // veritcal sync 
    // assign vsync_o = (vcount <= {7'h0, vpulse_end_i}) ? 0 : 1;
    always @(posedge clk ) begin 
        vsync_o <= (vcount <= {6'h0, vpulse_end_i}) ? 0 : 1;
    end

    // data request
    always @(posedge clk ) begin 
        data_req_o <= (((hcount >= {3'h0, hdata_begin_i}-1) && (hcount <= {1'h0, hdata_end_i}-1))&&
                       ((vcount >= {4'h0, vdata_begin_i}-1) && (vcount <= vdata_end_i-1))) ? 1 : 0;
    end
    // assign data_req_o = (((hcount >= {3'h0, hdata_begin_i}-1) && (hcount <= {1'h0, hdata_end_i}-1))&&
    //                     ((vcount >= {3'h0, vdata_begin_i}-1) && (vcount <= vdata_end_i-1))) ? 1 : 0;

    // output rgb
    // TODO: change back to real logic
    assign red_o   = data_i[ 3:0];    
    assign green_o = data_i[ 7:4];    
    assign blue_o  = data_i[11:8];    
    // always @(posedge clk ) begin 
        // if(data_req_o) begin
        //     red_o   <= data_i[ 3:0];    
        //     green_o <= data_i[ 7:4];    
        //     blue_o  <= data_i[11:8];    
        // end
        // else begin
        //     red_o   <= 4'h0;    
        //     green_o <= 4'h0;    
        //     blue_o  <= 4'h0;    
        // end
    // end

    always @(posedge clk ) begin 
        blank_o <= data_req_o;
    end
    
endmodule
`endif

