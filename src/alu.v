// ALU 16-bit word 
module alu16 (
    input wire [15:0] A,
    input wire [15:0] B,
    input wire [4:0] ALUCtrl,
    output reg [15:0] Result
);

always @(*) begin
    case (ALUCtrl)
    5'b00000 : Result = A + B; //ADD
    5'b00001 : Result = A - B; //SUB
    5'b00010 : Result = A & B; //AND
    5'b00011 : Result = A | B; //OR
    5'b00100 : Result = A ^ B; //XOR
    5'b00101 : Result = A * B; //MUL
    5'b00111 : Result = A / B; //DIV
    5'b01000 : Result = ~A;    //NOT
    5'b01001 : Result = A % B; //MOD
        default: Result = 16'b0; 
    endcase
end
endmodule