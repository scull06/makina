module PLNCPUT (
    input clk,
    input rst,
    input wire [15:0] instr_in,          // instruction from ROM being processed
    input wire [15:0] pmem_data_in,           // read from RAM
    output wire [15:0] pc,
    output reg [15:0] pmem_data_out, // write to RAM
    output reg [15:0] pmem_addr_out, // address of RAM to be written
    output reg pmem_write
);

// State encodings
localparam ZERO              = 3'b111;
localparam STAGE_FETCH       = 3'b000;
localparam STAGE_DECODE      = 3'b001;
localparam STAGE_EXECUTE     = 3'b010;
localparam STAGE_MEMORY      = 3'b011;
localparam STAGE_MEMORY_WAIT = 3'b100;
localparam STAGE_WRITEBACK   = 3'b101;


reg [2:0] stage;

//Cycles of the pipeline which must equal the FSM's number of stages
localparam CYCLES = 7;

typedef struct packed {
    //Pipeline table for PC 
    reg [15:0] pc_tbl;
    reg pc_wr_enable_tbl; 
    //TODO: to be moved to assign place
    
    //Pipeline instruction register table
    reg [15:0] instruction_tbl;
    
    //Pipeline table for instruction class
    reg [1:0] instruction_class_tbl;
    
    //Pipeline tables for registers address A, B and Dst
    reg [2:0] aReg_addr_tbl;
    reg [2:0] bReg_addr_tbl;
    reg [2:0] dstReg_addr_tbl;
    
    //Pipeline tables for registers value A and B
    //Register dst is never read; therefore we do not have any value out of it.
    reg [15:0] aReg_val_tbl;
    reg [15:0] bReg_val_tbl;
    
    //Pipeline table for register write back flags
    reg reg_write_tbl;
    reg reg_write_back_sel_tbl;
    
    //Pipeline table for ALU control bits
    reg [4:0]  alu_ctrl_tbl;
    
    //Pipeline table for ALU result value
    reg [15:0] alu_result_tbl;
    
    //Pipeline table for ALU immediate
    reg [15:0] alu_immediate_tbl;
    //Pipeline table for alu source selector for input B.
    reg [3:0]  alu_src_imm_tbl;
    
    //Pipeline table for JUMPs control bits
    reg [2:0]  jump_ctrl_tbl;
    
    //Pipeline memory register tables
    reg [15:0] mem_address_tbl;
    reg [15:0] mem_data_out_tbl;
    reg [15:0] mem_data_it_tbl;
    reg mem_write_tbl;

} reg_tbl;

/* IMPLEMENTATION */
// output declaration of module Decoder
// Since decoder is combinationial I can just write to the regs of the next stage right after the decoding
wire [4:0] alu_ctrl;
wire [2:0] reg_dst;
wire [2:0] reg_rs1;
wire [2:0] reg_rs2;
wire [15:0] imm_se;
wire reg_write;
wire alu_src_imm;
wire dmem_write;
wire reg_write_back_sel;
wire [2:0] jump_ctrl;
wire [1:0] instruction_class;

Decoder udec(
    .instr              	(instr_in            ),
    .alu_ctrl           	(alu_ctrl            ),
    .reg_dst            	(reg_dst             ),
    .reg_rs1            	(reg_rs1             ),
    .reg_rs2            	(reg_rs2             ),
    .imm_se             	(imm_se              ),
    .reg_write          	(reg_write           ),
    .alu_src_imm        	(alu_src_imm         ),
    .mem_write          	(dmem_write          ),
    .reg_write_back_sel 	(reg_write_back_sel  ),
    .jump_ctrl    	        (jump_ctrl           ),
    .instr_class            (instruction_class   )
);

reg rf_write_enable;
reg [15:0] rf_write_data;
    
RegisterFile u_RegisterFile(
    .clk           	(clk                ),
    .write_enabled 	(rf_write_enable    ),
    .addr_reg_a    	(reg_rs1            ),
    .addr_reg_b    	(reg_rs2            ),
    .addr_dest     	(reg_dst            ),
    .write_data    	(rf_write_data      ),
    .out_reg_a     	(id_regA            ),
    .out_reg_b     	(id_regB            )
);



reg [2:0]  ex_jump_ctrl;
reg ex_pc_wr_enable;
//reg control
reg ex_reg_write;
reg ex_reg_write_back_sel;
//mem control
reg ex_mem_write;

// output declaration of module alu16
wire [15:0] alu_result;
wire [15:0] alu_input_B = (id_alu_src_imm) ? id_imm : id_regB;

alu16 u_alu16(
    .A       	(id_regA     ),
    .B       	(alu_input_B ),
    .ALUCtrl 	(id_alu_ctrl ),
    .Result  	(alu_result  )
);

// output declaration of module jumper
wire pc_write_enabled;

jumper u_comparator(
    .jump_operator    	(id_jump_ctrl      ),
    .test_value        	(id_regA           ),
    .dest_address       (id_regB           ),
    .pc_write_enabled 	(pc_write_enabled  )
);

// MEMORY context

reg [15:0] mem_addr_out;
reg [15:0] mem_data_out;
reg [15:0] mem_data_in_saved;
reg [15:0] mem_regA;
reg [15:0] mem_regB;
reg mem_write;

assign pmem_addr_out = mem_addr_out; 
assign pmem_data_out = mem_data_out; 
assign pmem_write = mem_write;


