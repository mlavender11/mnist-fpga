module MacUnit #(
    parameter DATA_WIDTH = 8,  // Width of both inputs
    parameter SUM_WIDTH  = 32
) (
    input logic clk,
    input logic rst,
    input logic clr_i,
    input logic en_i,
    input logic signed [DATA_WIDTH-1:0] a_i,
    input logic signed [DATA_WIDTH-1:0] b_i,
    output logic signed [SUM_WIDTH-1:0] sum_o
);

    // If en_i, then update sum_o by adding a * b every clk cycle
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            sum_o <= '0;
        end else if (clr_i) begin
            sum_o <= '0;
        end else if (en_i) begin
            sum_o <= sum_o + (a_i * b_i);
        end else begin
            sum_o <= sum_o;
        end
    end

endmodule
