module ping_pong_register
#(
    parameter ADDR_WIDTH=64,
    parameter DATA_WIDTH=64
)
(
    // signals with VC(VGA Control)
    input  wire                  clk_v,      // clock with vga block
    input  wire                  resetn,
    input  wire                  data_reg_i, // data request from VC
    output reg  [11:0]           data_o,
    // signals with CU(config unit)
    input  wire                  base_addr_i,// SDRAM read base addr
    // signals with AXI bus
    input  wire                  clk_a,      // clock with AXI bus
    input  wire                  arready_i,
    input  wire                  rvalid_i,
    input  wire [1:0]            rresp_i,
    input  wire [DATA_WIDTH-1:0] rdata_i,

    output reg  [ADDR_WIDTH-1:0] araddr_o,
    output reg  [1:0]            arburst_o,
    output reg  [7:0]            arlen_o,
    output reg  [2:0]            arsize_o,
    output reg                   arvalid_o,
    output reg                   arready_o
); 

// =========================================================================
// ============================ variables =============================
// =========================================================================
reg [64:0] ping [31:0];
reg [64:0] pong [31:0];
reg        read_ping; // currently read from ping register
reg [ 4:0] reg_count; // which register in ping or pong is read
reg [ 1:0] byte_count;// which 16bits in a register is read, 64 bits register has 4 16-bits part


// =========================================================================
// ============================ implementation =============================
// =========================================================================


    // ==================== read logics ====================
    // read pointer 
    always @(posedge clk_v ) begin 
        if(~resetn) begin
            byte_count <= 2'b0;    
        end
        else if(data_reg_i) begin
            byte_count <= byte_count + 1;    
        end
        else begin
            byte_count <= byte_count;    
        end
    end

    always @(posedge clk_v ) begin 
        if(~resetn) begin
            reg_count <= 5'h0;    
        end
        else if(data_reg_i && byte_count == 2'b11) begin
            reg_count <= reg_count + 1;    
        end
        else begin
            reg_count <= reg_count;    
        end
    end
    
    always @(posedge clk_v) begin 
        if(~resetn) begin
            read_ping <= 1'b0;    
        end
        else if(reg_count == 5'h1f && byte_count == 2'b11) begin
            // finish read whole register group
            read_ping <= ~read_ping;
        end
    end
    
    // get VGA read data
    always @(posedge clk_v) begin 
        if(~resetn) begin
            data_o <= 12'h0;    
        end
        else if(data_reg_i) begin
            if(read_ping) begin
                    
            end
        end
        else begin
            data_o <= data_o;    
        end
    end

    // ==================== write logics ====================

endmodule
