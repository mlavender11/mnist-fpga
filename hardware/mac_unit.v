module mac_unit #(// move any to local param?
    parameter DATA_WIDTH = 8,
    parameter SUM_WIDTH  = 32
) (
    input clk,
    input rst,
    input en,
    input signed [DATA_WIDTH-1:0] a,
    input signed [DATA_WIDTH-1:0] b,
    output reg signed [SUM_WIDTH-1:0] sum
);
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sum <= 0;
        end else if (en) begin
            sum <= sum + (a * b);
        end else begin
            sum <= sum;
        end
    end

endmodule
