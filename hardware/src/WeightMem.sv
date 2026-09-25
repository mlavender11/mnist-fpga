module WeightMem #(
    parameter WEIGHT_WIDTH = 8,  // Size of each weight
    parameter STACK_SIZE = 32,  // Number of neurons per stack
    parameter NUM_WEIGHTS = 784,  // Number of weights for each neuron
    parameter NUM_NEURONS = 128,
    parameter NUM_STACKS = NUM_NEURONS / STACK_SIZE,
    parameter WEIGHT_FILE = "weights.mem"

) (
    input logic clk_i,
    input logic rst_i,

    input logic [ $clog2(NUM_STACKS)-1:0] stack_num_i,  // Input to select which stack
    input logic [$clog2(NUM_WEIGHTS)-1:0] weight_num_i, // Input to select which weight

    output logic [STACK_SIZE-1:0][WEIGHT_WIDTH-1:0] data_o // Output containing STACK_SIZE weights corresponding to weight_num and stack_num
);

    // Want to output weights for weight num i and batch num j all together


    logic [STACK_SIZE-1:0][WEIGHT_WIDTH-1:0] weights[0:NUM_STACKS-1][0:NUM_WEIGHTS-1];

    // Load weights
    initial begin
        $readmemh(WEIGHT_FILE, weights);
    end

    always_ff @(posedge clk_i) begin
        data_o <= weights[stack_num_i][weight_num_i];
    end

endmodule