reg [2:0] mem_jump_ctrl;
reg mem_pc_wr_enable;
reg mem_reg_write;
reg mem_reg_write_back_sel;


//Instruction driver
always @(posedge clk or posedge rst) begin
    if (rst) begin
        //reset instruction and PC 
        if_instruction <= 0;
        if_pc <= 0;
    end else begin
        case (stage)
            ZERO: begin
                stage <= STAGE_FETCH;
            end
            STAGE_FETCH: begin //INSTRUCION FETCH
                if_instruction <= instr_in;
                stage <= STAGE_DECODE;
            end

            STAGE_DECODE: begin //INSTRUCTION DECODING
                id_pc <= if_pc;
                //dest register address
                id_addr_regDst <= reg_dst;
                //alu control
                id_alu_ctrl <= alu_ctrl;
                id_imm <= imm_se;
                id_alu_src_imm <= alu_src_imm;
                //jump control
                // id_jump_ctrl <= jump_ctrl;
                //reg control
                id_reg_write <= reg_write;
                id_reg_write_back_sel <= reg_write_back_sel;
                //mem control
                id_mem_write <= dmem_write;

                //I must pass the instruction class across all stages
                id_instr_class <= instruction_class;

                $display("%0d@ [DECODE] INSTRUCTION: %b | rDest:%d | rA:%d |rB:%d | aluCTRL:%b | alusrcimm:%b >>> R0=%0d, R1=%0d, R2=%0d, R3=%0d, R4=%0d, R5=%0d, R6=%0d, R7=%0d",
                 if_pc, if_instruction, reg_dst, reg_rs1, reg_rs2, alu_ctrl, alu_src_imm,  u_RegisterFile.cpu_registers[0], u_RegisterFile.cpu_registers[1], u_RegisterFile.cpu_registers[2], u_RegisterFile.cpu_registers[3], 
                   u_RegisterFile.cpu_registers[4], u_RegisterFile.cpu_registers[5], u_RegisterFile.cpu_registers[6], u_RegisterFile.cpu_registers[7]);

                stage <= STAGE_EXECUTE;
            end

            STAGE_EXECUTE: begin //EXECUTE THE INSTRUCTION
                //EXECUTE context
                ex_pc <= id_pc;
                ex_regA <= id_regA;
                ex_regB <= id_regB;
                ex_addr_regDst <= id_addr_regDst;
                ex_imm <= id_imm;

                //alu control
                ex_alu_ctrl <= id_alu_ctrl;
                ex_alu_result <= alu_result;
                ex_alu_src_imm <= id_alu_src_imm;
                ex_imm <= id_imm;
                //jump control
                ex_jump_ctrl <= id_jump_ctrl;


                ex_pc_wr_enable <= pc_write_enabled;
                //reg control
                ex_reg_write <= id_reg_write;
                ex_reg_write_back_sel <= id_reg_write_back_sel;
                //mem control
                ex_mem_write <= id_mem_write;

                //instr class
                ex_instr_class <= id_instr_class;

                $display("%0d@ [EXEC] aluCTRL:%b |  A:%b | B:%b | InputB:%b | alu_res:%b | destAddr:%b", 
                                        id_pc, id_alu_ctrl, id_regA, id_regB, alu_input_B, alu_result, id_addr_regDst);

                stage <= STAGE_MEMORY;
            end

            STAGE_MEMORY: begin
                // mem_data_in <=   will come from the external memory module.
                mem_addr_out <= ex_alu_result;
                mem_data_out <= ex_regB;
                mem_write <= ex_mem_write;

                mem_regA <=  ex_regA;
                mem_regB <=  ex_regB;

                mem_jump_ctrl <= ex_jump_ctrl;
                mem_pc_wr_enable <= ex_pc_wr_enable;

                mem_reg_write <= ex_reg_write;
                mem_reg_write_back_sel <= ex_reg_write_back_sel;

                //instr class
                mem_instr_class <= ex_instr_class;

                $display("%0d@ [MEM] Addr=%b | dataOut??=%b IF(%b)", ex_pc, ex_alu_result, ex_regB, ex_mem_write);


                stage <= STAGE_MEMORY_WAIT;
            end

            STAGE_MEMORY_WAIT: begin
                //pmem_data_in is still loading from memory;
                //instr class
                memw_instr_class <= mem_instr_class;
                // in this cycle, do nothing.
                // just allow for the memory 
                // to bring the values or write the given one
                stage <= STAGE_WRITEBACK;
            end

            STAGE_WRITEBACK: begin

                $display("%0d@ [WRB] pmem_data_in=%b |  | mem_addr_to_write:%b | to_write_to_mem:%b", ex_pc,  pmem_data_in, mem_addr_out, mem_data_out);
                // $display("%0d@ [JMP?] jmp_flag=%b | jmp_address:%b", ex_pc,  mem_pc_wr_enable, mem_regB);

                rf_write_enable <= mem_reg_write;
                //mem_addr_out is an alias for the ex_alu_out on the memory stage
                rf_write_data <= (mem_reg_write_back_sel) ? pmem_data_in : mem_addr_out; 

                if(mem_pc_wr_enable && mem_jump_ctrl) begin
                    if_pc <= mem_regB; //to the instruction after the next instruction!
                end
                 else begin
                    if_pc <= ex_pc + 1; // no jump;
                 end


                stage <= ZERO;
            end


            default: begin
                $display("discarding stage %b", stage);
                stage <= ZERO; // safety fallback
            end
        endcase
    end
end
endmodule

