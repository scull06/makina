/*
00 → Memory ops

01 → ALU ops

10 → Jumps/branches

11 → Reserved (future expansion, system calls, multiply/divide, etc.)

*/
module decoder (
   input [15:0] instr,

   //ALU control
   output reg [3:0] alu_ctrl,
   output reg [2:0] reg_dst, //used for alu out, pc jumps and memory ops st and ld
   output reg [2:0] reg_rs1,
   output reg [2:0] reg_rs2,
   output reg [15:0] imm_se,
   output reg  reg_write,
   output reg  alu_src_imm, //this will be the ALU immediate sign extended input whenever it is needed
   //Memory control
   output reg  mem_read,
   output reg  mem_write,
   output reg  reg_write_back_sel, //Selector for where to write from: MEM => 1; or from ALU result => 0 
   //Branch control
   output reg [2:0] comparator_ctrl
);

localparam ALU_ADD = 4'b0000;

always @(*) begin
    //Default everything to 0!
    alu_ctrl = 4'b0000;
    comparator_ctrl = 3'b000;
    reg_dst = 3'b0;    
    reg_rs1 = 3'b0;    
    reg_rs2 = 3'b0;
    mem_read = 1'b0;
    mem_write = 1'b0;
    reg_write = 1'b0;
    reg_write_back_sel = 1'b0;
    alu_src_imm = 1'b0;
    

    case (instr[15:14])
        2'b00: begin //Memory operations
            // decode fields: bit 13 = R/W, bits 12:10 = reg, 9:7 = base, 6:0 = offset
            reg_dst = instr[12:10];
            reg_rs1 = instr[9:7];
            imm_se = {{9{instr[6]}}, instr[6:0]}; //the sign extension looks at the MSB of the immediate for replication

            alu_ctrl = ALU_ADD;
            alu_src_imm = 1'b1; //must pass imm_se to alu B

            if (instr[13] == 1'b0) begin
                // LD   Rd, offset(Rb)    ; Rd ← MEM[Rb + offset]
                mem_read = 1'b1;
                mem_write = 1'b0;
                reg_write_back_sel = 1'b1;
                reg_write = 1'b1;
            end else begin
                // ST   Rs, offset(Rb)    ; MEM[Rb + offset] ← Rs
                mem_read = 1'b0; //dissable memory read
                mem_write = 1'b1; //enable memory write
                reg_write_back_sel = 1'b0; // the dst register will not be written; so ignore it
                reg_write = 1'b0; //no register will be written
                reg_rs2 = reg_dst; // pass data to be written to the memory data bus register (i.e., reg_rs2).
            end

        end
        2'b01: begin //ALU operations
            // decode fields: bit 13:10 = alu-op, UNUSED: 9 bits 8:6 = dst, 5:3 = reg_a, 2:0 = reg_b
            alu_ctrl = instr[13:10];
            reg_dst = instr[8:6];
            reg_rs1 = instr[5:3];
            reg_rs2 = instr[2:0];
            reg_write = 1'b1;
            alu_src_imm = 1'b0; //must pass imm_se to alu B
        end
        2'b10: begin //JUMP operations
            alu_src_imm = 1'b0; //must pass imm_se to alu B
            //[13:11]: 000 = condition, [10:8]: 000 = regA, [7:5]: 000 = regB, [4:2]: 000 = regDst
            case (instr[13:11])
                3'b111: begin
                    //NOP
                end
                3'b110: begin //JMP regDst -> unconditional
                    comparator_ctrl = instr[13:11];
                    reg_dst = instr[4:2];
                    reg_rs1 = 0;
                    reg_rs2 = 0;
                end
                default: begin //JUMP_TYPE a b dest
                    comparator_ctrl = instr[13:11];
                    reg_rs1 = instr[10:8];
                    reg_rs2 = instr[7:5];
                    reg_dst = instr[4:2]; 
                end
            endcase
        end
        default: begin
            // could mark as NOP or invalid
        end
   endcase
    
end   
endmodule