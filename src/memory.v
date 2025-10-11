
module ROM (
    input clk,
    input [15:0] address,
    output reg [15:0] instrution_out 
);
reg [15:0] memory [0:15000];

always @(posedge clk) begin
    instrution_out <= memory[address];
end
endmodule


module RAM (
    input clk,
    input write_enabled,
    input [15:0] write_value,
    input [15:0] address,
    output reg [15:0] memory_out 
);

reg [15:0] memory [0:65535];
initial memory_out = 0;

always @(posedge clk) begin
    if(write_enabled) begin
        memory[address] <= write_value;
    end
    memory_out <= memory[address];       
end
endmodule