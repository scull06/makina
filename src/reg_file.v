
/*
Implements the registers for the CPU
*/

module RegisterFile (
    input clk,
    input write_enabled,
    input [2:0] addr_reg_a,          // address of register 1
    input [2:0] addr_reg_b,          // address of register 2
    input [2:0] addr_dest,           // address of destination register
    input [15:0] write_data,  // data to be written
    output reg [15:0] out_reg_a, // data from rs1
    output reg [15:0] out_reg_b  // data from rs2    
);

reg [15:0] cpu_registers [0:7];  //8 registers, each 16 bits wide

// assign out_reg_a = cpu_registers[addr_reg_a];
// assign out_reg_b = cpu_registers[addr_reg_b];

integer i;
initial begin
    for (i = 0; i < 8; i = i + 1) begin
        cpu_registers[i] = 16'b0;
    end
end

always @(posedge clk ) begin
    if(write_enabled)begin
        cpu_registers[addr_dest] <= write_data;
    end  
     out_reg_a <= cpu_registers[addr_reg_a];
     out_reg_b <= cpu_registers[addr_reg_b];   
end
endmodule