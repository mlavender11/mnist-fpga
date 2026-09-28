from cocotb.clock import Clock
from cocotb.triggers import RisingEdge
from cocotb.types import LogicArray
import cocotb
import numpy as np


@cocotb.test
async def mac_tb(dut):
    clock = Clock(dut.clk, 10, "ns")
    clock.start()

    dut.en_i.value = 0
    dut.clr_i.value = 0
    dut.a_i.value = 0
    dut.b_i.value = 0

    # Check reset
    dut.rst.value = 1
    for _ in range(2):
        await RisingEdge(dut.clk)
    assert dut.sum_o.value == 0
    dut.rst.value = 0
    await RisingEdge(dut.clk)

    # Check mac functionality works
    archive = np.load("mac_sequence.npz")
    a = archive["a"]
    b = archive["b"]
    expected = np.dot(a, b)

    dut.en_i.value = 1
    for a_val, b_val in zip(a, b):
        dut.a_i.value = LogicArray.from_signed(int(a_val), 8)
        dut.b_i.value = LogicArray.from_signed(int(b_val), 8)
        await RisingEdge(dut.clk)

    dut.en_i.value = 0
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    assert (
        dut.sum_o.value.to_signed() == expected
    ), f"MAC operation incorrect. Got: {dut.sum_o.value.to_signed()}, expected {expected}"

    # Check clr works
    await RisingEdge(dut.clk)

    dut.clr_i.value = 1
    await RisingEdge(dut.clk)
    dut.clr_i.value = 0
    await RisingEdge(dut.clk)

    assert dut.sum_o.value == 0, "sum not zero after clear"
