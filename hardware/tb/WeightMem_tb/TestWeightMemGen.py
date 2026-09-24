import random

NUM_STACKS = 4
NUM_WEIGHTS = 784
STACK_SIZE = 32

with open("weights_test.mem", "w") as f:
    for s in range(NUM_STACKS):
        for w in range(NUM_WEIGHTS):
            hex_chunks = []

            # STACK_SIZE weights per line
            for _ in range(STACK_SIZE):
                rand_num = random.randint(0, 255)  # random 8 bit num
                hex_chunks.append(f'{rand_num:02x}')

            line = "".join(hex_chunks)
            f.write(line + "\n")
