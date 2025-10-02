# makina


### Instruction format

#### 16-bit word size

bit: 15:14       13:10      9:7     6:4          3:0
     2 (class).  opcode(4).  rdest(3).  areg(3).    breg(3)/imm(4)


### Running tests and 

Run `iverilog -o alu_tb.vvp alu_tb.v alu.v` on the src folder for building the .vvp file. Then run vvp wit the *.vvp generated file for testing.