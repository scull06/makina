
module ROM #(parameter MEMORY_SIZE=100) (
    input clk,
    input [15:0] address,
    output reg [15:0] instruction_out 
);
reg [15:0] memory [0:MEMORY_SIZE-1];

always @(posedge clk) begin
    instruction_out <= memory[address];
end

integer i;
initial begin
    for (i = 0; i < MEMORY_SIZE; i = i + 1) begin
        memory[i] = 16'b0;
    end
end
endmodule


module RAM #(parameter MEMORY_SIZE=512) (
    input clk,
    input write_enabled,
    input [15:0] write_value,
    input [15:0] address,
    output reg [15:0] memory_out 
);

reg [15:0] memory [0:MEMORY_SIZE-1];
initial memory_out = 16'b0;

integer i;
initial begin
    for (i = 0; i < MEMORY_SIZE; i = i + 1) begin
        memory[i] = 16'b0;
    end
end

always @(posedge clk) begin
    if(write_enabled) begin
        memory[address] <= write_value;
    end
    memory_out <= memory[address];       
end
endmodule