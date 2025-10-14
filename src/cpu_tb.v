module cpu_tb;

    reg clk;
    reg rst;
    reg [15:0] Instruction;
    reg [15:0] mem_data_in;

    wire [15:0] pc_addr_out;
    wire [15:0] mem_addr;
    wire [15:0] mem_data_write;
    wire        mem_write_enabled;


    // small instr + data memory
    reg [15:0] data_mem  [0:63];

    // simple clock generator
    initial clk = 1'b0;
    always #20 clk = ~clk;

    // Instantiate CPU
    CPU uut (
        .clk(clk),
        .rst(rst),
        .Instruction(Instruction),
        .mem_data_in(mem_data_in),
        .pc_addr_out(pc_addr_out),
        .mem_addr(mem_addr),
        .mem_data_write(mem_data_write),
        .mem_write_enabled(mem_write_enabled)
    );

    ProgramMemory #(
        .MEM_SIZE  	(5),
        .FILE_PATH 	("tests/p1"))
    u_ProgramMemory(
        .address     	(pc_addr_out  ),
        .instruction 	(Instruction  )
    );
    

    program_tracer tracer(
        .clk(clk),
        .PC(pc_addr_out),
        .instr(Instruction),
        .cpu_registers(uut.u_RegisterFile.cpu_registers),
        .mem_addr(mem_addr),
        .mem_data_in(mem_data_in),
        .mem_data_out(mem_data_write),
        .mem_write(mem_write_enabled),
        .mem_read(uut.u_decoder.mem_read)
    );



    // // always present data bus: drive mem_data_in from data_mem at mem_addr
    always @(*) begin
        mem_data_in = data_mem[mem_addr];
    end

    // perform memory writes from CPU when mem_write_enabled asserted
    integer cycle = 0;
    always @(posedge clk) begin
        if (mem_write_enabled) begin
            data_mem[mem_addr] <= mem_data_write;
        end

        cycle = cycle + 1;
        
        if (cycle == 7) begin
            for (cycle = 0; cycle < 10; cycle=cycle+1) begin
                $display("%d %b", cycle, data_mem[cycle]);
            end
            $finish;
        end
    end

    
    integer i;
    initial begin
        for (i=0; i<64; i = i+1) data_mem[i]  = 16'h0000;

        data_mem[0]= 16'd5;
        data_mem[1]= 16'd3;

        // reset + run
        #10
        rst = 1'b1;
        #20;
        rst = 1'b0;
    end


endmodule



module program_tracer(
    input clk,
    input [15:0] PC,
    input [15:0] instr,
    input [15:0] cpu_registers [0:7],
    input [15:0] mem_addr,
    input [15:0] mem_data_in,
    input [15:0] mem_data_out,
    input mem_write,
    input mem_read
);
    integer cycle = 0;

    // Optional: sign-extended immediate from instruction (adjust width as needed)
    wire [15:0] imm_se = {{8{instr[7]}}, instr[7:0]};

    always @(posedge clk) begin
        string instr_str;

        case (instr[15:14])
                2'b00: begin //Memory operations
                    if (instr[13] == 1'b0) begin
                        // LD   Rd, offset(Rb)    ; Rd ← MEM[Rb + offset]
                        instr_str = $sformatf("LOAD R%0d, [R%0d + %0d]  |||||  MEM[%0d] <= %0d", 
                                                instr[11:9], instr[8:6], imm_se,  mem_addr, mem_data_out);
                    end else begin
                        instr_str = $sformatf("STORE R%0d, [R%0d + %0d]  |||||  MEM[%0d] => %0d", 
                                                instr[11:9], instr[8:6], imm_se, mem_addr, mem_data_in);
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
        $display("CYCLE %0d | PC=%0d | %s | REG=[R0=%0d,R1=%0d,R2=%0d,R3=%0d,R4=%0d,R5=%0d,R6=%0d,R7=%0d]",
                 cycle, PC, instr_str, cpu_registers[0], cpu_registers[1], cpu_registers[2], cpu_registers[3], cpu_registers[4], cpu_registers[5], cpu_registers[6], cpu_registers[7]);
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
        #1;  // one delta or small time unit
        $display("Program loaded successfully.");
    end


endmodule
