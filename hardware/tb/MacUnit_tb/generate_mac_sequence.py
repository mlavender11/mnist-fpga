import numpy as np

rng = np.random.default_rng(1)

DATA_WIDTH = 8  # Number of data bits
SUM_WIDTH = 32
# Low and high values for signed 8 bit nums (assuming integers)
# TODO test with q1.7 nums
low = -(2 ** (DATA_WIDTH - 1))
high = 2 ** (DATA_WIDTH - 1) - 1
max_sum = 2**32

a = rng.integers(low, high, 100000)
b = rng.integers(low, high, 100000)
result = np.dot(a, b)
print(result)
print(result < max_sum)

np.savez("mac_sequence.npz", a=a, b=b)
