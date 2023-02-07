# Reads and writes to MM'd values:
# 0xC000: Writing to this address writes to LEDR[9:0] of the board
# 0xC001: Reading from this address returns state of SW[9:0]
        LLB R1, 0x00 # Load address of LEDR in R1 (SW is offset 1 up)
        LHB R1, 0xC0
        LW R2, R1, 0 # Read contents of SW[9:0] into R2
        SW R2, R1, 1 # Store SW[9:0] from address at R1 + 1
START:  LLB R1, 0x00 # Load address of LEDR in R1 (SW is offset 1 up)
        LHB R1, 0xC0
        LW R2, R1, 0 # Read contents of SW[9:0] into R2
        SW R2, R1, 1 # Store SW[9:0] from address at R1 + 1
        B UNCOND, START # Loop forever
