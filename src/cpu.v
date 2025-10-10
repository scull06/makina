module CPU (
    input         clk,
    input         rst,
    input  reg [16:0] Instruction,   // instruction fetched from memory
    input  reg [16:0] MemReadData,   // data read from memory

    output reg [16:0] PC,            // current program counter
    output reg [16:0] MemAddress,    // address for memory access
    output reg [16:0] MemWriteData,  // data to write to memory
    output reg        MemWrite        // memory write enable
);


//ALU
PC pc (.clk(clk), .reset(rst));

always @(posedge clk ) begin
  
end

endmodule