module neuron #(
    parameter NUM_INPUTS = 784,
    parameter ADDR_WIDTH = $clog2(NUM_INPUTS),
    parameter FRAC_BITS = 7,
    parameter DATA_WIDTH = 8,
    parameter SUM_WIDTH = 32,  //what's this?
    parameter WEIGHT_FILE = "weights.mem"
) (
    input clk,
    input rst,
    input start,
    input signed [DATA_WIDTH-1:0] in,
    input in_valid,
    input [2:0] batch_idx,
    input signed [DATA_WIDTH-1:0] bias,

    output reg signed [DATA_WIDTH-1:0] out = 0,
    output reg done = 0
);
    localparam [1:0] IDLE = 2'b00;
    localparam [1:0] WORKING = 2'b01;
    localparam [1:0] DONE = 2'b10;

    reg signed [2*DATA_WIDTH-1:0] mult = 0;
    reg signed [SUM_WIDTH-1:0] sum = 0;
    reg signed [SUM_WIDTH -1:0] sum_shifted = 0;
    reg [ADDR_WIDTH-1:0] addr = 0;
    reg [ADDR_WIDTH-1:0] counter = 0;
    reg [1:0] state = IDLE;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            mult = 0;
            sum <= 0;
            sum_shifted <= 0;
            out <= 0;
            done <= 0;
            state <= IDLE;
        end else begin
            case (state)
                IDLE: begin
                    mult = 0;
                    sum <= 0;
                    sum_shifted <= 0;
                    out <= 0;
                    done <= 0;
                    state <= IDLE;
                end

                WORKING: begin
                    // multipy then add to sum



                end

                DONE: begin
                    // add bias
                    // shift before or after adding bias?
                    // clamp


                end

                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end



endmodule
