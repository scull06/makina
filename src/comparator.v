module comparator (
    input wire [2:0]  jump_operator,
    input wire [15:0] operand_a,
    input wire [15:0] operand_b,
    output reg  pc_write_enabled //wether the PC should receive the input address
);

reg branch_taken;

always @(*) begin
    branch_taken = 1'b0;
    pc_write_enabled = 1'b0;
    case (jump_operator)
        3'b110: branch_taken = 1'b1;                        //JMP regDst -> unconditional 
        3'b000: branch_taken = (operand_a == operand_b);    //JEQ a b dest -> if a == b 
        3'b001: branch_taken = (operand_a != operand_b);    //JNQ a b dest -> if a != b 
        3'b010: branch_taken = (operand_a > operand_b);     //JGT a b dest -> if a > b 
        3'b011: branch_taken = (operand_a < operand_b);     //JLT a b dest -> if a < b 
        3'b100: branch_taken = (operand_a >= operand_b);    //JGE a b dest -> if a >= b 
        3'b101: branch_taken = (operand_a <= operand_b);    //JLE a b dest -> if a <= b 
        default:  branch_taken = 1'b0;
    endcase
     
    if(branch_taken)begin
        pc_write_enabled = 1'b1;
    end
        
end
endmodule