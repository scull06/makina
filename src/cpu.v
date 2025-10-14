
module CPU (
    input         clk,
    input         rst,
    input [15:0] Instruction,   // instruction fetched from memory
    input [15:0] mem_data_in,   // data read from memory

    output [15:0] pc_addr_out,   // current program counter
    output [15:0] mem_addr,    // address for memory access
    output [15:0] mem_data_write,  // data to write to memory
    output        mem_write_enabled       // memory write enable
);

// output declaration of module RegisterFile
wire [15:0] data_reg_a;
wire [15:0] data_reg_b;

// output declaration of module decoder
wire [3:0] alu_ctrl;
wire [2:0] addr_reg_dst;
wire [2:0] addr_reg_a;
wire [2:0] addr_reg_b;
wire [15:0] imm_se;
wire reg_write;
wire alu_src_imm;
wire mem_read;
wire reg_write_back_sel;
wire [2:0] jump_ctrl;

// output declaration of module alu16
wire [15:0] alu_result;

// output declaration of module comparator
wire branch_taken;
wire [15:0] pc_jump_addr;

PC u_PC(
    .clk                   	(clk          ),
    .reset                 	(rst          ),
    .branch_taken          	(branch_taken &&  jump_ctrl),
    .w_instruction_address 	(pc_jump_addr ),
    .pc_out                	(pc_addr_out  )
);

//COMO acomodar las salidas del decoder con respecto a las operaciones en la memoria y el alu
decoder u_decoder(
    .instr              	(Instruction         ),
    .alu_ctrl           	(alu_ctrl            ),
    .reg_dst            	(addr_reg_dst        ),
    .reg_rs1            	(addr_reg_a          ),
    .reg_rs2            	(addr_reg_b          ),
    .imm_se             	(imm_se              ),
    .reg_write          	(reg_write           ),
    .alu_src_imm        	(alu_src_imm         ),
    .mem_write          	(mem_write_enabled   ),
    .reg_write_back_sel 	(reg_write_back_sel  ),
    .comparator_ctrl    	(jump_ctrl           )
);

wire [15:0] reg_file_in;
assign reg_file_in = (reg_write_back_sel) ? mem_data_in : alu_result;

RegisterFile u_RegisterFile(
    .clk           	(clk            ),
    .write_enabled 	(reg_write      ),
    .addr_reg_a    	(addr_reg_a     ),
    .addr_reg_b    	(addr_reg_b     ),
    .addr_dest     	(addr_reg_dst   ),
    .write_data    	(reg_file_in    ),
    .out_reg_a     	(data_reg_a     ),
    .out_reg_b     	(data_reg_b     )
);

comparator u_comparator(
    .jump_operator           	(jump_ctrl           ),
    .pc_destination_addr     	(imm_se              ),
    .operand_a               	(data_reg_a          ),
    .operand_b               	(data_reg_b          ),
    .pc_write_enabled        	(branch_taken        ),
    .pc_destination_addr_out 	(pc_jump_addr        )
);

wire [15:0] alu_in_b = (alu_src_imm) ? imm_se : data_reg_b;
//ALU
alu16 u_alu16(
    .A       	(data_reg_a ),
    .B       	(alu_in_b ),
    .ALUCtrl 	(alu_ctrl   ),
    .Result  	(alu_result )
);

assign mem_addr = alu_result;
assign mem_data_write = data_reg_b;

endmodule



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
    output [15:0] out_reg_a, // data from rs1
    output [15:0] out_reg_b  // data from rs2    
);

reg [15:0] cpu_registers [0:7];  //8 registers, each 16 bits wide

assign out_reg_a = cpu_registers[addr_reg_a];
assign out_reg_b = cpu_registers[addr_reg_b];

integer i;
initial begin
    for (i = 0; i < 8; i = i + 1) begin
        cpu_registers[i] = 16'b0;
    end
end

always @(posedge clk ) begin
    // $display("REGFILE: DEST: %d | RA: %d | RB: %d", addr_dest, addr_reg_a, addr_reg_b);
    if(write_enabled)begin
        cpu_registers[addr_dest] <= write_data;
    end    
end
endmodule
