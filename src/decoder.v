module decoder (
   input [15:0] instr;

   //ALU wiring
   output reg [3:0] alu_ctrl;
   output reg [2:0] reg_dst;
   output reg [2:0] reg_rs1;
   output reg [2:0] reg_rs2;
   output reg [6:0] imm_se;
   output reg  alu_src_imm;
   output reg  mem_read;
   output reg  mem_write;
   output reg  reg_write;
   output reg  write_back_sel; //write from MEM => 1; or from ALU result => 0
   output reg  branch;
   output reg  [1:0] pc_src;



);

localparam ALU_ADD = 4'b000;

always @(*) begin
    reg_dst = 3'b0;    
    reg_rs1 = 3'b0;    
    reg_rs2 = 3'b0;

    case (instr[15:14])
        2'b00: begin //Memory operations
        // LD   Rd, offset(Rb)    ; Rd ← MEM[Rb + offset]
        // ST   Rs, offset(Rb)    ; MEM[Rb + offset] ← Rs
        // decode fields: bit 13 = R/W, bits 12:10 = reg, 9:7 = base, 6:0 = offset
        reg_dst = instr[12:10];
        reg_rs1 = instr[9:7];
        imm_se = {{9{instr[6]}},instr[6,0]}; //the sign extension looks at the MSB of the immediate for replication
        alu_ctrl = ALU_ADD;

        if (instr[13] == 1'b0) begin
            // LOAD: Rd <- MEM[base + offset]

        end else begin
            
        end
        end

        default: 
   endcase
    
end   
endmodule