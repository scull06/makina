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

// output declaration of module MCPU
reg [15:0] mem_data_out;
reg [15:0] mem_addr_out;
reg mem_write;
reg mem_read;

PLNCPU u_MCPU(
    .clk          	(clk                ),
    .rst          	(rst                ),
    .instr_in     	(instruction        ),
    .pmem_data_in   (cur_memory_data    ),
    .pc           	(pc_addr            ),
    .pmem_data_out 	(mem_data_write     ),
    .pmem_addr_out 	(mem_addr           ),
    .pmem_write    	(mem_write_enabled  )
);
   
endmodule