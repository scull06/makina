module MCPU (
    input clk,
    input rst,
    input wire [15:0] instr_in,          // instruction from ROM being processed
    input wire [15:0] data_in,           // read from RAM
    output wire [15:0] PC,
    output reg [15:0] mem_data_out, // write to RAM
    output reg [15:0] mem_addr_out, // address of RAM to be written
    output reg mem_write
);

// State encodings
localparam STAGE_FETCH     = 3'b000;
localparam STAGE_DECODE    = 3'b001;
localparam REGISTER_READ   = 3'b101;
localparam STAGE_EXECUTE   = 3'b010;
localparam STAGE_MEMORY    = 3'b011;
localparam STAGE_WRITEBACK = 3'b100;

reg [2:0] stage;                    //Current stage being executed (IF -> ID -> EX -> EM -> WB)
                                    //It drives the execution of the instruction as a finite state machine.
reg [15:0] current_instr;           //holds the current instruction during the FSM execution
reg [15:0] PC_reg;                  //Program Counter
assign PC = PC_reg;


//Decoder latched outputs
reg [3:0] alu_ctrl_reg;
reg [15:0] imm_se_reg;
reg reg_write_reg, 
    alu_src_imm_reg, 
    mem_write_reg, 
    reg_write_back_sel_reg;
reg [2:0]   dst_reg,
            rs1_reg,
            rs2_reg,
            comparator_ctrl_reg;


// output declaration of module decoder
wire [3:0]  alu_ctrl;
wire [2:0]  dst, rs1, rs2;
wire [15:0] imm_se;
wire reg_write, alu_src_imm, dmem_write, reg_write_back_sel;
wire [2:0] comparator_ctrl;
wire [15:0] decoder_instruction;
assign decoder_instruction = current_instr;

Decoder u_decoder(
    .instr              	(decoder_instruction ),
    .alu_ctrl           	(alu_ctrl            ),
    .reg_dst            	(dst                 ),
    .reg_rs1            	(rs1                 ),
    .reg_rs2            	(rs2                 ),
    .imm_se             	(imm_se              ),
    .reg_write          	(reg_write           ),
    .alu_src_imm        	(alu_src_imm         ),
    .mem_write          	(dmem_write          ),
    .reg_write_back_sel 	(reg_write_back_sel  ),
    .comparator_ctrl    	(comparator_ctrl     )
);

// output declaration of module RegisterFile
reg [15:0] rf_reg_a_out;
reg [15:0] rf_reg_b_out;

//Latched register file outputs
reg [15:0] rs1_data_reg;
reg [15:0] rs2_data_reg;


reg [2:0] rf_addr_ar;
reg [2:0] rf_addr_br;
reg [2:0] rf_addr_destr;
reg [15:0] rf_write_data;
reg  rf_write_enable;

RegisterFile u_RegisterFile(
    .clk           	(clk            ),
    .write_enabled 	(rf_write_enable),
    .addr_reg_a    	(rf_addr_ar     ),
    .addr_reg_b    	(rf_addr_br     ),
    .addr_dest     	(rf_addr_destr  ),
    .write_data    	(rf_write_data  ),
    .out_reg_a     	(rf_reg_a_out   ),
    .out_reg_b     	(rf_reg_b_out   )
);


// output declaration of module alu16
reg [15:0] alu_result_reg;
wire [15:0] alu_result;

alu16 u_alu16(
    .A       	(rs1_data_reg          ),
    .B       	((alu_src_imm_reg) ? imm_se_reg : rs2_data_reg),
    .ALUCtrl 	(alu_ctrl_reg ),
    .Result  	(alu_result   )
);

// output declaration of module comparator
reg branch_taken_reg;
comparator u_comparator(
    .jump_operator           	(comparator_ctrl_reg      ),
    .operand_a               	(rs1_data_reg                    ),
    .operand_b               	(rs2_data_reg                    ), //TODO: I need to check that the data of the jump is comming always from dataB and not from the imm
    .pc_write_enabled        	(branch_taken_reg         )
);

always @(posedge clk or posedge rst) begin
    
    // rf_write_enable <= 0;
    // mem_write_reg <= 0;

    if (rst) begin
        PC_reg <= 16'b0;
        stage <= STAGE_FETCH;
    end else begin
        case (stage)
            STAGE_FETCH: begin
                // fetch instruction logic
                current_instr <= instr_in;
                stage <= STAGE_DECODE;
            end

            STAGE_DECODE: begin
                // decode logic, all signals from the decoder are latched
                rs1_reg <= rs1;
                rs2_reg <= rs2;
                dst_reg <= dst; 
                imm_se_reg <= imm_se; //It is NOT! sign extended!!!!!!
                alu_ctrl_reg <= alu_ctrl;
                alu_src_imm_reg <= alu_src_imm;

                comparator_ctrl_reg <= comparator_ctrl;
                mem_write_reg <= dmem_write; 
                //to drive reg write back stage
                reg_write_back_sel_reg <= reg_write_back_sel;
                reg_write_reg <= reg_write;

                stage <= REGISTER_READ;
            end

            REGISTER_READ: begin

                rf_addr_ar <= rs1_reg;
                rf_addr_br <= rs2_reg;
                rf_addr_destr <= dst_reg;
                
                rs1_data_reg <= rf_reg_a_out;
                rs2_data_reg <= rf_reg_b_out;
                
                stage <= STAGE_EXECUTE;
            end

            STAGE_EXECUTE: begin
                // execute logic
                alu_result_reg <= alu_result;
                
                if(branch_taken_reg) 
                    PC_reg <= PC_reg + 1; //The unconditional JUMP must be there.
                else 
                    PC_reg <= PC_reg + 2; //alternative branch, i.e, do not jump at all.

                stage <= STAGE_MEMORY;
            end

            STAGE_MEMORY: begin
                // memory logic
                mem_addr_out <= alu_result_reg;
                mem_write <= mem_write_reg;

                if(mem_write_reg)begin
                    mem_data_out <=  rs2_data_reg;
                end else begin
                    mem_data_out <= 0;
                end

                stage <= STAGE_WRITEBACK;
            end

            STAGE_WRITEBACK: begin
                // writeback logic
                rf_write_enable <= reg_write_reg;
                if(reg_write_reg)
                    rf_write_data <=  (reg_write_back_sel_reg) ? data_in : alu_result_reg;

                stage <= STAGE_FETCH;
            end

            default: stage <= STAGE_FETCH; // safety fallback
        endcase
    end
end
endmodule
