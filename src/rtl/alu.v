module alu
#(
    parameter WIDTH=4
)
(
    input wire clk,
    input wire resetn,
    input wire [WIDTH-1 : 0] a_in,
    input wire [WIDTH-1 : 0] b_in,
    input wire op_in,
    input wire valid_in,
    output wire [WIDTH-1 : 0] result_out,
    output wire valid_out
);

// =========================================================================
// ============================ definitions =============================
// =========================================================================
    reg [WIDTH-1 : 0] calculation_reg;
    reg               valid_out_reg;

// =========================================================================
// ============================ implementation =============================
// =========================================================================

    always @(posedge clk ) begin 
        if(~resetn) begin
            calculation_reg <= 4'h0;
        end
        else if(valid_in) begin
            case(op_in) 
                1'b0: calculation_reg <= a_in;
                1'b1: calculation_reg <= b_in;
            endcase    
        end
    end

    always @(posedge clk) begin 
       if(~resetn) begin
           valid_out_reg <= 1'h0; 
       end
       else begin
           valid_out_reg <= valid_in; 
       end
    end

    assign result_out = calculation_reg;
    assign valid_out  = valid_out_reg;
    
endmodule
