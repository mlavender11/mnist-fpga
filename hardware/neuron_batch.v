module neuron_batch #(  // move any of these to localparam?
    parameter NUM_INPUTS  = 784,
    parameter NUM_BATCHES = 4,
    parameter FRAC_BITS   = 7,
    parameter DATA_WIDTH  = 8,
    parameter SUM_WIDTH   = 32,
    parameter WEIGHT_FILE = "weights.mem"
) (
    input clk,
    input rst,
    input signed [DATA_WIDTH-1:0] in,
    input in_valid,
    input [$clog2(NUM_BATCHES)-1:0] batch_idx,
    input signed [DATA_WIDTH-1:0] bias,
    input start,

    output reg signed [DATA_WIDTH-1:0] out,
    output reg out_valid
);
    // States
    reg [1:0] state;
    localparam IDLE = 2'b00;
    localparam WORKING = 2'b01;
    localparam DONE = 2'b10;

    // Local params
    localparam ADDR_WIDTH = $clog2(NUM_INPUTS * NUM_BATCHES);  // how does sizing of this owrk?
    localparam [DATA_WIDTH-1:0] MAX_QUANTIZED_VALUE = {1'b0, {(DATA_WIDTH - 1) {1'b1}}};
    localparam [DATA_WIDTH-1:0] MIN_QUANTIZED_VALUE = {
        1'b1, {(DATA_WIDTH - 1) {1'b0}}
    };  // TODO fill with zeros not ones

    // Internal registers and wires
    reg [ADDR_WIDTH:0] mem_addr;
    wire signed [DATA_WIDTH-1:0] weight;
    wire signed [SUM_WIDTH-1:0] sum;
    reg signed [SUM_WIDTH-1:0] sum_shifted;
    reg mac_rst;
    reg mac_en;
    reg [$clog2(NUM_INPUTS)-1:0] input_counter;
    reg signed [DATA_WIDTH-1:0] in_delayed;
    reg in_delayed_valid;

    // combinational logic
    wire signed [SUM_WIDTH-1:0] biased = sum + (bias <<< FRAC_BITS);  // bias before or after shift?
    wire signed [SUM_WIDTH-1:0] shifted = biased >>> FRAC_BITS;
    wire signed [SUM_WIDTH-1:0] clamped = (shifted > MAX_QUANTIZED_VALUE) ? MAX_QUANTIZED_VALUE:
    (shifted < MIN_QUANTIZED_VALUE) ? MIN_QUANTIZED_VALUE: 
    shifted;

    // task
    task reset_state;
        begin
            out <= 0;
            out_valid <= 0;
            mac_rst <= 1;
            mac_en <= 0;
            input_counter <= 0;
            in_delayed_valid <= 0;
            state <= IDLE;
        end
    endtask

    // Modules
    weight_bank #(
        .NUM_INPUTS (NUM_INPUTS),
        .NUM_BATCHES(NUM_BATCHES),
        .WEIGHT_FILE(WEIGHT_FILE)
    ) wb (
        .clk(clk),
        .read_addr(mem_addr),
        .data_out(weight)
    );

    mac_unit #(
        .DATA_WIDTH(DATA_WIDTH),
        .SUM_WIDTH (SUM_WIDTH)
    ) mac (
        .clk(clk),
        .rst(mac_rst),
        .en (mac_en),
        .a  (weight),
        .b  (in_delayed),
        .sum(sum)
    );

    always @(posedge clk) begin
        in_delayed <= in;
        in_delayed_valid <= in_valid;
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            reset_state;
        end else begin
            case (state)
                IDLE: begin
                    if (start) begin
                        mac_rst <= 1;
                        mem_addr <= batch_idx * NUM_INPUTS;
                        state <= WORKING;
                    end else begin
                        reset_state;
                    end
                end

                WORKING: begin
                    mac_rst   <= 0;
                    out_valid <= 0;
                    if (in_delayed_valid) begin
                        mac_en <= 1;

                        if (input_counter == NUM_INPUTS - 1) begin
                            mem_addr <= batch_idx * NUM_INPUTS + input_counter;  // remove?
                            input_counter <= 0;
                            state <= DONE;
                        end else begin
                            mem_addr <= mem_addr + 1;
                            input_counter <= input_counter + 1;  // do this now or at the end?
                            state <= WORKING;
                        end
                    end else begin
                        mac_en <= 0;
                        state  <= WORKING;
                    end
                end

                DONE: begin
                    out <= clamped[DATA_WIDTH-1:0];
                    out_valid <= 1;
                    state <= IDLE;

                end

                default: begin
                    reset_state;
                end
            endcase
        end
    end
endmodule
