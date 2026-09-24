import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge


@cocotb.test()
async def test_weight_read(dut):
    """Test reading 32-neuron batches from the memory"""

    # 1. Start a 10ns clock running concurrently
    cocotb.start_soon(Clock(dut.clk_i, 10, units="ns").start())

    # 2. Initialize inputs
    dut.stack_addr_i.value = 0
    dut.weight_addr_i.value = 0
    await RisingEdge(dut.clk_i)

    dut._log.info("--- Starting Memory Read Tests ---")

    # ---------------------------------------------------------
    # Test 1: Read Stack 0, Weight 0
    # ---------------------------------------------------------
    dut.stack_addr_i.value = 0
    dut.weight_addr_i.value = 0

    await RisingEdge(dut.clk_i)  # Apply address to inputs
    await RisingEdge(dut.clk_i)  # Wait 1 cycle for BRAM read latency

    # Read the 256-bit output as a massive Python integer
    full_vector = int(dut.data_o.value)

    # Extract neuron 0 (lowest 8 bits) and neuron 31 (highest 8 bits)
    neuron_0 = full_vector & 0xFF
    neuron_31 = (full_vector >> (31 * 8)) & 0xFF

    dut._log.info(f"Stack 0, Weight 0 | Neuron 0: {hex(neuron_0)}, Neuron 31: {hex(neuron_31)}")

    # ---------------------------------------------------------
    # Test 2: Read Stack 3, Weight 783
    # ---------------------------------------------------------
    dut.stack_addr_i.value = 3
    dut.weight_addr_i.value = 783

    await RisingEdge(dut.clk_i)
    await RisingEdge(dut.clk_i)

    full_vector = int(dut.data_o.value)
    neuron_0 = full_vector & 0xFF

    dut._log.info(f"Stack 3, Weight 783 | Neuron 0: {hex(neuron_0)}")

    # Example Assertion (Checking against expected value)
    # assert neuron_0 == 0x00, f"Expected 0x00 but got {hex(neuron_0)}"