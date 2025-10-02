// ALU 16-bit word 
module alu16 (
    input wire [15:0] A,
    input wire [15:0] B,
    input wire [3:0] ALUCtrl,
    output reg [15:0] Result
);

always @(*) begin
    case (ALUCtrl)
    4'b0000 : Result = A + B; //ADD
    4'b0001 : Result = A - B; //SUB
    4'b0010 : Result = A & B; //AND
    4'b0011 : Result = A | B; //OR
    4'b0100 : Result = A ^ B; //XOR
    4'b0101 : Result = A * B; //MUL
    4'b0111 : Result = A / B; //DIV
    4'b1000 : Result = ~A;    //NOT
    4'b1001 : Result = A % B; //MOD
    4'b1010 : Result = A;     //LOADI
        default: Result = 16'b0; 
    endcase
end
endmodule