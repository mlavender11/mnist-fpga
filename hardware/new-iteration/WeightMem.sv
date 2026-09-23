module WeightMem #(
    parameter WEIGHT_WIDTH = 8, // Size of each weight
    parameter STACK_SIZE = 32, // Number of neurons per stack
    parameter NUM_WEIGHTS = 784, // Number of weights for each neuron
    parameter NUM_NEURONS = 128,
    parameter WEIGHT_FILE = "weights.mem"

) (
    input logic clk_i,
    input logic rst_i
);
logic [NUM_NEURONS][NUM_WEIGHTS] weights [WEIGHT_WIDTH-1:0];

// Load weights
initial begin
    $readmemh(WEIGHT_FILE, data_r);
end

always_ff @( clk_i ) begin
    data_o <=     
end

endmodule
