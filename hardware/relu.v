module ReLU #(
    parameter WIDTH = 8
) (
    input clk,
    input in,
    output reg [WIDTH-1:0] out
);

    always @(posedge clk) begin
        if (in > 8'b0) begin
            out <= in;
        end else begin
            out <= 0;
        end
    end

endmodule
