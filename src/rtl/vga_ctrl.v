module vga_ctrl(
    input  wire        clk,
    input  wire        resetn,
    input  wire [10:0] hsync_end_i,
    input  wire [ 7:0] hpulse_end_i,
    input  wire [ 7:0] hdata_begin_i,
    input  wire [ 9:0] hdata_end_i,
    input  wire [ 8:0] vsync_end_i,
    input  wire [ 2:0] vpulse_end_i,
    input  wire [ 4:0] vdata_begin_i,
    input  wire [ 8:0] vdata_end_i,
    input  wire [11:0] data_i,
    output wire        data_req_o, // request data from ping pong register
    output reg  [ 3:0] red_o,      // rea color
    output reg  [ 3:0] green_o,    // green color
    output reg  [ 3:0] blue_o,     // blue color
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
    always @(posedge clk or negedge resetn) begin 
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
    always @(posedge clk ) begin 
        hsync_o <= (hcount <= {3'h0, hpulse_end_i}) ? 0 : 1;
    end

    // veritcal counter
    always @(posedge clk or negedge resetn) begin 
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
    always @(posedge clk ) begin 
        vsync_o <= (vcount <= {7'h0, vpulse_end_i}) ? 0 : 1;
    end

    // data request
    // always @(posedge clk ) begin 
    //     data_req_o <= (((hcount >= {3'h0, hdata_begin_i}-1) && (hcount <= {1'h0, hdata_end_i}-1))&&
    //                    ((vcount >= {5'h0, vdata_begin_i}-1) && (vcount <= {1'h0, vdata_end_i}-1))) ? 1 : 0;
    // end
    assign data_req_o = (((hcount >= {3'h0, hdata_begin_i}-1) && (hcount <= {1'h0, hdata_end_i}-1))&&
                        ((vcount >= {5'h0, vdata_begin_i}-1) && (vcount <= {1'h0, vdata_end_i}-1))) ? 1 : 0;

    // output rgb
    always @(posedge clk ) begin 
        if(data_req_o) begin
            red_o   <= data_i[ 3:0];    
            green_o <= data_i[ 7:4];    
            blue_o  <= data_i[11:8];    
        end
        else begin
            red_o   <= 4'h0;    
            green_o <= 4'h0;    
            blue_o  <= 4'h0;    
        end
    end

    always @(posedge clk ) begin 
        blank_o <= data_req_o;
    end
    
endmodule
