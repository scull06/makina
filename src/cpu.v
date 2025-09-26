module CPU1 (
    input         clk,
    input         rst,
    input  [31:0] Instruction,   // instruction fetched from memory
    input  [31:0] MemReadData,   // data read from memory

    output [31:0] PC,            // current program counter
    output [31:0] MemAddress,    // address for memory access
    output [31:0] MemWriteData,  // data to write to memory
    output        MemWrite        // memory write enable
);


//ALU
reg [15:0]	alu_A;
reg [15:0]	alu_B;
reg [4:0]	alu_ALUCtrl;
wire [15:0]	alu_Result;

alu16 alu(.A(alu_A), .B(alu_B), .Result(alu_Result), .ALUCtrl(alu_ALUCtrl));

always @(posedge clk ) begin
    if (rst) begin
        PC = 16'b0; //PC goes to the first ROM address
    end else begin
        //Decoding
        if (Instruction[31]) begin //handle alu instruction 
            
        end else begin // handle other instructions
            
        end        
    end
end

endmodule