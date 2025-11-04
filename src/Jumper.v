module Jumper (
    input wire [2:0]  jump_operator,
    input wire [15:0] test_value,
    // input wire [15:0] dest_address,
    output reg  pc_write_enabled //wether the PC should receive the input address
);

reg branch_taken;

localparam JMP = 3'b000;
localparam JEZ = 3'b001;
localparam JNZ = 3'b010;
localparam JGZ = 3'b011;
localparam JLZ = 3'b100;

always @(*) begin
    branch_taken = 1'b0;
    pc_write_enabled = 1'b0;
    case (jump_operator)
        JMP: branch_taken = 1'b1;                     //JMP regDst -> unconditional 
        JEZ: branch_taken = (test_value == 16'b0);    //JEZ test_value == 0 -> jump
        JNZ: branch_taken = (test_value != 16'b0);    //JNZ test_value != 0 -> jump
        JGZ: branch_taken = (test_value > 16'b0);     //JNZ test_value > 0 -> jump
        JLZ: branch_taken = (test_value < 16'b0);     //JNZ test_value < 0 -> jump
        default:  branch_taken = 1'b0;
    endcase
    if(branch_taken)begin
        pc_write_enabled = 1'b1;
    end
        
end
endmodule