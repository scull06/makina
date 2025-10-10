# makina


### Instruction format

#### 16-bit word size

##### For ALU operations

bit: 15:14       13:10        9              8:6     5:3          2:0
     2 (class).  opcode(4).   UNUSED    rdest(3).  areg(3).    breg(3)/imm(4)

##### For JUMP operations

[15:14]:01 = jump class, [13:11]: 000 = condition, [10:8]: 000 = regA, [7:5]: 000 = regB, [4:2]: 000 = regDst

`
110: JMP regDst -> unconditional
000: JEQ a b dest -> if a == b
001: JNQ a b dest -> if a != b
010: JGT a b dest -> if a > b
011: JLT a b dest -> if a < b
100: JGE a b dest -> if a >= b
101: JLE a b dest -> if a <= b
`

##### For memory operations

TODO:

### Running tests and 

Run `iverilog -o alu_tb.vvp alu_tb.v alu.v` on the src folder for building the .vvp file. Then run vvp wit the *.vvp generated file for testing.