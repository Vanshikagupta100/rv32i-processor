# arith_loop — same as arith.s but with a halt loop at the end so the
# testbench can detect completion (PC stops changing).
#
# Tests R-type and I-type arithmetic only, no branches, no memory.
    addi  x1,  x0, 15        # x1 = 15
    addi  x2,  x0, -3        # x2 = -3  (0xFFFFFFFD)
    add   x3,  x1, x2        # x3 = 12
    sub   x4,  x1, x2        # x4 = 18
    and   x5,  x1, x2        # x5 = 13
    or    x6,  x1, x2        # x6 = -1  (0xFFFFFFFF)
    xor   x7,  x1, x2        # x7 = 0xFFFFFFF2
    slt   x8,  x2, x1        # x8 = 1   (-3 < 15 signed)
    sltu  x9,  x2, x1        # x9 = 0   (huge unsigned > 15)
    slli  x10, x1, 4         # x10 = 240 (0xF0)
    srli  x11, x2, 4         # x11 = 0x0FFFFFFF
    srai  x12, x2, 4         # x12 = 0xFFFFFFFF
    andi  x13, x1, 7         # x13 = 7
    addi  x0,  x0, 99        # x0 stays 0 — writes to x0 are ignored
done:
    beq   x0, x0, done       # infinite loop — halts here
