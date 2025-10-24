

- [ ] Los registros para el p2 en el segundo ciclo reflejan el mismo valor.

0@ [DECODE] INSTRUCTION: 0101010000000001 | rDest:000 | rA:000 |rB:001 | aluCTRL:01010 | alusrcimm:1 || R0=0, R1=0, R2=0, R3=0, R4=0, R5=0, R6=0, R7=0
0@ [EXEC] aluCTRL:01010 |  A:0000000000000000 | B:0000000000000000 | InputB:0000000000000001 | alu_res:0000000000000001 | destAddr:000
0@ [MEM] Addr=0000000000000001 | dataOut??=0000000000000000 IF(0)
0@ [WRB] pmem_data_in=0000000000000000 |  | mem_addr_to_write:0000000000000001 | to_write_to_mem:0000000000000000
1@ [DECODE] INSTRUCTION: 0101010001000010 | rDest:001 | rA:000 |rB:010 | aluCTRL:01010 | alusrcimm:1 | R0=1, R1=1, R2=0, R3=0, R4=0, R5=0, R6=0, R7=0
1@ [EXEC] aluCTRL:01010 |  A:0000000000000001 | B:0000000000000000 | InputB:0000000000000010 | alu_res:0000000000000010 | destAddr:001
1@ [MEM] Addr=0000000000000010 | dataOut??=0000000000000000 IF(0)
1@ [WRB] pmem_data_in=0000000000000000 |  | mem_addr_to_write:0000000000000010 | to_write_to_mem:0000000000000000
2@ [DECODE] INSTRUCTION: 0101100010001001 | rDest:010 | rA:001 |rB:001 | aluCTRL:01100 | alusrcimm:0 | R0=1, R1=2, R2=2, R3=0, R4=0, R5=0, R6=0, R7=0
2@ [EXEC] aluCTRL:01100 |  A:0000000000000010 | B:0000000000000010 | InputB:0000000000000010 | alu_res:0000000000000001 | destAddr:010
2@ [MEM] Addr=0000000000000001 | dataOut??=0000000000000010 IF(0)
2@ [WRB] pmem_data_in=0000000000000000 |  | mem_addr_to_write:0000000000000001 | to_write_to_mem:0000000000000010
3@ [DECODE] INSTRUCTION: 0011001010000010 | rDest:100 | rA:101 |rB:100 | aluCTRL:00000 | alusrcimm:1 | R0=1, R1=2, R2=1, R3=0, R4=1, R5=0, R6=0, R7=0
3@ [EXEC] aluCTRL:00000 |  A:0000000000000000 | B:0000000000000001 | InputB:0000000000000010 | alu_res:0000000000000010 | destAddr:100
3@ [MEM] Addr=0000000000000010 | dataOut??=0000000000000001 IF(1)

- [X] Cambiar las instrucciones de comparator para el alu.
- [ ] Implementar jumps basado en en registros, solo leen registro and saltan a direcciones basadas en registros.

