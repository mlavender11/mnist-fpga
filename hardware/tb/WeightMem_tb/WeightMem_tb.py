import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ReadOnly

import math
import logging
import random

# TODO can I get these from the dut?
MEM_FILE = "weights_test.mem"
NUM_WEIGHTS = 784
NUM_STACKS = 4


@cocotb.test()
async def memory_test(dut):
    log = logging.getLogger("cocotb.my_tb")
    clock = Clock(dut.clk_i, 10, unit="ns")
    clock.start()

    # initial inputs
    log.info("init inputs")
    dut.stack_num_i.value = 0
    dut.weight_num_i.value = 0
    await RisingEdge(dut.clk_i)

    log.info("starting memory read")
    stack_idx = 0
    weight_idx = 0

    # Check boundaries
    addrs_to_check = [(0, 0), (0, NUM_WEIGHTS - 1), (NUM_STACKS - 1, 0), (NUM_STACKS - 1, NUM_WEIGHTS - 1)]
    # Add random addrs to check
    addrs_to_check += [(random.randrange(NUM_STACKS), random.randrange(NUM_WEIGHTS)) for _ in range(100)]

    # Check each address
    for i, (stack_idx, weight_idx) in enumerate(addrs_to_check):
        dut.stack_num_i.value = stack_idx
        dut.weight_num_i.value = weight_idx

        await RisingEdge(dut.clk_i)
        await RisingEdge(dut.clk_i)
        # await ReadOnly()  # TODO how does this work

        hardware_output = str(dut.data_o.value)
        hardware_output_hex = f"{int(hardware_output, 2):064x}"
        expected_hex = read_mem_line(NUM_WEIGHTS, stack_idx, weight_idx)

        assert (
            hardware_output_hex == expected_hex
        ), f"stack={stack_idx} weight={weight_idx}: got {hardware_output_hex}, expected {expected_hex}, iteration {i}"


def read_mem_line(NUM_WEIGHTS, stack_idx, weight_idx, mem_fn="weights_test.mem"):
    line_num = stack_idx * NUM_WEIGHTS + weight_idx

    with open(mem_fn, "r") as f:
        for current_line_num, line in enumerate(f, start=0):
            if current_line_num == line_num:
                return line.strip()
            else:
                continue


def read_neuron_weight(line, STACK_SIZE, neuron_idx, weight_width_binary):
    # STACK_SIZE is the number of neurons in each stack
    # neuron_idx is the neuron's index within its respective stack
    weight_width_hex = math.ceil(weight_width_binary / 4)

    # Starting index of hex word
    starting_index = weight_width_hex * (STACK_SIZE - neuron_idx - 1)
    ending_index = starting_index + weight_width_hex

    return line[starting_index:ending_index]
