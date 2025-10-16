module Computer (
    input wire clk,
    input wire rst
);

// output declaration of module ROM
wire [15:0] instruction;          // instruction to be executed

// output declaration of module RAM
reg [15:0] cur_memory_data;     //data of the selected RAM address

// output declaration of module CPU
wire [15:0] pc_addr;            //address used to select the next instruction in ROM
wire [15:0] mem_addr;           //address to select a register in RAM
wire [15:0] mem_data_write;     //data to be written into RAM
wire mem_write_enabled;         //enables writing to RAM; RAM[mem_addr] = mem_data_write

ROM u_ROM(
    .clk            	(clk             ),
    .address        	(pc_addr         ),
    .instruction_out 	(instruction      )
);

RAM u_RAM(
    .clk           	(clk                ),
    .write_enabled 	(mem_write_enabled  ),
    .write_value   	(mem_data_write     ),
    .address       	(mem_addr           ),
    .memory_out    	(cur_memory_data    )
);

CPU u_CPU(
    .clk               	(clk                ),
    .rst               	(rst                ),
    .Instruction       	(instruction        ),
    .mem_data_in       	(cur_memory_data    ),
    .pc_addr_out       	(pc_addr            ),
    .mem_addr          	(mem_addr           ),
    .mem_data_write    	(mem_data_write     ),
    .mem_write_enabled 	(mem_write_enabled  )
);    
endmodule