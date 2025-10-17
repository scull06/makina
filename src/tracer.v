
module program_tracer(
    input clk,
    input [15:0] PC,
    input [15:0] instr,
    input [15:0] cpu_registers [0:7],
    input [15:0] mem_addr,
    input [15:0] mem_data_in,
    input [15:0] mem_data_out,
    input mem_write,
    input mem_read, 
    input [2:0] stage
);
    integer cycle = 0;

    // Optional: sign-extended immediate from instruction (adjust width as needed)
    wire [15:0] imm_se = {{8{1'b0}}, instr[7:0]};

    always @(posedge clk ) begin
        string instr_str;

        case (instr[15:14])
                2'b00: begin //Memory operations
                    if (instr[13] == 1'b0) begin
                        // LD   Rd, offset(Rb)    ; Rd ← MEM[Rb + offset]
                        instr_str = $sformatf("LOAD R%0d, [R%0d + %0d]  ", 
                                                instr[12:10], instr[9:7], imm_se);
                    end else begin
                        instr_str = $sformatf("STORE R%0d, [R%0d + %0d]  | WRITE", 
                                                instr[12:10], instr[9:7], imm_se);
                    end
                end 
                2'b01: begin //ALU operations
                    // decode fields: bit 13:10 = alu-op, UNUSED: 9 bits 8:6 = dst, 5:3 = reg_a, 2:0 = reg_b
                    case (instr[13:10])
                        4'b0000 : instr_str = $sformatf("ADD R%0d, R%0d, R%0d", 
                                                   instr[8:6], instr[5:3], instr[2:0]); //ADD
                        4'b0001 : instr_str = $sformatf("SUB R%0d, R%0d, R%0d", 
                                                   instr[8:6], instr[5:3], instr[2:0]); //SUB
                        4'b0010 : instr_str = $sformatf("AND R%0d, R%0d, R%0d", 
                                                   instr[8:6], instr[5:3], instr[2:0]); //AND
                        4'b0011 : instr_str = $sformatf("OR R%0d, R%0d, R%0d", 
                                                   instr[8:6], instr[5:3], instr[2:0]); //OR
                        4'b0100 : instr_str = $sformatf("XOR R%0d, R%0d, R%0d", 
                                                   instr[8:6], instr[5:3], instr[2:0]); //XOR
                        4'b0101 : instr_str = $sformatf("MUL R%0d, R%0d, R%0d", 
                                                   instr[8:6], instr[5:3], instr[2:0]); //MUL
                        4'b0111 : instr_str = $sformatf("DIV R%0d, R%0d, R%0d", 
                                                   instr[8:6], instr[5:3], instr[2:0]); //DIV
                        4'b1000 : instr_str = $sformatf("NOT R%0d, R%0d, R%0d", 
                                                   instr[8:6], instr[5:3], instr[2:0]); //NOT
                        4'b1001 : instr_str = $sformatf("NOT R%0d, R%0d, R%0d", 
                                                   instr[8:6], instr[5:3], instr[2:0]); //MOD
                        4'b1010 : instr_str = $sformatf("LDI R%0d, IMM=%d", instr[8:6], instr[5:0]); //LOADI
                            default: instr_str = "ALU NOP";
                    endcase
                            
                end
                2'b10: begin //JUMP operations
                    //[13:11]: 000 = condition, [10:8]: 000 = regA, [7:5]: 000 = regB, [4:2]: 000 = regDst
                    case (instr[13:11])
                        3'b111: begin
                            //NOP
                        end
                        3'b110: begin //JMP regDst -> unconditional
                    
                        end
                        default: begin //JUMP_TYPE a b dest
                        
                        end
                    endcase
                end
                default: begin
                    instr_str = $sformatf("NOP");
                end
        endcase
       
        // // Print cycle, PC, instruction, and register snapshot
        // $display("Instruction %b", instr);
        $display("CYCLE %0d:0%d | PC=%0d | %b | %s | REG=[R0=%0d,R1=%0d,R2=%0d,R3=%0d,R4=%0d,R5=%0d,R6=%0d,R7=%0d]",
                 cycle, stage , PC, instr, instr_str, cpu_registers[0], cpu_registers[1], cpu_registers[2], cpu_registers[3], cpu_registers[4], cpu_registers[5], cpu_registers[6], cpu_registers[7]);
        cycle = cycle + 1;
    end
endmodule

module ProgramMemory #(
    parameter MEM_SIZE = 5,
    parameter FILE_PATH = "PROGRAMNAME"
)(
    input [15:0] address,
    output [15:0] instruction
);

    reg [15:0] mem [0:MEM_SIZE-1];

    wire [$clog2(MEM_SIZE)-1:0] addr_index;
    assign addr_index = address[$clog2(MEM_SIZE)-1:0];

    assign instruction = mem[addr_index];

    integer i;
    initial begin
        $display("Loading program from %s ...", FILE_PATH);
        $readmemb(FILE_PATH, mem);
        // for (i=0;i< MEM_SIZE; i=i+1) begin
        //     $display("%b", mem[i]);
        // end
        #1;  // one delta or small time unit
        $display("Program loaded successfully.");
    end


endmodule