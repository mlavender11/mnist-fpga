module MacUnit #(  // move any to local param?
    parameter DATA_WIDTH = 8,  // Width of both inputs
    parameter SUM_WIDTH  = 32
) (
    input clk_i,
    input rst_i,
    input clr_i,
    input en_i,
    input signed [DATA_WIDTH-1:0] a_i,
    input signed [DATA_WIDTH-1:0] b_i,
    output reg signed [SUM_WIDTH-1:0] sum_o
);
    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            sum_o <= 0;
        end else if (clr_i) begin
            sum_o <= 0;
        end else if (en_i) begin
            sum_o <= sum_o + (a_i * b_i);
        end else begin
            sum_o <= sum_o;
        end
    end

endmodule
