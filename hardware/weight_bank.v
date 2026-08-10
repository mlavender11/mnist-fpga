module weight_bank #(
    parameter NUM_INPUTS  = 784,
    parameter NUM_BATCHES = 4,
    parameter NUM_WEIGHTS = NUM_INPUTS * NUM_BATCHES,
    parameter ADDR_WIDTH  = $clog2(NUM_WEIGHTS),
    parameter FRAC_BITS   = 7,
    parameter DATA_WIDTH  = 8,
    parameter WEIGHT_FILE = "weights.mem"
) (
    input clk,
    input rst,
    input [ADDR_WIDTH-1:0] read_addr,
    output reg signed [DATA_WIDTH-1:0] data_out
);

    //load weights
    reg signed [DATA_WIDTH-1:0] data[0:NUM_WEIGHTS-1];

    initial begin
        $readmemh(WEIGHT_FILE, data);
    end

    always @(posedge clk) begin
        data_out <= data[read_addr];
    end

endmodule
