`ifndef __PING_PONG_REGISTER__
`define __PING_PONG_REGISTER__
module ping_pong_register
#(
    parameter ADDR_WIDTH=64,
    parameter DATA_WIDTH=64
)
(
    // signals with VC(VGA Control)
    input  wire                  clk_v,      // clock with vga block
    input  wire                  resetn_v,
    input  wire                  data_req_i, // data request from VC
    input  wire                  self_test_i, // VGA self test mode
    output reg  [11:0]           data_o,
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

    output reg  [ADDR_WIDTH-1:0] araddr_o,
    output reg  [1:0]            arburst_o,
    output reg  [7:0]            arlen_o,
    output reg  [2:0]            arsize_o,
    output reg                   arvalid_o,
    output reg                   rready_o
); 

// =========================================================================
// ============================ variables =============================
// =========================================================================
reg [DATA_WIDTH-1:0] ping [31:0];
reg [DATA_WIDTH-1:0] pong [31:0];
// reg [11:0] color[ 7:0]; // color register, store self test color data
reg        read_ping; // currently read from ping register
reg [ 4:0] read_count; // which register in ping or pong is read
reg [ 1:0] byte_count;// which 16bits in a register is read, 64 bits register has 4 16-bits part
reg [63:0] next_addr;
reg [ 4:0] write_count;
wire       vga_read_finish;  // finish read ping or pong
reg        ppr_write_finish; // finish write ping or pong


// =========================================================================
// ============================ implementation =============================
// =========================================================================


    // ==================== read logics ====================
    // read pointer 
    always @(posedge clk_v ) begin 
        if(~resetn_v) begin
            byte_count <= 2'b0;    
        end
        else if(data_req_i) begin
            byte_count <= byte_count + 1;    
        end
        else begin
            byte_count <= byte_count;    
        end
    end

    always @(posedge clk_v ) begin 
        if(~resetn_v) begin
            read_count <= 5'h0;    
        end
        else if(data_req_i && byte_count == 2'b11) begin
            read_count <= read_count + 1;    
        end
        else begin
            read_count <= read_count;    
        end
    end

    assign vga_read_finish = (read_count==5'h1f) & (byte_count==2'b11); 
    
    always @(posedge clk_v) begin 
        if(~resetn_v) begin
            read_ping <= 1'b0;    
        end
        else if(vga_read_finish & ppr_write_finish) begin
            // finish read whole register grou
            read_ping <= ~read_ping;
        end
    end
    
    always @(posedge clk_v) begin 
        if(~resetn_v) begin
            data_o <= 12'h0;    
        end
        else if(data_req_i) begin
            // if(self_test_i) begin
            //     data_o <= color[2]; //TODO: correntlly only support self test of red color
            // end
            begin
                if(read_ping) begin // read data from ping register
                    case(byte_count) 
                        2'h0: begin
                            data_o <= ping[read_count][11:0];
                        end
                        2'h1: begin
                            data_o <= ping[read_count][27:16];
                        end
                        2'h2: begin
                            data_o <= ping[read_count][43:32];
                        end
                        2'h3: begin
                            data_o <= ping[read_count][59:48];
                        end
                        default: begin
                        end
                    endcase
                end
                else begin // read data from pong register
                    case(byte_count) 
                        2'h0: begin
                            data_o <= pong[read_count][11:0];
                        end
                        2'h1: begin
                            data_o <= pong[read_count][27:16];
                        end
                        2'h2: begin
                            data_o <= pong[read_count][43:32];
                        end
                        2'h3: begin
                            data_o <= pong[read_count][59:48];
                        end
                        default: begin
                        end
                    endcase
                end
            end
        end
        else begin
            data_o <= data_o;    
        end
    end

    // ==================== write logics ====================
    // calculate AXI read address
    always @(posedge clk_a) begin 
        if(~resetn_a) begin
            araddr_o <= base_addr_i;
            next_addr<= base_addr_i;
            arburst_o<= 2'h0;
            arlen_o  <= 8'h0;
            arsize_o <= 3'h0;
            arvalid_o<= 1'h0;
            rready_o <= 1'h0;
        end
        else if(arready_i) begin
            araddr_o <=  next_addr;   
            if(next_addr+64'h100 < top_addr_i) begin
                next_addr<=  next_addr+64'h100;
            end
            else begin
                next_addr<=base_addr_i;    
            end
            arburst_o<= 2'h1; // addr increment
            arlen_o  <= 8'h1f;// 31+1=32 transfers 
            arsize_o <= 3'h3; // 8 byte for 1 transaction
            arvalid_o<= 1'h1; // read addrss valid
        end
    end

    // calculate if PPR write finish
    always @(posedge clk_a ) begin 
        if(~resetn_a) begin
            ppr_write_finish <= 1'b0;    
        end
        else if(write_count==5'h1f) begin
            if(vga_read_finish==1'b0 ) begin
                ppr_write_finish <=1'b1;    
            end
            else begin
                ppr_write_finish <=1'b0;    
            end
        end
    end
    
    always @(posedge clk_a) begin 
        if(~resetn_a) begin
            arvalid_o <= 1'h0;    
            rready_o  <= 1'h0;
        end
        else if(~ppr_write_finish) begin
            arvalid_o <= 1'b1; // address valid
            rready_o  <= 1'h1; // ready for read data
        end
    end
    

    // write AXI data into memory
    always @(posedge clk_a ) begin 
        if(rvalid_i && (rresp_i==2'h0) && (~ppr_write_finish)) begin
            if(read_ping) begin
                pong[write_count] <= rdata_i;
            end    
            else begin
                ping[write_count] <= rdata_i;    
            end
        end
    end

    always @(posedge clk_a) begin 
        if(~resetn_a) begin
            write_count<=5'h0;    
        end
        else if(vga_read_finish && ppr_write_finish) begin
            write_count <= 5'h0;    
        end
        else if(write_count<=5'h1e) begin
            write_count <= write_count + 5'h1;    
        end
    end
    

    // // self test color set
    // always @(posedge clk_a) begin 
    //     if(~resetn_a) begin
    //         color[0] <= 12'h000; // black
    //         color[1] <= 12'hfff; // white
    //         color[2] <= 12'hf00; // red 
    //         color[3] <= 12'h0f0; // green
    //         color[4] <= 12'h00f; // blue
    //         color[5] <= 12'hff0; // yellow 
    //         color[6] <= 12'h0ff; // cyan
    //         color[7] <= 12'hf0f; // magenta
    //     end
    // end
    
endmodule
`endif
