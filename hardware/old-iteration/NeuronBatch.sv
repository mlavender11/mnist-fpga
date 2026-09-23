`include "MacUnit.sv"
`include "WeightBank.sv"

module NeuronBatch #(  // move any of these to localparam?
    parameter NUM_INPUTS  = 784,
    parameter NUM_BATCHES = 4,
    parameter FRAC_BITS   = 7,
    parameter DATA_WIDTH  = 8,
    parameter SUM_WIDTH   = 32,
    parameter WEIGHT_FILE = "weights.mem"
) (
    input clk_i,
    input rst_i,
    input signed [DATA_WIDTH-1:0] data_i,
    input in_data_valid_i,
    input [$clog2(NUM_BATCHES)-1:0] batch_idx_i,
    input signed [DATA_WIDTH-1:0] bias_i,
    input start_i,

    output reg signed [DATA_WIDTH-1:0] output_o,
    output reg output_valid_o
);
    // States
    reg [1:0] state_r;
    localparam IDLE = 2'b00;
    localparam WORKING = 2'b01;
    localparam DONE = 2'b10;

    // Local params
    localparam ADDR_WIDTH = $clog2(NUM_INPUTS * NUM_BATCHES);  // how does sizing of this owrk?
    localparam signed [DATA_WIDTH-1:0] MAX_QUANTIZED_VALUE = {1'b0, {(DATA_WIDTH - 1) {1'b1}}};
    localparam signed [DATA_WIDTH-1:0] MIN_QUANTIZED_VALUE = {
        1'b1, {(DATA_WIDTH - 1) {1'b0}}
    }; 

    // Internal registers and wires
    reg [ADDR_WIDTH-1:0] mem_addr_r;
    wire signed [DATA_WIDTH-1:0] weight_w;
    wire signed [SUM_WIDTH-1:0] sum_w;
    reg mac_rst_r;
    reg mac_en;
    reg [$clog2(NUM_INPUTS)-1:0] input_counter_r;
    reg signed [DATA_WIDTH-1:0] in_delayed_r;
    reg in_delayed_valid_r;

    // combinational logic
    wire signed [SUM_WIDTH-1:0] biased_w = sum_w + (bias_i <<< FRAC_BITS);  // bias_i before or after shift?
    wire signed [SUM_WIDTH-1:0] shifted_w = biased_w >>> FRAC_BITS;
    wire signed [SUM_WIDTH-1:0] clamped_w = (shifted_w > MAX_QUANTIZED_VALUE) ? MAX_QUANTIZED_VALUE:
    (shifted_w < MIN_QUANTIZED_VALUE) ? MIN_QUANTIZED_VALUE: 
    shifted_w;

    // task
    task reset_state;
        begin
            output_o <= 0;
            output_valid_o <= 0;
            mac_rst_r <= 1;
            mac_en <= 0;
            input_counter_r <= 0;
            in_delayed_valid_r <= 0;
            mem_addr_r <= 0;
            state_r <= IDLE;
        end
    endtask

    // Modules
    WeightBank #(
        .NUM_INPUTS (NUM_INPUTS),
        .NUM_BATCHES(NUM_BATCHES),
        .WEIGHT_FILE(WEIGHT_FILE)
    ) wb (
        .clk_i(clk_i),
        .read_addr_i(mem_addr_r),
        .data_o(weight_w)
    );

    MacUnit #(
        .DATA_WIDTH(DATA_WIDTH),
        .SUM_WIDTH (SUM_WIDTH)
    ) mac (
        .clk_i(clk_i),
        .rst_i(mac_rst_r),
        .en_i (mac_en),
        .a_i  (weight_w),
        .b_i  (in_delayed_r),
        .sum_o(sum_w)
    );

    always @(posedge clk_i) begin
        in_delayed_r <= data_i;
        in_delayed_valid_r <= in_data_valid_i;
    end

    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            reset_state;
        end else begin
            case (state_r)
                IDLE: begin
                    if (start_i) begin
                        mac_rst_r <= 1;
                        mem_addr_r <= batch_idx_i * NUM_INPUTS;
                        state_r <= WORKING;
                    end else begin
                        reset_state;
                    end
                end

                WORKING: begin
                    mac_rst_r <= 0;
                    output_valid_o <= 0;
                    if (in_delayed_valid_r) begin
                        mac_en <= 1;

                        if (input_counter_r == NUM_INPUTS - 1) begin
                            input_counter_r <= 0;
                            state_r <= DONE;
                        end else begin
                            mem_addr_r <= mem_addr_r + 1;
                            input_counter_r <= input_counter_r + 1;  // do this now or at the end?
                        end
                    end else begin
                        mac_en  <= 0;
                    end
                end

                DONE: begin
                    output_o <= clamped_w[DATA_WIDTH-1:0];
                    output_valid_o <= 1;
                    state_r <= IDLE;

                end

                default: begin
                    reset_state;
                end
            endcase
        end
    end
endmodule
