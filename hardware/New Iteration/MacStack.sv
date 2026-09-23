`include "MacUnit.sv"

module MacStack #(
    parameter DATA_WIDTH = 8,   // Width of weights and input data
    parameter STACK_SIZE = 32,  // Number of MACs in parallel
    parameter SUM_WIDTH  = 32   // Width of MAC output sum

) (
    input logic clk_i,
    input logic rst_i,
    input logic clr_i,
    input logic en_i,
    input signed [DATA_WIDTH-1:0] data_i,  // input data (ex. 784 MNIST inputs, passed sequentially)
    input logic [STACK_SIZE-1:0][DATA_WIDTH-1:0] weight_stack_i, //TODO does signed work for packed? // Packed - should I use packed or unpacked?
    output logic [STACK_SIZE-1:0][SUM_WIDTH-1:0] sum_stack_o  // name as logic TODO make signed?
);
    // TODO Maybe add a MUX for sum stack output?

    for (genvar i = 0; i < STACK_SIZE; i = i + 1) begin : gen_mac_stack
        MacUnit #(
            .DATA_WIDTH(DATA_WIDTH),
            .SUM_WIDTH (SUM_WIDTH)
        ) mac_inst (
            .clk_i,
            .rst_i,
            .clr_i,
            .en_i,
            .a_i  (data_i),
            .b_i  (weight_stack_i[i]),
            .sum_o(sum_stack_o[i])
        );

    end


endmodule
