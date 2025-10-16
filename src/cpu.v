
module CPU (
    input         clk,
    input         rst,
    input reg [15:0] Instruction,       // instruction fetched from ROM
    input [15:0] mem_data_in,       // data read from RAM

    output [15:0] pc_addr_out,      // current PC address
    output [15:0] mem_addr,         // address for RAM access
    output [15:0] mem_data_write,       // data to write to RAM
    output        mem_write_enabled       // RAM write enable?
);

reg [15:0] instruction_reg ;

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
Decoder u_decoder(
    .instr              	(instruction_reg     ),
    .alu_ctrl           	(alu_ctrl            ),
    .reg_dst            	(addr_reg_dst        ),
    .reg_rs1            	(addr_reg_a          ),
    .reg_rs2            	(addr_reg_b          ),
    .imm_se             	(imm_se              ),
    .reg_write          	(reg_write           ),
    .alu_src_imm        	(alu_src_imm         ),
    .mem_write          	(mem_write_enabled   ),
    .reg_write_back_sel 	(reg_write_back_sel  ),
    .comparator_ctrl    	(jump_ctrl           ),
    .mem_read    	        (mem_read           )
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

always @(posedge clk or posedge rst) begin
    if(rst)
        instruction_reg <= 16'b0;
    else
        instruction_reg <= Instruction;
end

endmodule



