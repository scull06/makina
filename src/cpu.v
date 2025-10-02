module CPU1 (
    input         clk,
    input         rst,
    input  reg [31:0] Instruction,   // instruction fetched from memory
    input  reg [31:0] MemReadData,   // data read from memory

    output reg [31:0] PC,            // current program counter
    output reg [31:0] MemAddress,    // address for memory access
    output reg [31:0] MemWriteData,  // data to write to memory
    output reg        MemWrite        // memory write enable
);


//ALU
reg [15:0]	alu_A;
reg [15:0]	alu_B;
reg [3:0]	alu_ALUCtrl;
wire [15:0]	alu_Result;
alu16 alu(.A(alu_A), .B(alu_B), .Result(alu_Result), .ALUCtrl(alu_ALUCtrl));

reg [1:0] instruction_class = Instruction[31:30];

always @(posedge clk ) begin
    if (rst) begin
        PC = 16'b0; //PC goes to the first ROM address
    end else begin
        //Decoding
        case (instruction_class)
           2'b00 : //MEMORY
           2'b01 : begin //ALU class op
            alu_ALUCtrl = Instruction[13:10];
            
           end
           2'b10 : //JUMP/BRANCH
           2'b11 : //RESERVED
            default: 
        endcase

        if (instruction_class) begin //handle alu instruction 
            alu_ALUCtrl = Instruction[14:10];
            
        end else begin // handle other instructions
            
        end        
    end
end

endmodule