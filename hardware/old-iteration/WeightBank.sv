module WeightBank #(  // move any to local param?
    parameter  NUM_INPUTS  = 784,
    parameter  NUM_BATCHES = 4,
    parameter  FRAC_BITS   = 7,
    parameter  DATA_WIDTH  = 8,
    parameter  WEIGHT_FILE = "weights.mem",
    localparam NUM_WEIGHTS = NUM_INPUTS * NUM_BATCHES,
    localparam ADDR_WIDTH  = $clog2(NUM_WEIGHTS)
) (
    input clk_i,
    input [ADDR_WIDTH-1:0] read_addr_i,
    output reg signed [DATA_WIDTH-1:0] data_o
);


    //load weights
    reg signed [DATA_WIDTH-1:0] data_r[0:NUM_WEIGHTS-1];

    initial begin
        $readmemh(WEIGHT_FILE, data_r);
    end

    always @(posedge clk_i) begin
        data_o <= data_r[read_addr_i];
    end

endmodule
