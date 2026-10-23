# P7 - edge cases the other programs do not reach:
#   * BGE / BGEU taken when the operands are EQUAL (>= includes equality)
#   * BGE not taken for -1 vs 1 (signed), BGEU taken for 0xFFFFFFFF vs 1 (unsigned)
#   * branch encodings with the unused funct3 values 010 and 011 must NOT branch
#   * JALR with an odd computed target: bit 0 must be cleared
#   * LUI whose immediate bits land in the rs1 field (rs1 holds a non-zero register)
# Expected final state is derived by hand in p7_edge.expect.
    addi  x1, x0, 5
    addi  x2, x0, 5
    addi  x20, x0, 0

    bge   x1, x2, L1        # equal -> taken, skips the next instruction
    addi  x20, x20, 1       # (must be skipped)
L1:
    bgeu  x1, x2, L2        # equal -> taken
    addi  x20, x20, 2       # (must be skipped)
L2:
    addi  x3, x0, -1        # x3 = 0xFFFFFFFF
    addi  x4, x0, 1
    bge   x3, x4, L3        # signed: -1 >= 1 is false -> NOT taken
    addi  x21, x0, 7        # must execute
L3:
    bgeu  x3, x4, L4        # unsigned: 0xFFFFFFFF >= 1 -> taken
    addi  x22, x0, 9        # (must be skipped)
L4:
    .word 0x00002463        # B-type, funct3 = 010 (does not exist): must not branch
    addi  x23, x0, 1        # must execute
    .word 0x00003463        # B-type, funct3 = 011 (does not exist): must not branch
    addi  x24, x0, 1        # must execute

    auipc x5, 0             # x5 = A (address of this instruction)
    addi  x5, x5, 17        # x5 = A + 17 (odd)
    jalr  x6, 0(x5)         # jumps to (A+17) & ~1 = A + 16, x6 = A + 12
    addi  x25, x0, 99       # (must be skipped)
    auipc x7, 0             # x7 = A + 16 if bit 0 was cleared (A + 17 if not)
    sub   x8, x7, x5        # x8 = -1 expected
    sub   x9, x5, x6        # x9 = 5 expected

    lui   x10, 0x28         # imm bits [7:3] = 5, so the rs1 field is x5 (non-zero)
done:
    beq   x0, x0, done
