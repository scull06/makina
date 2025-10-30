module plncput (
        input              clk,
        input              rst,
        input  wire [15:0] instr_in,       // instruction from ROM being processed
        input  wire [15:0] pmem_data_in,   // read from RAM
        output wire [15:0] pc,
        output reg  [15:0] pmem_data_out,  // write to RAM
        output reg  [15:0] pmem_addr_out,  // address of RAM to be written
        output reg         pmem_write
    );

    // State encodings
    localparam reg [2:0] ZERO = 3'b000;
    localparam reg [2:0] STAGE_FETCH = 3'b001;
    localparam reg [2:0] STAGE_DECODE = 3'b010;
    localparam reg [2:0] STAGE_REGISTER_READ = 3'b011;

    localparam reg [2:0] STAGE_EXECUTE = 3'b100;
    localparam reg [2:0] STAGE_MEMORY = 3'b101;
    localparam reg [2:0] STAGE_MEMORY_WAIT = 3'b110;
    localparam reg [2:0] STAGE_WRITEBACK = 3'b111;


    reg [2:0] stage;

    //Cycles of the pipeline which must equal the FSM's number of stages
    localparam  unsigned CYCLES = 8;

    //Pipeline table for PC
    reg [15:0] pc_tbl [0:CYCLES-1];
    reg pc_wr_enable_tbl [0:(CYCLES-1)];
    //Pipeline instruction logicister table
    reg [15:0] instruction_tbl [0:CYCLES-1];
    //Pipeline table for instruction class
    reg [1:0] instruction_class_tbl [0:CYCLES-1];
    //Pipeline tables for registers address A, B and Dst
    reg [2:0] aReg_addr_tbl [0:CYCLES-1];
    reg [2:0] bReg_addr_tbl [0:CYCLES-1];
    reg [2:0] dstReg_addr_tbl [0:CYCLES-1];
    //Pipeline tables for registers value A and B
    //Register dst is never read; therefore we do not have any value out of it.
    reg [15:0] aReg_val_tbl [0:CYCLES-1];
    reg [15:0] bReg_val_tbl [0:CYCLES-1];
    //Pipeline table for register write back flags
    reg reg_write_tbl [0:CYCLES-1];
    reg reg_write_back_sel_tbl [0:CYCLES-1];
    //Pipeline table for ALU control bits
    reg [4:0] alu_ctrl_tbl [0:CYCLES-1];
    //Pipeline table for ALU result value
    reg [15:0] alu_result_tbl [0:CYCLES-1];
    //Pipeline table for ALU immediate
    reg [15:0] alu_immediate_tbl [0:CYCLES-1];
    //Pipeline table for alu source selector for input B.
    reg  alu_src_imm_tbl[0:CYCLES-1];
    //Pipeline table for JUMPs control bits
    reg [2:0] jump_ctrl_tbl[0:CYCLES-1];
    //Pipeline memory register tables
    reg [15:0] mem_address_tbl[0:CYCLES-1];
    reg [15:0] mem_data_out_tbl[0:CYCLES-1];
    reg [15:0] mem_data_in_tbl[0:CYCLES-1];
    //should memory be written back
    reg mem_write_tbl[0:CYCLES-1];


    // output declaration of module Decoder
    reg [4:0] alu_ctrl;
    reg [2:0] reg_dst;
    reg [2:0] reg_rs1;
    reg [2:0] reg_rs2;
    reg [15:0] imm_se;
    reg reg_write;
    reg alu_src_imm;
    reg mem_write;
    reg reg_write_back_sel;
    reg [2:0] jump_ctrl;
    reg [1:0] instr_class;

    Decoder u_Decoder(
                .instr               (instruction_tbl[STAGE_FETCH]),
                .alu_ctrl            (alu_ctrl            ),
                .reg_dst             (reg_dst             ),
                .reg_rs1             (reg_rs1             ),
                .reg_rs2             (reg_rs2             ),
                .imm_se              (imm_se              ),
                .reg_write           (reg_write           ),
                .alu_src_imm         (alu_src_imm         ),
                .mem_write           (mem_write           ),
                .reg_write_back_sel  (reg_write_back_sel  ),
                .jump_ctrl           (jump_ctrl           ),
                .instr_class         (instr_class         )
            );

    // output declaration of module RegisterFile
    reg [15:0] rf_out_reg_a;
    reg [15:0] rf_out_reg_b;

    RegisterFile u_RegisterFile(
                     .clk           (clk                            ),
                     .write_enabled (reg_write_tbl[STAGE_DECODE]    ), //FIXME: is a later stage here!
                     .addr_reg_a    (aReg_addr_tbl[STAGE_DECODE]    ),
                     .addr_reg_b    (bReg_addr_tbl[STAGE_DECODE]    ),
                     .addr_dest     (dstReg_addr_tbl[STAGE_DECODE]  ),
                     .write_data    (write_data                     ), //FIXME: is a later stage here!
                     .out_reg_a     (rf_out_reg_a                   ),
                     .out_reg_b     (rf_out_reg_b                   )
                 );


    // output declaration of module Alu16
    reg [15:0] alu_result;

    wire [15:0] alu_input_b = (alu_src_imm_tbl[STAGE_DECODE])
         ? alu_immediate_tbl[STAGE_DECODE]
         : bReg_val_tbl[STAGE_DECODE];

    //If instruction class is not for ALU the we use addition as the default operation.
    wire [4:0] effective_alu_ctrl = (instruction_class_tbl[STAGE_DECODE] == 2'b01)
         ? alu_ctrl_tbl[STAGE_DECODE]
         : 5'b00000 ;

    Alu16 u_Alu16(
              .A       (aReg_val_tbl[STAGE_DECODE]),
              .B       (alu_input_b),
              .ALUCtrl (effective_alu_ctrl),
              .Result  (alu_result   )
          );

    // output declaration of module Jumper
    reg pc_write_en;
    wire pc_write_enabled = (instruction_class_tbl[STAGE_DECODE] == 2'b10)
         ? pc_write_enabled
         : 1'b0;

    Jumper u_Jumper(
               .jump_operator    (jump_ctrl_tbl[STAGE_DECODE]     ),
               .test_value       ( aReg_val_tbl[STAGE_DECODE]     ),
               .dest_address     (bReg_val_tbl[STAGE_DECODE]      ),
               .pc_write_enabled (pc_write_en  )
           );



    //Instruction driver
    integer i;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            //reset instruction and PC
            for (i = 0; i < CYCLES; i = i + 1) begin
                pc_tbl[i] <= 0;
                instruction_tbl[i] <= 0;
                pc_wr_enable_tbl[i] <= 0;
                instruction_class_tbl[i] <= 0;
                aReg_addr_tbl[i] <= 0;
                bReg_addr_tbl[i] <= 0;
                dstReg_addr_tbl[i] <= 0;
                aReg_val_tbl[i] <= 0;
                bReg_val_tbl[i] <= 0;
                reg_write_tbl[i] <= 0;
                reg_write_back_sel_tbl[i] <= 0;
                alu_ctrl_tbl[i] <= 0;
                alu_result_tbl[i] <= 0;
                alu_immediate_tbl[i] <= 0;
                alu_src_imm_tbl[i] <= 0;
                jump_ctrl_tbl[i] <= 0;
                mem_address_tbl[i] <= 0;
                mem_data_out_tbl[i] <= 0;
                mem_data_in_tbl[i] <= 0;
                mem_write_tbl[i] <= 0;
            end
            stage <= ZERO;
        end
        else begin
            case (stage)
                ZERO: begin
                    //NOTHING TO DO:
                    //just wait for the instruction
                    //to be fetched
                    //from the ROM
                    stage <= STAGE_FETCH;
                end
                STAGE_FETCH: begin  //INSTRUCION FETCH
                    pc_tbl[STAGE_FETCH] <= 0; //TODO:
                    instruction_tbl[STAGE_FETCH] <= instr_in;
                    pc_wr_enable_tbl[STAGE_FETCH] <= 0;
                    instruction_class_tbl[STAGE_FETCH] <= 0;
                    aReg_addr_tbl[STAGE_FETCH] <= 0;
                    bReg_addr_tbl[STAGE_FETCH] <= 0;
                    dstReg_addr_tbl[STAGE_FETCH] <= 0;
                    aReg_val_tbl[STAGE_FETCH] <= 0;
                    bReg_val_tbl[STAGE_FETCH] <= 0;
                    reg_write_tbl[STAGE_FETCH] <= 0;
                    reg_write_back_sel_tbl[STAGE_FETCH] <= 0;
                    alu_ctrl_tbl[STAGE_FETCH] <= 0;
                    alu_result_tbl[STAGE_FETCH] <= 0;
                    alu_immediate_tbl[STAGE_FETCH] <= 0;
                    alu_src_imm_tbl[STAGE_FETCH] <= 0;
                    jump_ctrl_tbl[STAGE_FETCH] <= 0;
                    mem_address_tbl[STAGE_FETCH] <= 0;
                    mem_data_out_tbl[STAGE_FETCH] <= 0;
                    mem_data_in_tbl[STAGE_FETCH] <= 0;
                    mem_write_tbl[STAGE_FETCH] <= 0;
                    //changin the stage
                    stage <= STAGE_DECODE;
                end

                STAGE_DECODE: begin  //INSTRUCTION DECODING
                    pc_tbl[STAGE_DECODE] <= pc_tbl[STAGE_FETCH];
                    instruction_tbl[STAGE_DECODE] <= instruction_tbl[STAGE_FETCH];

                    alu_ctrl_tbl[STAGE_DECODE] <= alu_ctrl;
                    jump_ctrl_tbl[STAGE_DECODE] <= jump_ctrl;

                    aReg_addr_tbl[STAGE_DECODE] <= reg_rs1;
                    bReg_addr_tbl[STAGE_DECODE] <= reg_rs2;
                    dstReg_addr_tbl[STAGE_DECODE] <= reg_dst;
                    alu_immediate_tbl[STAGE_DECODE] <= imm_se;
                    reg_write_tbl[STAGE_DECODE] <= reg_write;
                    alu_src_imm_tbl[STAGE_DECODE] <= alu_src_imm;

                    mem_write_tbl[STAGE_DECODE] <= mem_write;
                    reg_write_back_sel_tbl[STAGE_DECODE] <= reg_write_back_sel;
                    instruction_class_tbl[STAGE_DECODE] <= instr_class;

                    //For execute
                    aReg_val_tbl[STAGE_DECODE] <= 0;
                    bReg_val_tbl[STAGE_DECODE] <= 0;
                    alu_result_tbl[STAGE_DECODE] <= 0;
                    //For memory
                    mem_address_tbl[STAGE_DECODE] <= 0;
                    mem_data_out_tbl[STAGE_DECODE] <= 0;
                    mem_data_in_tbl[STAGE_DECODE] <= 0;
                    //For jumps
                    pc_wr_enable_tbl[STAGE_DECODE] <=  0;

                    // $display("%0d@ [DECODE] INSTRUCTION: %b | rDest:%d | rA:%d |rB:%d | aluCTRL:%b | alusrcimm:%b >>> R0=%0d, R1=%0d, R2=%0d, R3=%0d, R4=%0d, R5=%0d, R6=%0d, R7=%0d",
                    //  if_pc, if_instruction, reg_dst, reg_rs1, reg_rs2, alu_ctrl, alu_src_imm,  u_RegisterFile.cpu_registers[0], u_RegisterFile.cpu_registers[1], u_RegisterFile.cpu_registers[2], u_RegisterFile.cpu_registers[3],
                    //    u_RegisterFile.cpu_registers[4], u_RegisterFile.cpu_registers[5], u_RegisterFile.cpu_registers[6], u_RegisterFile.cpu_registers[7]);

                    stage <= STAGE_REGISTER_READ;
                end

                STAGE_REGISTER_READ: begin
                    //this is to estabilize all register values from the decode stage as
                    //reading the register file is asynchronous
                    aReg_val_tbl[STAGE_DECODE] <= rf_out_reg_a;
                    bReg_val_tbl[STAGE_DECODE] <= rf_out_reg_b;
                    stage <= STAGE_EXECUTE;
                end

                STAGE_EXECUTE: begin  //EXECUTE THE INSTRUCTION
                    pc_tbl[STAGE_EXECUTE] <= pc_tbl[STAGE_DECODE];
                    instruction_tbl[STAGE_EXECUTE] <= instruction_tbl[STAGE_DECODE];

                    alu_ctrl_tbl[STAGE_EXECUTE] <= alu_ctrl_tbl[STAGE_DECODE];
                    jump_ctrl_tbl[STAGE_EXECUTE] <= jump_ctrl_tbl[STAGE_DECODE];

                    aReg_addr_tbl[STAGE_EXECUTE] <= aReg_addr_tbl[STAGE_DECODE];
                    bReg_addr_tbl[STAGE_EXECUTE] <= bReg_addr_tbl[STAGE_DECODE];
                    dstReg_addr_tbl[STAGE_EXECUTE] <= dstReg_addr_tbl[STAGE_DECODE];
                    alu_immediate_tbl[STAGE_EXECUTE] <= alu_immediate_tbl[STAGE_DECODE];
                    alu_src_imm_tbl[STAGE_EXECUTE] <= alu_src_imm_tbl[STAGE_DECODE];

                    mem_write_tbl[STAGE_EXECUTE] <= mem_write_tbl[STAGE_DECODE];
                    reg_write_back_sel_tbl[STAGE_EXECUTE] <= reg_write_back_sel_tbl[STAGE_DECODE];
                    instruction_class_tbl[STAGE_EXECUTE] <= instruction_class_tbl[STAGE_DECODE];


                    //For execute
                    aReg_val_tbl[STAGE_EXECUTE] <=  aReg_val_tbl[STAGE_DECODE];
                    bReg_val_tbl[STAGE_EXECUTE] <= bReg_val_tbl[STAGE_DECODE];
                    alu_result_tbl[STAGE_EXECUTE] <= alu_result;

                    //For memory
                    mem_address_tbl[STAGE_EXECUTE] <= 0;
                    mem_data_out_tbl[STAGE_EXECUTE] <= 0;
                    mem_data_in_tbl[STAGE_EXECUTE] <= 0;
                    //For jumps
                    reg_write_tbl[STAGE_EXECUTE] <= reg_write_tbl[STAGE_DECODE];
                    pc_wr_enable_tbl[STAGE_EXECUTE] <=  pc_write_enabled;

                    // $display("%0d@ [EXEC] aluCTRL:%b |  A:%b | B:%b | InputB:%b | alu_res:%b | destAddr:%b",
                    //                         id_pc, id_alu_ctrl, id_regA, id_regB, alu_input_B, alu_result, id_addr_regDst);

                    stage <= STAGE_MEMORY;
                end

                STAGE_MEMORY: begin

                    pc_tbl[STAGE_MEMORY] <= pc_tbl[STAGE_EXECUTE];
                    instruction_tbl[STAGE_MEMORY] <= instruction_tbl[STAGE_EXECUTE];

                    alu_ctrl_tbl[STAGE_MEMORY] <= alu_ctrl_tbl[STAGE_EXECUTE];
                    jump_ctrl_tbl[STAGE_MEMORY] <= jump_ctrl_tbl[STAGE_EXECUTE];

                    aReg_addr_tbl[STAGE_MEMORY] <= aReg_addr_tbl[STAGE_EXECUTE];
                    bReg_addr_tbl[STAGE_MEMORY] <= bReg_addr_tbl[STAGE_EXECUTE];
                    dstReg_addr_tbl[STAGE_MEMORY] <= dstReg_addr_tbl[STAGE_EXECUTE];
                    alu_immediate_tbl[STAGE_MEMORY] <= alu_immediate_tbl[STAGE_EXECUTE];
                    alu_src_imm_tbl[STAGE_MEMORY] <= alu_src_imm_tbl[STAGE_EXECUTE];

                    reg_write_back_sel_tbl[STAGE_MEMORY] <= reg_write_back_sel_tbl[STAGE_EXECUTE];
                    instruction_class_tbl[STAGE_MEMORY] <= instruction_class_tbl[STAGE_EXECUTE];


                    //For execute
                    aReg_val_tbl[STAGE_MEMORY] <=  aReg_val_tbl[STAGE_EXECUTE];
                    bReg_val_tbl[STAGE_MEMORY] <= bReg_val_tbl[STAGE_EXECUTE];
                    alu_result_tbl[STAGE_MEMORY] <= alu_result_tbl[STAGE_EXECUTE];

                    //For memory
                    //FIXME:
                    //Presenting data to the memory bus. Effective in next cycle.
                    //It means that memory data will come back in the cycle after.
                    //So reading from memory wastes 2 cycles
                    pmem_addr_out <= alu_result_tbl[STAGE_EXECUTE];
                    pmem_data_out <= bReg_val_tbl[STAGE_EXECUTE];
                    pmem_write <= mem_write_tbl[STAGE_EXECUTE];

                    //Carrying the register values of the memory stage
                    mem_address_tbl[STAGE_MEMORY] <= alu_result_tbl[STAGE_EXECUTE];
                    mem_data_out_tbl[STAGE_MEMORY] <= bReg_val_tbl[STAGE_EXECUTE];
                    mem_write_tbl[STAGE_MEMORY] <= mem_write_tbl[STAGE_EXECUTE];
                    mem_data_in_tbl[STAGE_MEMORY] <= 0; //still not loading from memory...

                    //For jumps
                    reg_write_tbl[STAGE_MEMORY] <= reg_write_tbl[STAGE_EXECUTE];
                    pc_wr_enable_tbl[STAGE_MEMORY] <=  pc_wr_enable_tbl[STAGE_EXECUTE];

                    // $display("%0d@ [MEM] Addr=%b | dataOut??=%b IF(%b)", ex_pc, ex_alu_result, ex_regB, ex_mem_write);
                    stage <= STAGE_MEMORY_WAIT;
                end

                STAGE_MEMORY_WAIT: begin
                    //pmem_data_in is still loading from memory;
                    //BUBBLE MEMORY STAGE
                    stage <= STAGE_WRITEBACK;
                end
 
                STAGE_WRITEBACK: begin

                    // $display("%0d@ [WRB] pmem_data_in=%b |  | mem_addr_to_write:%b | to_write_to_mem:%b", ex_pc,  pmem_data_in, mem_addr_out, mem_data_out);
                    // $display("%0d@ [JMP?] jmp_flag=%b | jmp_address:%b", ex_pc,  mem_pc_wr_enable, mem_regB);

                    // rf_write_enable <= mem_reg_write;
                    // //mem_addr_out is an alias for the ex_alu_out on the memory stage
                    // rf_write_data <= (mem_reg_write_back_sel) ? pmem_data_in : mem_addr_out;

                    // if(mem_pc_wr_enable && mem_jump_ctrl) begin
                    //     if_pc <= mem_regB; //to the instruction after the next instruction!
                    // end
                    //  else begin
                    //     if_pc <= ex_pc + 1; // no jump;
                    //  end


                    stage <= ZERO;
                end


                default: begin
                    $display("discarding stage %b", stage);
                    stage <= ZERO;  // safety fallback
                end
            endcase
        end
    end
endmodule
